# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "vpc_main_route_table_id" {
  description = "ID of the main route table"
  value       = aws_vpc.this.main_route_table_id
}

output "vpc_default_security_group_id" {
  description = "ID of the default security group"
  value       = aws_vpc.this.default_security_group_id
}

output "vpc_default_network_acl_id" {
  description = "ID of the default network ACL"
  value       = aws_vpc.this.default_network_acl_id
}

output "vpc_default_route_table_id" {
  description = "ID of the default route table"
  value       = aws_vpc.this.default_route_table_id
}

# Secondary CIDR Blocks
output "secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks"
  value       = [for assoc in aws_vpc_ipv4_cidr_block_association.secondary : assoc.cidr_block]
}

# Internet Gateway
output "igw_id" {
  description = "ID of the Internet Gateway"
  value       = var.create_igw ? aws_internet_gateway.this[0].id : null
}

output "igw_arn" {
  description = "ARN of the Internet Gateway"
  value       = var.create_igw ? aws_internet_gateway.this[0].arn : null
}

# NAT Gateway
output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "List of NAT Gateway public IPs"
  value       = aws_nat_gateway.this[*].public_ip
}

output "nat_eip_ids" {
  description = "List of NAT EIP IDs"
  value       = aws_eip.nat[*].id
}

output "nat_eip_public_ips" {
  description = "List of NAT EIP public IPs"
  value       = aws_eip.nat[*].public_ip
}

# DHCP Options
output "dhcp_options_id" {
  description = "ID of the DHCP options set"
  value       = var.dhcp_options != null ? aws_vpc_dhcp_options.this[0].id : null
}

# Flow Logs
output "flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = var.flow_logs.enabled ? aws_flow_log.this[0].id : null
}

output "flow_log_cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for flow logs"
  value       = var.flow_logs.enabled && var.flow_logs.create_log_group ? aws_cloudwatch_log_group.flow_logs[0].arn : null
}

output "flow_log_iam_role_arn" {
  description = "ARN of the IAM role for flow logs"
  value       = var.flow_logs.enabled && var.flow_logs.create_iam_role ? aws_iam_role.flow_logs[0].arn : null
}

# VPC Endpoints
output "gateway_endpoint_ids" {
  description = "Map of gateway endpoint IDs"
  value       = { for k, v in aws_vpc_endpoint.gateway : k => v.id }
}

output "interface_endpoint_ids" {
  description = "Map of interface endpoint IDs"
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}

output "interface_endpoint_dns_entries" {
  description = "Map of interface endpoint DNS entries"
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.dns_entry }
}

output "endpoint_security_group_id" {
  description = "ID of the endpoint security group"
  value       = var.create_endpoint_security_group ? aws_security_group.endpoints[0].id : null
}

