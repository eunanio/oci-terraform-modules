locals {
  queue_name = var.fifo_queue ? (
    endswith(var.name, ".fifo") ? var.name : "${var.name}.fifo"
  ) : var.name
  
  dlq_name = var.create_dlq ? (
    var.dlq_name != null ? var.dlq_name : (
      var.fifo_queue ? (
        endswith(var.name, ".fifo") ? "${trimsuffix(var.name, ".fifo")}-dlq.fifo" : "${var.name}-dlq.fifo"
      ) : "${var.name}-dlq"
    )
  ) : null
  
  dlq_arn = var.create_dlq ? aws_sqs_queue.dlq[0].arn : var.existing_dlq_arn
  
  # Build policy from statements
  generated_policy = var.create_policy && length(var.policy_statements) > 0 ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      for stmt in var.policy_statements : {
        Sid       = stmt.sid
        Effect    = stmt.effect
        Principal = stmt.principals != null ? {
          (stmt.principals.type) = stmt.principals.identifiers
        } : "*"
        Action    = stmt.actions
        Resource  = stmt.resources != null ? stmt.resources : [aws_sqs_queue.this.arn]
        Condition = length(stmt.conditions) > 0 ? {
          for condition in stmt.conditions : condition.test => {
            (condition.variable) = condition.values
          }
        } : null
      }
    ]
  }) : null
}

# Dead Letter Queue
resource "aws_sqs_queue" "dlq" {
  count = var.create_dlq ? 1 : 0

  name = local.dlq_name

  # FIFO settings
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.fifo_queue ? var.content_based_deduplication : null

  # Message settings
  message_retention_seconds  = var.dlq_message_retention_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds

  # Encryption (same as main queue)
  sqs_managed_sse_enabled           = var.kms_master_key_id == null ? var.sqs_managed_sse_enabled : null
  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_master_key_id != null ? var.kms_data_key_reuse_period_seconds : null

  tags = merge(var.tags, { Name = local.dlq_name })
}

# Main SQS Queue
resource "aws_sqs_queue" "this" {
  name = local.queue_name

  # FIFO settings
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.fifo_queue ? var.content_based_deduplication : null
  deduplication_scope         = var.fifo_queue ? var.deduplication_scope : null
  fifo_throughput_limit       = var.fifo_queue ? var.fifo_throughput_limit : null

  # Message settings
  delay_seconds              = var.delay_seconds
  max_message_size           = var.max_message_size
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds

  # Encryption
  sqs_managed_sse_enabled           = var.kms_master_key_id == null ? var.sqs_managed_sse_enabled : null
  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_master_key_id != null ? var.kms_data_key_reuse_period_seconds : null

  # Redrive policy (DLQ)
  redrive_policy = local.dlq_arn != null ? jsonencode({
    deadLetterTargetArn = local.dlq_arn
    maxReceiveCount     = var.max_receive_count
  }) : null

  tags = merge(var.tags, { Name = local.queue_name })
}

# Redrive allow policy for DLQ (allows main queue to send messages)
resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  count = var.create_dlq ? 1 : 0

  queue_url = aws_sqs_queue.dlq[0].id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.this.arn]
  })
}

# Queue Policy
resource "aws_sqs_queue_policy" "this" {
  count = var.policy != null || local.generated_policy != null ? 1 : 0

  queue_url = aws_sqs_queue.this.id
  policy    = var.policy != null ? var.policy : local.generated_policy
}

# DLQ Policy (same as main queue if specified)
resource "aws_sqs_queue_policy" "dlq" {
  count = var.create_dlq && var.policy != null ? 1 : 0

  queue_url = aws_sqs_queue.dlq[0].id
  policy    = var.policy
}

