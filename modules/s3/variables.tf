variable "bucket_name" {
  description = "Name of the S3 bucket. Must be globally unique."
  type        = string
}

variable "force_destroy" {
  description = "Allow destruction of non-empty bucket"
  type        = bool
  default     = false
}

variable "object_lock_enabled" {
  description = "Enable S3 Object Lock (requires versioning)"
  type        = bool
  default     = false
}

# Versioning
variable "versioning_enabled" {
  description = "Enable versioning for the bucket"
  type        = bool
  default     = false
}

variable "mfa_delete" {
  description = "Enable MFA delete for versioned bucket"
  type        = bool
  default     = false
}

# Encryption
variable "encryption" {
  description = "Server-side encryption configuration"
  type = object({
    sse_algorithm             = optional(string, "AES256")
    kms_key_id                = optional(string)
    bucket_key_enabled        = optional(bool, true)
  })
  default = {}
}

# Public Access Block
variable "block_public_access" {
  description = "S3 bucket public access block configuration"
  type = object({
    block_public_acls       = optional(bool, true)
    block_public_policy     = optional(bool, true)
    ignore_public_acls      = optional(bool, true)
    restrict_public_buckets = optional(bool, true)
  })
  default = {}
}

# Lifecycle Rules
variable "lifecycle_rules" {
  description = "List of lifecycle rules for the bucket"
  type = list(object({
    id      = string
    enabled = optional(bool, true)
    prefix  = optional(string)
    tags    = optional(map(string))
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    noncurrent_version_transitions = optional(list(object({
      noncurrent_days = number
      storage_class   = string
    })), [])
    expiration_days                    = optional(number)
    noncurrent_version_expiration_days = optional(number)
    abort_incomplete_multipart_upload_days = optional(number)
  }))
  default = []
}

# Logging
variable "logging" {
  description = "Access logging configuration"
  type = object({
    target_bucket = string
    target_prefix = optional(string, "")
  })
  default = null
}

# CORS
variable "cors_rules" {
  description = "CORS rules for the bucket"
  type = list(object({
    allowed_headers = optional(list(string), ["*"])
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number, 3600)
  }))
  default = []
}

# Website Configuration
variable "website" {
  description = "Static website hosting configuration"
  type = object({
    index_document           = optional(string, "index.html")
    error_document           = optional(string)
    redirect_all_requests_to = optional(object({
      host_name = string
      protocol  = optional(string, "https")
    }))
    routing_rules = optional(string)
  })
  default = null
}

# Replication
variable "replication" {
  description = "Cross-region replication configuration"
  type = object({
    role = string
    rules = list(object({
      id       = string
      status   = optional(string, "Enabled")
      priority = optional(number)
      prefix   = optional(string)
      destination = object({
        bucket        = string
        storage_class = optional(string)
        account_id    = optional(string)
        access_control_translation = optional(object({
          owner = string
        }))
        encryption_configuration = optional(object({
          replica_kms_key_id = string
        }))
      })
      source_selection_criteria = optional(object({
        replica_modifications = optional(object({
          status = string
        }))
        sse_kms_encrypted_objects = optional(object({
          status = string
        }))
      }))
      delete_marker_replication = optional(bool, false)
    }))
  })
  default = null
}

# Object Lock Configuration
variable "object_lock_configuration" {
  description = "Object lock configuration (requires object_lock_enabled = true)"
  type = object({
    mode  = string # GOVERNANCE or COMPLIANCE
    days  = optional(number)
    years = optional(number)
  })
  default = null
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

