data "aws_region" "current" {}

# VPC
resource "aws_vpc" "this" {
  cidr_block                           = var.cidr_block
  instance_tenancy                     = var.instance_tenancy
  enable_dns_support                   = var.enable_dns_support
  enable_dns_hostnames                 = var.enable_dns_hostnames
  enable_network_address_usage_metrics = var.enable_network_address_usage_metrics

  tags = merge(var.tags, var.vpc_tags, { Name = var.name })
}

# Secondary CIDR Blocks
resource "aws_vpc_ipv4_cidr_block_association" "secondary" {
  for_each = toset(var.secondary_cidr_blocks)

  vpc_id     = aws_vpc.this.id
  cidr_block = each.value
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  count = var.create_igw ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, var.igw_tags, { Name = "${var.name}-igw" })
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = var.nat_gateway_config.enabled && length(var.nat_gateway_config.allocation_ids) == 0 ? (
    var.nat_gateway_config.single_nat ? 1 : length(var.nat_gateway_config.subnet_ids)
  ) : 0

  domain = "vpc"

  tags = merge(var.tags, var.nat_gateway_tags, { Name = "${var.name}-nat-eip-${count.index + 1}" })

  depends_on = [aws_internet_gateway.this]
}

# NAT Gateways
resource "aws_nat_gateway" "this" {
  count = var.nat_gateway_config.enabled ? (
    var.nat_gateway_config.single_nat ? 1 : length(var.nat_gateway_config.subnet_ids)
  ) : 0

  allocation_id = length(var.nat_gateway_config.allocation_ids) > 0 ? (
    var.nat_gateway_config.single_nat ? var.nat_gateway_config.allocation_ids[0] : var.nat_gateway_config.allocation_ids[count.index]
  ) : aws_eip.nat[count.index].id

  subnet_id = var.nat_gateway_config.single_nat ? var.nat_gateway_config.subnet_ids[0] : var.nat_gateway_config.subnet_ids[count.index]

  tags = merge(var.tags, var.nat_gateway_tags, { Name = "${var.name}-nat-${count.index + 1}" })

  depends_on = [aws_internet_gateway.this]
}

# DHCP Options
resource "aws_vpc_dhcp_options" "this" {
  count = var.dhcp_options != null ? 1 : 0

  domain_name          = var.dhcp_options.domain_name
  domain_name_servers  = var.dhcp_options.domain_name_servers
  ntp_servers          = var.dhcp_options.ntp_servers
  netbios_name_servers = var.dhcp_options.netbios_name_servers
  netbios_node_type    = var.dhcp_options.netbios_node_type

  tags = merge(var.tags, { Name = "${var.name}-dhcp-options" })
}

resource "aws_vpc_dhcp_options_association" "this" {
  count = var.dhcp_options != null ? 1 : 0

  vpc_id          = aws_vpc.this.id
  dhcp_options_id = aws_vpc_dhcp_options.this[0].id
}

# VPC Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.flow_logs.enabled && var.flow_logs.create_log_group && var.flow_logs.destination_type == "cloud-watch-logs" ? 1 : 0

  name              = "/aws/vpc-flow-logs/${var.name}"
  retention_in_days = var.flow_logs.log_retention_days

  tags = merge(var.tags, { Name = "${var.name}-flow-logs" })
}

resource "aws_iam_role" "flow_logs" {
  count = var.flow_logs.enabled && var.flow_logs.create_iam_role && var.flow_logs.destination_type == "cloud-watch-logs" ? 1 : 0

  name = "${var.name}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.flow_logs.enabled && var.flow_logs.create_iam_role && var.flow_logs.destination_type == "cloud-watch-logs" ? 1 : 0

  name = "${var.name}-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "this" {
  count = var.flow_logs.enabled ? 1 : 0

  vpc_id                   = aws_vpc.this.id
  traffic_type             = var.flow_logs.traffic_type
  log_destination_type     = var.flow_logs.destination_type
  max_aggregation_interval = var.flow_logs.max_aggregation_interval

  log_destination = var.flow_logs.destination_type == "cloud-watch-logs" ? (
    var.flow_logs.log_destination != null ? var.flow_logs.log_destination : aws_cloudwatch_log_group.flow_logs[0].arn
  ) : var.flow_logs.log_destination

  iam_role_arn = var.flow_logs.destination_type == "cloud-watch-logs" ? (
    var.flow_logs.iam_role_arn != null ? var.flow_logs.iam_role_arn : aws_iam_role.flow_logs[0].arn
  ) : null

  log_format = var.flow_logs.log_format

  tags = merge(var.tags, { Name = "${var.name}-flow-log" })
}

