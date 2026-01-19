# S3 Bucket Module

Creates an S3 bucket with comprehensive configuration options including versioning, encryption, lifecycle rules, CORS, website hosting, replication, and object lock.

## Usage with Nori

```bash
nori release create my-bucket ghcr.io/eunanio/oci-terraform-modules/s3:v1.0.0 -f values.yaml
```

## Usage with OpenTofu

```hcl
module "s3_bucket" {
  source = "oci://ghcr.io/eunanio/oci-terraform-modules/s3?tag=v1.0.0"

  bucket_name        = "my-application-bucket"
  versioning_enabled = true

  encryption = {
    sse_algorithm = "aws:kms"
    kms_key_id    = "alias/my-key"
  }

  tags = {
    Environment = "production"
  }
}
```

## Values File Example

```yaml
# values.yaml
bucket_name: my-application-bucket
force_destroy: false
versioning_enabled: true

encryption:
  sse_algorithm: aws:kms
  kms_key_id: alias/my-key
  bucket_key_enabled: true

block_public_access:
  block_public_acls: true
  block_public_policy: true
  ignore_public_acls: true
  restrict_public_buckets: true

lifecycle_rules:
  - id: archive-old-objects
    enabled: true
    prefix: logs/
    transitions:
      - days: 90
        storage_class: STANDARD_IA
      - days: 180
        storage_class: GLACIER
    expiration_days: 365
    abort_incomplete_multipart_upload_days: 7

  - id: cleanup-temp
    enabled: true
    prefix: temp/
    expiration_days: 7

logging:
  target_bucket: my-logs-bucket
  target_prefix: s3-access-logs/

cors_rules:
  - allowed_headers:
      - "*"
    allowed_methods:
      - GET
      - HEAD
    allowed_origins:
      - https://example.com
      - https://www.example.com
    expose_headers:
      - ETag
    max_age_seconds: 3600

# Static website hosting
website:
  index_document: index.html
  error_document: error.html

# Cross-region replication (requires versioning)
# replication:
#   role: arn:aws:iam::123456789012:role/s3-replication-role
#   rules:
#     - id: replicate-all
#       status: Enabled
#       destination:
#         bucket: arn:aws:s3:::my-replica-bucket
#         storage_class: STANDARD

# Object lock (must be enabled at bucket creation)
# object_lock_enabled: true
# object_lock_configuration:
#   mode: GOVERNANCE
#   days: 30

tags:
  Environment: production
  Team: platform
  CostCenter: "12345"
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bucket_name | Name of the S3 bucket. Must be globally unique. | `string` | n/a | yes |
| force_destroy | Allow destruction of non-empty bucket | `bool` | `false` | no |
| object_lock_enabled | Enable S3 Object Lock (requires versioning) | `bool` | `false` | no |
| versioning_enabled | Enable versioning for the bucket | `bool` | `false` | no |
| mfa_delete | Enable MFA delete for versioned bucket | `bool` | `false` | no |
| encryption | Server-side encryption configuration | `object` | `{}` | no |
| block_public_access | S3 bucket public access block configuration | `object` | `{}` | no |
| lifecycle_rules | List of lifecycle rules for the bucket | `list(object)` | `[]` | no |
| logging | Access logging configuration | `object` | `null` | no |
| cors_rules | CORS rules for the bucket | `list(object)` | `[]` | no |
| website | Static website hosting configuration | `object` | `null` | no |
| replication | Cross-region replication configuration | `object` | `null` | no |
| object_lock_configuration | Object lock configuration | `object` | `null` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | The name of the bucket |
| bucket_arn | The ARN of the bucket |
| bucket_domain_name | The bucket domain name |
| bucket_regional_domain_name | The bucket region-specific domain name |
| hosted_zone_id | The Route 53 Hosted Zone ID for this bucket's region |
| website_endpoint | The website endpoint, if website hosting is configured |
| website_domain | The website domain, if website hosting is configured |

