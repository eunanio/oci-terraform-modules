# Cluster Outputs
output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = local.cluster_arn
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = local.cluster_arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = local.cluster_name
}

# Task Definition Outputs
output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_family" {
  description = "Family of the task definition"
  value       = aws_ecs_task_definition.this.family
}

output "task_definition_revision" {
  description = "Revision of the task definition"
  value       = aws_ecs_task_definition.this.revision
}

# Service Outputs
output "service_id" {
  description = "ID of the ECS service"
  value       = aws_ecs_service.this.id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.this.name
}

output "service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.this.id
}

# IAM Role Outputs
output "task_execution_role_arn" {
  description = "ARN of the task execution role"
  value       = local.task_execution_role_arn
}

output "task_execution_role_name" {
  description = "Name of the task execution role"
  value       = var.create_task_execution_role ? aws_iam_role.task_execution[0].name : null
}

output "task_role_arn" {
  description = "ARN of the task role"
  value       = local.task_role_arn
}

output "task_role_name" {
  description = "Name of the task role"
  value       = var.create_task_role ? aws_iam_role.task[0].name : null
}

# Security Group Outputs
output "security_group_id" {
  description = "ID of the created security group"
  value       = var.create_security_group ? aws_security_group.this[0].id : null
}

output "security_group_arn" {
  description = "ARN of the created security group"
  value       = var.create_security_group ? aws_security_group.this[0].arn : null
}

# CloudWatch Log Group
output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = var.create_log_group ? aws_cloudwatch_log_group.this[0].name : local.log_group_name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = var.create_log_group ? aws_cloudwatch_log_group.this[0].arn : null
}

# Service Discovery
output "service_discovery_arn" {
  description = "ARN of the service discovery service"
  value       = var.service_discovery != null ? aws_service_discovery_service.this[0].arn : null
}

# Auto Scaling
output "autoscaling_target_id" {
  description = "ID of the auto scaling target"
  value       = var.autoscaling != null ? aws_appautoscaling_target.this[0].id : null
}