# Endpoint Security Group
resource "aws_security_group" "endpoints" {
  count = var.create_endpoint_security_group ? 1 : 0

  name        = "${var.name}-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-endpoints-sg" })
}

resource "aws_security_group_rule" "endpoints_ingress_cidr" {
  count = var.create_endpoint_security_group && length(var.endpoint_security_group_rules.ingress_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.endpoints[0].id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.endpoint_security_group_rules.ingress_cidr_blocks
  description       = "HTTPS from VPC"
}

resource "aws_security_group_rule" "endpoints_ingress_custom" {
  for_each = var.create_endpoint_security_group ? {
    for idx, rule in var.endpoint_security_group_rules.ingress_rules : idx => rule
  } : {}

  type              = "ingress"
  security_group_id = aws_security_group.endpoints[0].id
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
}

resource "aws_security_group_rule" "endpoints_egress" {
  count = var.create_endpoint_security_group ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.endpoints[0].id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound"
}

# Gateway VPC Endpoints
resource "aws_vpc_endpoint" "gateway" {
  for_each = var.gateway_endpoints

  vpc_id            = aws_vpc.this.id
  service_name      = each.value.service_name
  vpc_endpoint_type = "Gateway"
  route_table_ids   = each.value.route_table_ids
  policy            = each.value.policy

  tags = merge(var.tags, { Name = "${var.name}-${each.key}-endpoint" })
}

# Interface VPC Endpoints
resource "aws_vpc_endpoint" "interface" {
  for_each = var.interface_endpoints

  vpc_id              = aws_vpc.this.id
  service_name        = each.value.service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = each.value.subnet_ids
  private_dns_enabled = each.value.private_dns_enabled
  policy              = each.value.policy

  security_group_ids = length(each.value.security_group_ids) > 0 ? each.value.security_group_ids : (
    var.create_endpoint_security_group ? [aws_security_group.endpoints[0].id] : []
  )

  tags = merge(var.tags, { Name = "${var.name}-${each.key}-endpoint" })
}

# Default Security Group
resource "aws_default_security_group" "this" {
  count = var.manage_default_security_group ? 1 : 0

  vpc_id = aws_vpc.this.id

  dynamic "ingress" {
    for_each = var.default_security_group_ingress
    content {
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
      self             = ingress.value.self
      description      = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.default_security_group_egress
    content {
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      cidr_blocks      = egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
      self             = egress.value.self
      description      = egress.value.description
    }
  }

  tags = merge(var.tags, { Name = "${var.name}-default-sg" })
}

# Default Network ACL
resource "aws_default_network_acl" "this" {
  count = var.manage_default_network_acl ? 1 : 0

  default_network_acl_id = aws_vpc.this.default_network_acl_id

  dynamic "ingress" {
    for_each = var.default_network_acl_ingress
    content {
      rule_no         = ingress.value.rule_no
      action          = ingress.value.action
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_block      = ingress.value.cidr_block
      ipv6_cidr_block = ingress.value.ipv6_cidr_block
    }
  }

  dynamic "egress" {
    for_each = var.default_network_acl_egress
    content {
      rule_no         = egress.value.rule_no
      action          = egress.value.action
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      protocol        = egress.value.protocol
      cidr_block      = egress.value.cidr_block
      ipv6_cidr_block = egress.value.ipv6_cidr_block
    }
  }

  tags = merge(var.tags, { Name = "${var.name}-default-nacl" })

  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

