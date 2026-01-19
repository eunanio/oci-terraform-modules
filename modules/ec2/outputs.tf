# Instance Outputs
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.this.arn
}

output "instance_state" {
  description = "State of the EC2 instance"
  value       = aws_instance.this.instance_state
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.this.private_ip
}

output "private_dns" {
  description = "Private DNS name of the instance"
  value       = aws_instance.this.private_dns
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.this.public_ip
}

output "public_dns" {
  description = "Public DNS name of the instance"
  value       = aws_instance.this.public_dns
}

output "availability_zone" {
  description = "Availability zone of the instance"
  value       = aws_instance.this.availability_zone
}

# Security Group Outputs
output "security_group_id" {
  description = "ID of the created security group (if created)"
  value       = var.create_security_group ? aws_security_group.this[0].id : null
}

output "security_group_arn" {
  description = "ARN of the created security group (if created)"
  value       = var.create_security_group ? aws_security_group.this[0].arn : null
}

# Key Pair Outputs
output "key_pair_name" {
  description = "Name of the key pair"
  value       = local.key_name
}

output "key_pair_id" {
  description = "ID of the created key pair (if created)"
  value       = var.create_key_pair ? aws_key_pair.this[0].key_pair_id : null
}

output "key_pair_fingerprint" {
  description = "Fingerprint of the created key pair (if created)"
  value       = var.create_key_pair ? aws_key_pair.this[0].fingerprint : null
}

# EBS Volume Outputs
output "root_volume_id" {
  description = "ID of the root EBS volume"
  value       = aws_instance.this.root_block_device[0].volume_id
}

output "ebs_volumes" {
  description = "Map of additional EBS volume attributes"
  value = {
    for name, volume in aws_ebs_volume.this : name => {
      id               = volume.id
      arn              = volume.arn
      availability_zone = volume.availability_zone
    }
  }
}

output "ebs_volume_ids" {
  description = "Map of additional EBS volume names to IDs"
  value       = { for name, volume in aws_ebs_volume.this : name => volume.id }
}

# Elastic IP Outputs
output "eip_id" {
  description = "ID of the Elastic IP (if created)"
  value       = var.create_eip ? aws_eip.this[0].id : null
}

output "eip_public_ip" {
  description = "Public IP address of the Elastic IP (if created)"
  value       = var.create_eip ? aws_eip.this[0].public_ip : null
}

output "eip_allocation_id" {
  description = "Allocation ID of the Elastic IP (if created)"
  value       = var.create_eip ? aws_eip.this[0].allocation_id : null
}

# Primary Network Interface
output "primary_network_interface_id" {
  description = "ID of the primary network interface"
  value       = aws_instance.this.primary_network_interface_id
}

