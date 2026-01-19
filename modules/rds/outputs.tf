# Instance Outputs
output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.this.arn
}

output "db_instance_identifier" {
  description = "Identifier of the RDS instance"
  value       = aws_db_instance.this.identifier
}

output "db_instance_resource_id" {
  description = "Resource ID of the RDS instance"
  value       = aws_db_instance.this.resource_id
}

output "db_instance_status" {
  description = "Status of the RDS instance"
  value       = aws_db_instance.this.status
}

# Connection Information
output "db_instance_endpoint" {
  description = "Connection endpoint"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_address" {
  description = "Hostname of the RDS instance"
  value       = aws_db_instance.this.address
}

output "db_instance_port" {
  description = "Database port"
  value       = aws_db_instance.this.port
}

output "db_instance_hosted_zone_id" {
  description = "Canonical hosted zone ID of the instance"
  value       = aws_db_instance.this.hosted_zone_id
}

# Database Information
output "db_instance_name" {
  description = "Name of the database"
  value       = aws_db_instance.this.db_name
}

output "db_instance_username" {
  description = "Master username"
  value       = aws_db_instance.this.username
  sensitive   = true
}

output "db_instance_password" {
  description = "Master password"
  value       = var.password != null ? var.password : random_password.master[0].result
  sensitive   = true
}

# Engine Information
output "db_instance_engine" {
  description = "Database engine"
  value       = aws_db_instance.this.engine
}

output "db_instance_engine_version_actual" {
  description = "Running engine version"
  value       = aws_db_instance.this.engine_version_actual
}

# Storage Information
output "db_instance_allocated_storage" {
  description = "Allocated storage in GB"
  value       = aws_db_instance.this.allocated_storage
}

output "db_instance_storage_type" {
  description = "Storage type"
  value       = aws_db_instance.this.storage_type
}

# Network Information
output "db_instance_availability_zone" {
  description = "Availability zone"
  value       = aws_db_instance.this.availability_zone
}

output "db_instance_multi_az" {
  description = "Whether Multi-AZ is enabled"
  value       = aws_db_instance.this.multi_az
}

# Subnet Group
output "db_subnet_group_id" {
  description = "ID of the DB subnet group"
  value       = aws_db_subnet_group.this.id
}

output "db_subnet_group_arn" {
  description = "ARN of the DB subnet group"
  value       = aws_db_subnet_group.this.arn
}

# Security Group
output "security_group_id" {
  description = "ID of the created security group"
  value       = var.create_security_group ? aws_security_group.this[0].id : null
}

output "security_group_arn" {
  description = "ARN of the created security group"
  value       = var.create_security_group ? aws_security_group.this[0].arn : null
}

# Parameter Group
output "db_parameter_group_id" {
  description = "ID of the DB parameter group"
  value       = var.create_parameter_group ? aws_db_parameter_group.this[0].id : null
}

output "db_parameter_group_arn" {
  description = "ARN of the DB parameter group"
  value       = var.create_parameter_group ? aws_db_parameter_group.this[0].arn : null
}

# Option Group
output "db_option_group_id" {
  description = "ID of the DB option group"
  value       = var.create_option_group ? aws_db_option_group.this[0].id : null
}

output "db_option_group_arn" {
  description = "ARN of the DB option group"
  value       = var.create_option_group ? aws_db_option_group.this[0].arn : null
}

# Monitoring Role
output "monitoring_role_arn" {
  description = "ARN of the enhanced monitoring IAM role"
  value       = var.create_monitoring_role ? aws_iam_role.monitoring[0].arn : null
}

# CA Certificate
output "db_instance_ca_cert_identifier" {
  description = "CA certificate identifier"
  value       = aws_db_instance.this.ca_cert_identifier
}

