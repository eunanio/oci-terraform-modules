locals {
  security_group_ids = var.create_security_group ? concat([aws_security_group.this[0].id], var.vpc_security_group_ids) : var.vpc_security_group_ids
  key_name           = var.create_key_pair ? aws_key_pair.this[0].key_name : var.key_name
}

# Key Pair
resource "aws_key_pair" "this" {
  count = var.create_key_pair && var.public_key != null ? 1 : 0

  key_name   = "${var.name}-key"
  public_key = var.public_key

  tags = merge(var.tags, { Name = "${var.name}-key" })
}

# Security Group
resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name        = "${var.name}-sg"
  description = "Security group for ${var.name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-sg" })
}

resource "aws_security_group_rule" "ingress" {
  for_each = var.create_security_group ? {
    for idx, rule in var.security_group_rules.ingress : idx => rule
  } : {}

  type              = "ingress"
  security_group_id = aws_security_group.this[0].id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks : null
  ipv6_cidr_blocks  = length(each.value.ipv6_cidr_blocks) > 0 ? each.value.ipv6_cidr_blocks : null
  self              = each.value.self ? true : null

  source_security_group_id = length(each.value.security_groups) > 0 ? each.value.security_groups[0] : null
}

resource "aws_security_group_rule" "egress" {
  for_each = var.create_security_group ? {
    for idx, rule in var.security_group_rules.egress : idx => rule
  } : {}

  type              = "egress"
  security_group_id = aws_security_group.this[0].id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks : null
  ipv6_cidr_blocks  = length(each.value.ipv6_cidr_blocks) > 0 ? each.value.ipv6_cidr_blocks : null
  self              = each.value.self ? true : null

  source_security_group_id = length(each.value.security_groups) > 0 ? each.value.security_groups[0] : null
}

# EC2 Instance
resource "aws_instance" "this" {
  ami                         = var.ami
  instance_type               = var.instance_type
  availability_zone           = var.availability_zone
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = local.security_group_ids
  key_name                    = local.key_name
  iam_instance_profile        = var.iam_instance_profile
  private_ip                  = var.private_ip
  secondary_private_ips       = length(var.secondary_private_ips) > 0 ? var.secondary_private_ips : null
  associate_public_ip_address = var.associate_public_ip_address
  source_dest_check           = var.source_dest_check

  # User Data
  user_data                   = var.user_data
  user_data_base64            = var.user_data_base64
  user_data_replace_on_change = var.user_data_replace_on_change

  # Monitoring
  monitoring = var.monitoring

  # Placement
  placement_group = var.placement_group
  tenancy         = var.tenancy
  host_id         = var.host_id

  # Lifecycle
  disable_api_termination              = var.disable_api_termination
  disable_api_stop                     = var.disable_api_stop
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  hibernation                          = var.hibernation

  # Root Volume
  root_block_device {
    volume_size           = var.root_volume.volume_size
    volume_type           = var.root_volume.volume_type
    iops                  = var.root_volume.iops
    throughput            = var.root_volume.throughput
    encrypted             = var.root_volume.encrypted
    kms_key_id            = var.root_volume.kms_key_id
    delete_on_termination = var.root_volume.delete_on_termination
    tags                  = merge(var.tags, var.volume_tags, { Name = "${var.name}-root" })
  }

  # Metadata Options (IMDSv2)
  metadata_options {
    http_endpoint               = var.metadata_options.http_endpoint
    http_tokens                 = var.metadata_options.http_tokens
    http_put_response_hop_limit = var.metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = var.metadata_options.instance_metadata_tags
  }

  # Credit Specification
  dynamic "credit_specification" {
    for_each = var.credit_specification != null ? [var.credit_specification] : []
    content {
      cpu_credits = credit_specification.value.cpu_credits
    }
  }

  # Capacity Reservation
  dynamic "capacity_reservation_specification" {
    for_each = var.capacity_reservation_specification != null ? [var.capacity_reservation_specification] : []
    content {
      capacity_reservation_preference = capacity_reservation_specification.value.capacity_reservation_preference

      dynamic "capacity_reservation_target" {
        for_each = capacity_reservation_specification.value.capacity_reservation_target != null ? [capacity_reservation_specification.value.capacity_reservation_target] : []
        content {
          capacity_reservation_id                 = capacity_reservation_target.value.capacity_reservation_id
          capacity_reservation_resource_group_arn = capacity_reservation_target.value.capacity_reservation_resource_group_arn
        }
      }
    }
  }

  # Enclave Options
  enclave_options {
    enabled = var.enclave_options_enabled
  }

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    ignore_changes = [ami]
  }
}

# Additional EBS Volumes
resource "aws_ebs_volume" "this" {
  for_each = var.ebs_volumes

  availability_zone = var.availability_zone != null ? var.availability_zone : aws_instance.this.availability_zone
  size              = each.value.volume_size
  type              = each.value.volume_type
  iops              = each.value.iops
  throughput        = each.value.throughput
  encrypted         = each.value.encrypted
  kms_key_id        = each.value.kms_key_id
  snapshot_id       = each.value.snapshot_id

  tags = merge(var.tags, var.volume_tags, { Name = "${var.name}-${each.key}" })
}

resource "aws_volume_attachment" "this" {
  for_each = var.ebs_volumes

  device_name = each.value.device_name
  volume_id   = aws_ebs_volume.this[each.key].id
  instance_id = aws_instance.this.id
}

# Elastic IP
resource "aws_eip" "this" {
  count = var.create_eip ? 1 : 0

  domain   = var.eip_domain
  instance = aws_instance.this.id

  tags = merge(var.tags, { Name = "${var.name}-eip" })
}

