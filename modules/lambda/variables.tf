# Function Configuration
variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

variable "runtime" {
  description = "Runtime for the Lambda function (e.g., python3.12, nodejs20.x)"
  type        = string
}

variable "handler" {
  description = "Function entrypoint in your code (e.g., main.handler)"
  type        = string
}

variable "memory_size" {
  description = "Amount of memory in MB for the Lambda function"
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Timeout in seconds for the Lambda function"
  type        = number
  default     = 3
}

variable "architectures" {
  description = "Instruction set architecture (x86_64 or arm64)"
  type        = list(string)
  default     = ["x86_64"]
}

# Deployment Package - Option 1: Local source directory (auto-zipped)
variable "source_dir" {
  description = "Path to local source directory to be zipped and deployed"
  type        = string
  default     = null
}

# Deployment Package - Option 2: Pre-built ZIP file
variable "filename" {
  description = "Path to a pre-built deployment package ZIP file"
  type        = string
  default     = null
}

# Deployment Package - Option 3: S3 package
variable "s3_bucket" {
  description = "S3 bucket containing the deployment package"
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key of the deployment package"
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "S3 object version of the deployment package"
  type        = string
  default     = null
}

# IAM Role
variable "role_arn" {
  description = "ARN of an existing IAM role. If not provided, a role will be created."
  type        = string
  default     = null
}

variable "create_role" {
  description = "Whether to create an IAM role for the Lambda function"
  type        = bool
  default     = true
}

variable "policy_arns" {
  description = "List of IAM policy ARNs to attach to the Lambda role"
  type        = list(string)
  default     = []
}

variable "inline_policy" {
  description = "Inline IAM policy document (JSON) to attach to the Lambda role"
  type        = string
  default     = null
}

# Environment Variables
variable "environment_variables" {
  description = "Map of environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

# VPC Configuration
variable "vpc_config" {
  description = "VPC configuration for the Lambda function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

# Layers
variable "layers" {
  description = "List of Lambda layer ARNs to attach"
  type        = list(string)
  default     = []
}

# Logging
variable "logging" {
  description = "CloudWatch Logs configuration"
  type = object({
    retention_days = optional(number, 14)
    log_format     = optional(string, "Text")
  })
  default = {}
}

# Dead Letter Queue
variable "dead_letter_config" {
  description = "Dead letter queue configuration (SQS or SNS ARN)"
  type = object({
    target_arn = string
  })
  default = null
}

# Concurrency
variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions for this function (-1 for unreserved)"
  type        = number
  default     = -1
}

variable "provisioned_concurrency" {
  description = "Provisioned concurrency configuration"
  type = object({
    qualifier                      = optional(string, "$LATEST")
    provisioned_concurrent_executions = number
  })
  default = null
}

# Tracing
variable "tracing_mode" {
  description = "X-Ray tracing mode (Active or PassThrough)"
  type        = string
  default     = null
}

# Ephemeral Storage
variable "ephemeral_storage_size" {
  description = "Ephemeral storage (/tmp) size in MB (512-10240)"
  type        = number
  default     = 512
}

# Function URL
variable "function_url" {
  description = "Lambda function URL configuration"
  type = object({
    authorization_type = optional(string, "NONE")
    cors = optional(object({
      allow_credentials = optional(bool, false)
      allow_headers     = optional(list(string), ["*"])
      allow_methods     = optional(list(string), ["*"])
      allow_origins     = optional(list(string), ["*"])
      expose_headers    = optional(list(string), [])
      max_age           = optional(number, 0)
    }))
  })
  default = null
}

# Triggers / Permissions
variable "allowed_triggers" {
  description = "Map of allowed triggers for creating Lambda permissions"
  type = map(object({
    service           = string
    source_arn        = optional(string)
    source_account    = optional(string)
    event_source_token = optional(string)
  }))
  default = {}
}

# Event Source Mappings
variable "event_source_mappings" {
  description = "Map of event source mappings (SQS, DynamoDB, Kinesis, etc.)"
  type = map(object({
    event_source_arn                   = string
    batch_size                         = optional(number)
    starting_position                  = optional(string)
    starting_position_timestamp        = optional(string)
    enabled                            = optional(bool, true)
    maximum_batching_window_in_seconds = optional(number)
    maximum_retry_attempts             = optional(number)
    maximum_record_age_in_seconds      = optional(number)
    bisect_batch_on_function_error     = optional(bool)
    parallelization_factor             = optional(number)
    filter_criteria = optional(object({
      filters = list(object({
        pattern = string
      }))
    }))
  }))
  default = {}
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

