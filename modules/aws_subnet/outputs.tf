# Subnet Outputs
output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = { for name, subnet in aws_subnet.this : name => subnet.id }
}

output "subnet_arns" {
  description = "Map of subnet names to ARNs"
  value       = { for name, subnet in aws_subnet.this : name => subnet.arn }
}

output "subnet_cidr_blocks" {
  description = "Map of subnet names to CIDR blocks"
  value       = { for name, subnet in aws_subnet.this : name => subnet.cidr_block }
}

output "subnet_availability_zones" {
  description = "Map of subnet names to availability zones"
  value       = { for name, subnet in aws_subnet.this : name => subnet.availability_zone }
}

output "subnets" {
  description = "Map of all subnet attributes"
  value = {
    for name, subnet in aws_subnet.this : name => {
      id                = subnet.id
      arn               = subnet.arn
      cidr_block        = subnet.cidr_block
      availability_zone = subnet.availability_zone
    }
  }
}

# Categorized Subnet IDs
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [for name, subnet in aws_subnet.this : subnet.id if contains(keys(local.public_subnets), name)]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [for name, subnet in aws_subnet.this : subnet.id if contains(keys(local.private_subnets), name)]
}

# Route Table Outputs
output "route_table_ids" {
  description = "Map of subnet names to route table IDs"
  value       = { for name, rt in aws_route_table.this : name => rt.id }
}

output "route_table_arns" {
  description = "Map of subnet names to route table ARNs"
  value       = { for name, rt in aws_route_table.this : name => rt.arn }
}

# Network ACL Outputs
output "network_acl_ids" {
  description = "Map of subnet names to network ACL IDs"
  value       = { for name, nacl in aws_network_acl.this : name => nacl.id }
}

output "network_acl_arns" {
  description = "Map of subnet names to network ACL ARNs"
  value       = { for name, nacl in aws_network_acl.this : name => nacl.arn }
}

# Subnet Group Outputs
output "db_subnet_group_id" {
  description = "ID of the DB subnet group"
  value       = var.create_db_subnet_group ? aws_db_subnet_group.this[0].id : null
}

output "db_subnet_group_arn" {
  description = "ARN of the DB subnet group"
  value       = var.create_db_subnet_group ? aws_db_subnet_group.this[0].arn : null
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = var.create_db_subnet_group ? aws_db_subnet_group.this[0].name : null
}

output "elasticache_subnet_group_id" {
  description = "ID of the ElastiCache subnet group"
  value       = var.create_elasticache_subnet_group ? aws_elasticache_subnet_group.this[0].id : null
}

output "elasticache_subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = var.create_elasticache_subnet_group ? aws_elasticache_subnet_group.this[0].name : null
}

output "redshift_subnet_group_id" {
  description = "ID of the Redshift subnet group"
  value       = var.create_redshift_subnet_group ? aws_redshift_subnet_group.this[0].id : null
}

output "redshift_subnet_group_name" {
  description = "Name of the Redshift subnet group"
  value       = var.create_redshift_subnet_group ? aws_redshift_subnet_group.this[0].name : null
}

# Availability Zones
output "availability_zones" {
  description = "List of availability zones used"
  value       = distinct([for subnet in aws_subnet.this : subnet.availability_zone])
}

