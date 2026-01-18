# S3 Bucket
resource "aws_s3_bucket" "this" {
  bucket              = var.bucket_name
  force_destroy       = var.force_destroy
  object_lock_enabled = var.object_lock_enabled

  tags = var.tags
}

# Versioning
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status     = var.versioning_enabled ? "Enabled" : "Suspended"
    mfa_delete = var.mfa_delete ? "Enabled" : "Disabled"
  }
}

# Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption.sse_algorithm
      kms_master_key_id = var.encryption.kms_key_id
    }
    bucket_key_enabled = var.encryption.bucket_key_enabled
  }
}

# Public Access Block
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.block_public_access.block_public_acls
  block_public_policy     = var.block_public_access.block_public_policy
  ignore_public_acls      = var.block_public_access.ignore_public_acls
  restrict_public_buckets = var.block_public_access.restrict_public_buckets
}

# Lifecycle Rules
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      dynamic "filter" {
        for_each = rule.value.prefix != null || rule.value.tags != null ? [1] : []
        content {
          and {
            prefix = rule.value.prefix
            tags   = rule.value.tags
          }
        }
      }

      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transitions
        content {
          noncurrent_days = noncurrent_version_transition.value.noncurrent_days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? [1] : []
        content {
          days = rule.value.expiration_days
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration_days != null ? [1] : []
        content {
          noncurrent_days = rule.value.noncurrent_version_expiration_days
        }
      }

      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload_days != null ? [1] : []
        content {
          days_after_initiation = rule.value.abort_incomplete_multipart_upload_days
        }
      }
    }
  }
}

# Access Logging
resource "aws_s3_bucket_logging" "this" {
  count  = var.logging != null ? 1 : 0
  bucket = aws_s3_bucket.this.id

  target_bucket = var.logging.target_bucket
  target_prefix = var.logging.target_prefix
}

# CORS Configuration
resource "aws_s3_bucket_cors_configuration" "this" {
  count  = length(var.cors_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

# Website Configuration
resource "aws_s3_bucket_website_configuration" "this" {
  count  = var.website != null ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "index_document" {
    for_each = var.website.redirect_all_requests_to == null ? [1] : []
    content {
      suffix = var.website.index_document
    }
  }

  dynamic "error_document" {
    for_each = var.website.error_document != null && var.website.redirect_all_requests_to == null ? [1] : []
    content {
      key = var.website.error_document
    }
  }

  dynamic "redirect_all_requests_to" {
    for_each = var.website.redirect_all_requests_to != null ? [var.website.redirect_all_requests_to] : []
    content {
      host_name = redirect_all_requests_to.value.host_name
      protocol  = redirect_all_requests_to.value.protocol
    }
  }

  routing_rules = var.website.routing_rules
}

# Replication Configuration
resource "aws_s3_bucket_replication_configuration" "this" {
  count  = var.replication != null ? 1 : 0
  bucket = aws_s3_bucket.this.id
  role   = var.replication.role

  dynamic "rule" {
    for_each = var.replication.rules
    content {
      id       = rule.value.id
      status   = rule.value.status
      priority = rule.value.priority

      dynamic "filter" {
        for_each = rule.value.prefix != null ? [1] : []
        content {
          prefix = rule.value.prefix
        }
      }

      destination {
        bucket        = rule.value.destination.bucket
        storage_class = rule.value.destination.storage_class
        account       = rule.value.destination.account_id

        dynamic "access_control_translation" {
          for_each = rule.value.destination.access_control_translation != null ? [rule.value.destination.access_control_translation] : []
          content {
            owner = access_control_translation.value.owner
          }
        }

        dynamic "encryption_configuration" {
          for_each = rule.value.destination.encryption_configuration != null ? [rule.value.destination.encryption_configuration] : []
          content {
            replica_kms_key_id = encryption_configuration.value.replica_kms_key_id
          }
        }
      }

      dynamic "source_selection_criteria" {
        for_each = rule.value.source_selection_criteria != null ? [rule.value.source_selection_criteria] : []
        content {
          dynamic "replica_modifications" {
            for_each = source_selection_criteria.value.replica_modifications != null ? [source_selection_criteria.value.replica_modifications] : []
            content {
              status = replica_modifications.value.status
            }
          }

          dynamic "sse_kms_encrypted_objects" {
            for_each = source_selection_criteria.value.sse_kms_encrypted_objects != null ? [source_selection_criteria.value.sse_kms_encrypted_objects] : []
            content {
              status = sse_kms_encrypted_objects.value.status
            }
          }
        }
      }

      delete_marker_replication {
        status = rule.value.delete_marker_replication ? "Enabled" : "Disabled"
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

# Object Lock Configuration
resource "aws_s3_bucket_object_lock_configuration" "this" {
  count  = var.object_lock_enabled && var.object_lock_configuration != null ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    default_retention {
      mode  = var.object_lock_configuration.mode
      days  = var.object_lock_configuration.days
      years = var.object_lock_configuration.years
    }
  }
}

