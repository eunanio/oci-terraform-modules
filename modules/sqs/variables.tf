# Queue Name
variable "name" {
  description = "Name of the SQS queue"
  type        = string
}

# Queue Type
variable "fifo_queue" {
  description = "Whether this is a FIFO queue"
  type        = bool
  default     = false
}

# FIFO Settings
variable "content_based_deduplication" {
  description = "Enable content-based deduplication for FIFO queues"
  type        = bool
  default     = false
}

variable "deduplication_scope" {
  description = "Deduplication scope for FIFO queues (messageGroup or queue)"
  type        = string
  default     = null
}

variable "fifo_throughput_limit" {
  description = "FIFO throughput limit (perQueue or perMessageGroupId)"
  type        = string
  default     = null
}

# Message Settings
variable "delay_seconds" {
  description = "Delay in seconds before messages become available"
  type        = number
  default     = 0
}

variable "max_message_size" {
  description = "Maximum message size in bytes (1024-262144)"
  type        = number
  default     = 262144
}

variable "message_retention_seconds" {
  description = "Message retention period in seconds (60-1209600)"
  type        = number
  default     = 345600 # 4 days
}

variable "receive_wait_time_seconds" {
  description = "Long polling wait time in seconds (0-20)"
  type        = number
  default     = 0
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout in seconds (0-43200)"
  type        = number
  default     = 30
}

# Encryption
variable "sqs_managed_sse_enabled" {
  description = "Enable SQS managed server-side encryption"
  type        = bool
  default     = true
}

variable "kms_master_key_id" {
  description = "KMS key ID for encryption (overrides SQS managed SSE)"
  type        = string
  default     = null
}

variable "kms_data_key_reuse_period_seconds" {
  description = "KMS data key reuse period in seconds (60-86400)"
  type        = number
  default     = 300
}

# Dead Letter Queue
variable "create_dlq" {
  description = "Whether to create a dead letter queue"
  type        = bool
  default     = false
}

variable "dlq_name" {
  description = "Name of the dead letter queue (defaults to {name}-dlq)"
  type        = string
  default     = null
}

variable "dlq_message_retention_seconds" {
  description = "Message retention period for DLQ in seconds"
  type        = number
  default     = 1209600 # 14 days
}

variable "max_receive_count" {
  description = "Number of times a message can be received before moving to DLQ"
  type        = number
  default     = 3
}

variable "existing_dlq_arn" {
  description = "ARN of an existing dead letter queue to use"
  type        = string
  default     = null
}

# Queue Policy
variable "policy" {
  description = "JSON policy document for the queue"
  type        = string
  default     = null
}

variable "create_policy" {
  description = "Whether to create a queue policy"
  type        = bool
  default     = false
}

variable "policy_statements" {
  description = "List of policy statements for the queue"
  type = list(object({
    sid       = optional(string)
    effect    = optional(string, "Allow")
    principals = optional(object({
      type        = string
      identifiers = list(string)
    }))
    actions   = list(string)
    resources = optional(list(string))
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
  }))
  default = []
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

