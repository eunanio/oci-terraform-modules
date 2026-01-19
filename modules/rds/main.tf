locals {
  port = var.port != null ? var.port : (
    contains(["mysql", "mariadb"], var.engine) ? 3306 :
    var.engine == "postgres" ? 5432 :
    startswith(var.engine, "oracle") ? 1521 :
    startswith(var.engine, "sqlserver") ? 1433 : 3306
  )

  security_group_ids = var.create_security_group ? concat([aws_security_group.this[0].id], var.vpc_security_group_ids) : var.vpc_security_group_ids
  
  final_snapshot_identifier = var.final_snapshot_identifier != null ? var.final_snapshot_identifier : "${var.identifier}-final-snapshot"
  
  monitoring_role_arn = var.monitoring_interval > 0 ? (
    var.create_monitoring_role ? aws_iam_role.monitoring[0].arn : var.monitoring_role_arn
  ) : null
}

# Random password if not provided
resource "random_password" "master" {
  count = var.password == null ? 1 : 0

  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# DB Subnet Group
resource "aws_db_subnet_group" "this" {
  name        = "${var.identifier}-subnet-group"
  description = "Subnet group for ${var.identifier}"
  subnet_ids  = var.subnet_ids

  tags = merge(var.tags, { Name = "${var.identifier}-subnet-group" })
}

# Security Group
resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name        = "${var.identifier}-sg"
  description = "Security group for ${var.identifier}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.identifier}-sg" })
}

resource "aws_security_group_rule" "ingress_cidr" {
  count = var.create_security_group && length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  security_group_id = aws_security_group.this[0].id
  description       = "Database access from CIDR blocks"
  from_port         = local.port
  to_port           = local.port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
}

resource "aws_security_group_rule" "ingress_sg" {
  for_each = var.create_security_group ? toset(var.allowed_security_groups) : []

  type                     = "ingress"
  security_group_id        = aws_security_group.this[0].id
  description              = "Database access from security group"
  from_port                = local.port
  to_port                  = local.port
  protocol                 = "tcp"
  source_security_group_id = each.value
}

resource "aws_security_group_rule" "egress" {
  count = var.create_security_group ? 1 : 0

  type              = "egress"
  security_group_id = aws_security_group.this[0].id
  description       = "Allow all outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Parameter Group
resource "aws_db_parameter_group" "this" {
  count = var.create_parameter_group ? 1 : 0

  name        = "${var.identifier}-params"
  description = "Parameter group for ${var.identifier}"
  family      = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(var.tags, { Name = "${var.identifier}-params" })

  lifecycle {
    create_before_destroy = true
  }
}

# Option Group
resource "aws_db_option_group" "this" {
  count = var.create_option_group ? 1 : 0

  name                     = "${var.identifier}-options"
  option_group_description = "Option group for ${var.identifier}"
  engine_name              = var.engine
  major_engine_version     = var.major_engine_version

  dynamic "option" {
    for_each = var.options
    content {
      option_name                    = option.value.option_name
      port                           = option.value.port
      version                        = option.value.version
      db_security_group_memberships  = option.value.db_security_group_memberships
      vpc_security_group_memberships = option.value.vpc_security_group_memberships

      dynamic "option_settings" {
        for_each = option.value.option_settings
        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }
      }
    }
  }

  tags = merge(var.tags, { Name = "${var.identifier}-options" })

  lifecycle {
    create_before_destroy = true
  }
}

# Enhanced Monitoring IAM Role
resource "aws_iam_role" "monitoring" {
  count = var.create_monitoring_role && var.monitoring_interval > 0 ? 1 : 0

  name = "${var.identifier}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  count = var.create_monitoring_role && var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# RDS Instance
resource "aws_db_instance" "this" {
  identifier = var.identifier

  # Engine
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Database
  db_name  = var.db_name
  username = var.username
  password = var.password != null ? var.password : random_password.master[0].result
  port     = local.port

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null
  storage_type          = var.storage_type
  iops                  = var.iops
  storage_throughput    = var.storage_throughput
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id

  # Network
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = local.security_group_ids
  publicly_accessible    = var.publicly_accessible
  availability_zone      = var.availability_zone
  multi_az               = var.multi_az
  network_type           = var.network_type

  # Parameter and Option Groups
  parameter_group_name = var.create_parameter_group ? aws_db_parameter_group.this[0].name : var.parameter_group_name
  option_group_name    = var.create_option_group ? aws_db_option_group.this[0].name : var.option_group_name

  # Backup
  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  delete_automated_backups  = var.delete_automated_backups
  copy_tags_to_snapshot     = var.copy_tags_to_snapshot
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : local.final_snapshot_identifier
  snapshot_identifier       = var.snapshot_identifier

  # Maintenance
  maintenance_window          = var.maintenance_window
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately           = var.apply_immediately

  # Monitoring
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = local.monitoring_role_arn
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports

  # Security
  deletion_protection                 = var.deletion_protection
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  ca_cert_identifier                  = var.ca_cert_identifier

  # Engine-specific
  character_set_name   = var.character_set_name
  license_model        = var.license_model
  domain               = var.domain
  domain_iam_role_name = var.domain_iam_role_name

  tags = merge(var.tags, { Name = var.identifier })

  depends_on = [
    aws_iam_role_policy_attachment.monitoring
  ]
}

