# Local values for deployment package selection
locals {
  use_source_dir = var.source_dir != null
  use_filename   = var.filename != null && !local.use_source_dir
  use_s3         = var.s3_bucket != null && var.s3_key != null && !local.use_source_dir && !local.use_filename
  
  create_role = var.create_role && var.role_arn == null
  role_arn    = local.create_role ? aws_iam_role.lambda[0].arn : var.role_arn
}

# Archive data source for source_dir option
data "archive_file" "source" {
  count       = local.use_source_dir ? 1 : 0
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/.terraform/tmp/${var.function_name}.zip"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda" {
  count = local.create_role ? 1 : 0
  name  = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach basic execution role policy
resource "aws_iam_role_policy_attachment" "basic_execution" {
  count      = local.create_role ? 1 : 0
  role       = aws_iam_role.lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach VPC execution role policy if VPC is configured
resource "aws_iam_role_policy_attachment" "vpc_execution" {
  count      = local.create_role && var.vpc_config != null ? 1 : 0
  role       = aws_iam_role.lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Attach additional managed policies
resource "aws_iam_role_policy_attachment" "additional" {
  for_each   = local.create_role ? toset(var.policy_arns) : []
  role       = aws_iam_role.lambda[0].name
  policy_arn = each.value
}

# Attach inline policy
resource "aws_iam_role_policy" "inline" {
  count  = local.create_role && var.inline_policy != null ? 1 : 0
  name   = "${var.function_name}-inline-policy"
  role   = aws_iam_role.lambda[0].id
  policy = var.inline_policy
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.logging.retention_days

  tags = var.tags
}

# Lambda Function
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  description   = var.description
  role          = local.role_arn
  handler       = var.handler
  runtime       = var.runtime
  architectures = var.architectures
  memory_size   = var.memory_size
  timeout       = var.timeout
  layers        = var.layers

  # Deployment package - source_dir (auto-zipped)
  filename         = local.use_source_dir ? data.archive_file.source[0].output_path : (local.use_filename ? var.filename : null)
  source_code_hash = local.use_source_dir ? data.archive_file.source[0].output_base64sha256 : (local.use_filename ? filebase64sha256(var.filename) : null)

  # Deployment package - S3
  s3_bucket         = local.use_s3 ? var.s3_bucket : null
  s3_key            = local.use_s3 ? var.s3_key : null
  s3_object_version = local.use_s3 ? var.s3_object_version : null

  # Environment variables
  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  # VPC configuration
  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  # Dead letter queue
  dynamic "dead_letter_config" {
    for_each = var.dead_letter_config != null ? [var.dead_letter_config] : []
    content {
      target_arn = dead_letter_config.value.target_arn
    }
  }

  # X-Ray tracing
  dynamic "tracing_config" {
    for_each = var.tracing_mode != null ? [1] : []
    content {
      mode = var.tracing_mode
    }
  }

  # Ephemeral storage
  ephemeral_storage {
    size = var.ephemeral_storage_size
  }

  # Logging configuration
  logging_config {
    log_format = var.logging.log_format
    log_group  = aws_cloudwatch_log_group.lambda.name
  }

  # Reserved concurrency
  reserved_concurrent_executions = var.reserved_concurrent_executions

  tags = var.tags

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.basic_execution,
    aws_iam_role_policy_attachment.vpc_execution,
  ]
}

# Provisioned Concurrency
resource "aws_lambda_provisioned_concurrency_config" "this" {
  count                             = var.provisioned_concurrency != null ? 1 : 0
  function_name                     = aws_lambda_function.this.function_name
  qualifier                         = var.provisioned_concurrency.qualifier
  provisioned_concurrent_executions = var.provisioned_concurrency.provisioned_concurrent_executions
}

# Function URL
resource "aws_lambda_function_url" "this" {
  count              = var.function_url != null ? 1 : 0
  function_name      = aws_lambda_function.this.function_name
  authorization_type = var.function_url.authorization_type

  dynamic "cors" {
    for_each = var.function_url.cors != null ? [var.function_url.cors] : []
    content {
      allow_credentials = cors.value.allow_credentials
      allow_headers     = cors.value.allow_headers
      allow_methods     = cors.value.allow_methods
      allow_origins     = cors.value.allow_origins
      expose_headers    = cors.value.expose_headers
      max_age           = cors.value.max_age
    }
  }
}

# Lambda Permissions (Triggers)
resource "aws_lambda_permission" "triggers" {
  for_each = var.allowed_triggers

  statement_id       = each.key
  action             = "lambda:InvokeFunction"
  function_name      = aws_lambda_function.this.function_name
  principal          = "${each.value.service}.amazonaws.com"
  source_arn         = each.value.source_arn
  source_account     = each.value.source_account
  event_source_token = each.value.event_source_token
}

# Event Source Mappings
resource "aws_lambda_event_source_mapping" "this" {
  for_each = var.event_source_mappings

  function_name     = aws_lambda_function.this.arn
  event_source_arn  = each.value.event_source_arn
  batch_size        = each.value.batch_size
  enabled           = each.value.enabled
  starting_position = each.value.starting_position
  starting_position_timestamp = each.value.starting_position_timestamp
  maximum_batching_window_in_seconds = each.value.maximum_batching_window_in_seconds
  maximum_retry_attempts             = each.value.maximum_retry_attempts
  maximum_record_age_in_seconds      = each.value.maximum_record_age_in_seconds
  bisect_batch_on_function_error     = each.value.bisect_batch_on_function_error
  parallelization_factor             = each.value.parallelization_factor

  dynamic "filter_criteria" {
    for_each = each.value.filter_criteria != null ? [each.value.filter_criteria] : []
    content {
      dynamic "filter" {
        for_each = filter_criteria.value.filters
        content {
          pattern = filter.value.pattern
        }
      }
    }
  }
}

