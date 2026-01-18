# Hosted Zone
resource "aws_route53_zone" "this" {
  name              = var.zone_name
  comment           = var.comment
  force_destroy     = var.force_destroy
  delegation_set_id = var.delegation_set_id

  # VPC configuration for private zones
  dynamic "vpc" {
    for_each = var.private_zone ? var.vpc_associations : []
    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = vpc.value.vpc_region
    }
  }

  tags = var.tags
}

# Additional VPC associations (for associating multiple VPCs beyond the first)
resource "aws_route53_zone_association" "additional" {
  for_each = var.private_zone && length(var.vpc_associations) > 1 ? {
    for idx, vpc in slice(var.vpc_associations, 1, length(var.vpc_associations)) : idx => vpc
  } : {}

  zone_id    = aws_route53_zone.this.zone_id
  vpc_id     = each.value.vpc_id
  vpc_region = each.value.vpc_region
}

# DNSSEC Key Signing Key
resource "aws_kms_key" "dnssec" {
  count                    = var.dnssec_signing != null && var.dnssec_signing.enabled && var.dnssec_signing.kms_key_arn == null ? 1 : 0
  customer_master_key_spec = "ECC_NIST_P256"
  deletion_window_in_days  = 7
  key_usage                = "SIGN_VERIFY"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Allow Route 53 DNSSEC Service"
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Action = [
          "kms:DescribeKey",
          "kms:GetPublicKey",
          "kms:Sign"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:route53:::hostedzone/*"
          }
        }
      },
      {
        Sid    = "Allow Route 53 DNSSEC to CreateGrant"
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Action   = "kms:CreateGrant"
        Resource = "*"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
        }
      },
      {
        Sid    = "Allow administration of the key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

data "aws_caller_identity" "current" {}

# DNSSEC Key Signing Key
resource "aws_route53_key_signing_key" "this" {
  count                      = var.dnssec_signing != null && var.dnssec_signing.enabled ? 1 : 0
  hosted_zone_id             = aws_route53_zone.this.zone_id
  key_management_service_arn = var.dnssec_signing.kms_key_arn != null ? var.dnssec_signing.kms_key_arn : aws_kms_key.dnssec[0].arn
  name                       = "${replace(var.zone_name, ".", "-")}-ksk"
}

# Enable DNSSEC signing
resource "aws_route53_hosted_zone_dnssec" "this" {
  count          = var.dnssec_signing != null && var.dnssec_signing.enabled ? 1 : 0
  hosted_zone_id = aws_route53_zone.this.zone_id

  depends_on = [aws_route53_key_signing_key.this]
}

# Query Logging
resource "aws_route53_query_log" "this" {
  count                    = var.query_logging != null ? 1 : 0
  zone_id                  = aws_route53_zone.this.zone_id
  cloudwatch_log_group_arn = var.query_logging.cloudwatch_log_group_arn

  depends_on = [aws_route53_zone.this]
}

# Health Checks
resource "aws_route53_health_check" "this" {
  for_each = var.health_checks

  type              = each.value.type
  fqdn              = each.value.fqdn
  ip_address        = each.value.ip_address
  port              = each.value.port
  resource_path     = each.value.resource_path
  failure_threshold = each.value.failure_threshold
  request_interval  = each.value.request_interval
  search_string     = each.value.search_string
  invert_healthcheck = each.value.invert_healthcheck
  enable_sni        = each.value.enable_sni
  regions           = each.value.regions
  disabled          = each.value.disabled

  # Calculated health check
  child_health_threshold = each.value.child_healthcheck_threshold
  child_healthchecks     = each.value.child_health_checks

  # CloudWatch alarm health check
  cloudwatch_alarm_name   = each.value.cloudwatch_alarm_name
  cloudwatch_alarm_region = each.value.cloudwatch_alarm_region
  insufficient_data_health_status = each.value.insufficient_data_health_status

  tags = merge(var.tags, each.value.tags, { Name = each.key })
}

# DNS Records
resource "aws_route53_record" "this" {
  for_each = { for idx, record in var.records : "${record.name}-${record.type}-${try(record.routing_policy.weighted.set_identifier, try(record.routing_policy.latency.set_identifier, try(record.routing_policy.geolocation.set_identifier, try(record.routing_policy.failover.set_identifier, try(record.routing_policy.multivalue.set_identifier, try(record.routing_policy.ip_based.set_identifier, idx))))))}" => record }

  zone_id         = aws_route53_zone.this.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = each.value.alias == null ? each.value.ttl : null
  records         = each.value.alias == null ? each.value.records : null
  allow_overwrite = each.value.allow_overwrite
  health_check_id = each.value.health_check_id

  # Alias record
  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

  # Weighted routing
  dynamic "weighted_routing_policy" {
    for_each = try(each.value.routing_policy.weighted, null) != null ? [each.value.routing_policy.weighted] : []
    content {
      weight = weighted_routing_policy.value.weight
    }
  }

  # Latency routing
  dynamic "latency_routing_policy" {
    for_each = try(each.value.routing_policy.latency, null) != null ? [each.value.routing_policy.latency] : []
    content {
      region = latency_routing_policy.value.region
    }
  }

  # Geolocation routing
  dynamic "geolocation_routing_policy" {
    for_each = try(each.value.routing_policy.geolocation, null) != null ? [each.value.routing_policy.geolocation] : []
    content {
      continent   = geolocation_routing_policy.value.continent
      country     = geolocation_routing_policy.value.country
      subdivision = geolocation_routing_policy.value.subdivision
    }
  }

  # Failover routing
  dynamic "failover_routing_policy" {
    for_each = try(each.value.routing_policy.failover, null) != null ? [each.value.routing_policy.failover] : []
    content {
      type = failover_routing_policy.value.type
    }
  }

  # Multivalue answer routing
  multivalue_answer_routing_policy = try(each.value.routing_policy.multivalue, null) != null ? true : null

  # Set identifier for routing policies
  set_identifier = try(
    each.value.routing_policy.weighted.set_identifier,
    try(
      each.value.routing_policy.latency.set_identifier,
      try(
        each.value.routing_policy.geolocation.set_identifier,
        try(
          each.value.routing_policy.failover.set_identifier,
          try(
            each.value.routing_policy.multivalue.set_identifier,
            try(each.value.routing_policy.ip_based.set_identifier, null)
          )
        )
      )
    )
  )

  # CIDR routing
  dynamic "cidr_routing_policy" {
    for_each = try(each.value.routing_policy.ip_based, null) != null ? [each.value.routing_policy.ip_based] : []
    content {
      collection_id = cidr_routing_policy.value.collection_id
      location_name = cidr_routing_policy.value.set_identifier
    }
  }
}

