output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function (for API Gateway)"
  value       = aws_lambda_function.this.invoke_arn
}

output "qualified_arn" {
  description = "Qualified ARN of the Lambda function (includes version)"
  value       = aws_lambda_function.this.qualified_arn
}

output "version" {
  description = "Latest published version of the Lambda function"
  value       = aws_lambda_function.this.version
}

output "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the deployment package"
  value       = aws_lambda_function.this.source_code_hash
}

output "source_code_size" {
  description = "Size in bytes of the function deployment package"
  value       = aws_lambda_function.this.source_code_size
}

output "role_arn" {
  description = "ARN of the IAM role attached to the Lambda function"
  value       = local.role_arn
}

output "role_name" {
  description = "Name of the created IAM role (null if using existing role)"
  value       = local.create_role ? aws_iam_role.lambda[0].name : null
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda.arn
}

output "function_url" {
  description = "Lambda function URL (if configured)"
  value       = try(aws_lambda_function_url.this[0].function_url, null)
}

output "function_url_id" {
  description = "Lambda function URL ID (if configured)"
  value       = try(aws_lambda_function_url.this[0].url_id, null)
}

