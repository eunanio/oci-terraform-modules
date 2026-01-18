# Lambda Function Module

Creates an AWS Lambda function with flexible deployment options, IAM role management, VPC support, and comprehensive configuration options.

## Deployment Options

This module supports three methods for deploying Lambda function code:

1. **Local Source Directory** (`source_dir`) - Automatically zipped and deployed
2. **Pre-built ZIP File** (`filename`) - Use an existing ZIP archive
3. **S3 Package** (`s3_bucket` + `s3_key`) - Reference a package stored in S3

## Usage with Nori

```bash
nori release create my-function ghcr.io/your-org/lambda:v1.0.0 -f values.yaml
```

## Usage with OpenTofu/Terraform

```hcl
module "lambda_function" {
  source = "oci://ghcr.io/your-org/lambda?tag=v1.0.0"

  function_name = "my-api-handler"
  description   = "Handles API requests"
  runtime       = "python3.12"
  handler       = "main.handler"
  memory_size   = 256
  timeout       = 30

  source_dir = "./src"

  environment_variables = {
    LOG_LEVEL  = "INFO"
    TABLE_NAME = "my-dynamodb-table"
  }

  tags = {
    Environment = "production"
  }
}
```

## Values File Example

```yaml
# values.yaml
function_name: my-api-handler
description: Handles API requests
runtime: python3.12
handler: main.handler
memory_size: 256
timeout: 30
architectures:
  - x86_64

# === Deployment Package Options (choose one) ===

# Option 1: Local source directory (automatically zipped)
source_dir: ./src

# Option 2: Pre-built ZIP file
# filename: ./dist/function.zip

# Option 3: S3 deployment package
# s3_bucket: my-deployments-bucket
# s3_key: functions/my-api-handler/v1.0.0.zip
# s3_object_version: abc123

# === IAM Configuration ===

# Use an existing role (skip role creation)
# role_arn: arn:aws:iam::123456789012:role/my-existing-role
# create_role: false

# Or create a role with additional policies
create_role: true
policy_arns:
  - arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess
  - arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Inline policy for custom permissions
# inline_policy: |
#   {
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Effect": "Allow",
#         "Action": ["secretsmanager:GetSecretValue"],
#         "Resource": "arn:aws:secretsmanager:*:*:secret:my-secret-*"
#       }
#     ]
#   }

# === Environment Variables ===
environment_variables:
  LOG_LEVEL: INFO
  TABLE_NAME: my-dynamodb-table
  API_ENDPOINT: https://api.example.com

# === VPC Configuration ===
vpc_config:
  subnet_ids:
    - subnet-abc123
    - subnet-def456
  security_group_ids:
    - sg-xyz789

# === Lambda Layers ===
layers:
  - arn:aws:lambda:us-east-1:123456789012:layer:my-layer:1

# === Logging ===
logging:
  retention_days: 14
  log_format: JSON

# === Dead Letter Queue ===
dead_letter_config:
  target_arn: arn:aws:sqs:us-east-1:123456789012:my-dlq

# === Concurrency ===
reserved_concurrent_executions: 100

# Provisioned concurrency for consistent performance
# provisioned_concurrency:
#   qualifier: $LATEST
#   provisioned_concurrent_executions: 5

# === X-Ray Tracing ===
tracing_mode: Active

# === Ephemeral Storage ===
ephemeral_storage_size: 1024  # MB (512-10240)

# === Function URL ===
function_url:
  authorization_type: NONE
  cors:
    allow_credentials: false
    allow_headers:
      - "*"
    allow_methods:
      - GET
      - POST
    allow_origins:
      - https://example.com
    max_age: 86400

# === Triggers / Permissions ===
allowed_triggers:
  api_gateway:
    service: apigateway
    source_arn: arn:aws:execute-api:us-east-1:123456789012:abc123/*/*/*
  s3_bucket:
    service: s3
    source_arn: arn:aws:s3:::my-bucket
    source_account: "123456789012"

# === Event Source Mappings ===
event_source_mappings:
  sqs_queue:
    event_source_arn: arn:aws:sqs:us-east-1:123456789012:my-queue
    batch_size: 10
    enabled: true
    maximum_batching_window_in_seconds: 5
  
  dynamodb_stream:
    event_source_arn: arn:aws:dynamodb:us-east-1:123456789012:table/my-table/stream/2024-01-01T00:00:00.000
    batch_size: 100
    starting_position: LATEST
    maximum_retry_attempts: 3
    bisect_batch_on_function_error: true
    filter_criteria:
      filters:
        - pattern: '{"eventName": ["INSERT", "MODIFY"]}'

# === Tags ===
tags:
  Service: api
  Environment: production
  Team: platform
  CostCenter: "12345"
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| function_name | Name of the Lambda function | `string` | n/a | yes |
| runtime | Runtime for the Lambda function | `string` | n/a | yes |
| handler | Function entrypoint in your code | `string` | n/a | yes |
| description | Description of the Lambda function | `string` | `""` | no |
| memory_size | Amount of memory in MB | `number` | `128` | no |
| timeout | Timeout in seconds | `number` | `3` | no |
| architectures | Instruction set architecture | `list(string)` | `["x86_64"]` | no |
| source_dir | Path to local source directory to be zipped | `string` | `null` | no |
| filename | Path to a pre-built deployment package ZIP | `string` | `null` | no |
| s3_bucket | S3 bucket containing the deployment package | `string` | `null` | no |
| s3_key | S3 key of the deployment package | `string` | `null` | no |
| s3_object_version | S3 object version of the deployment package | `string` | `null` | no |
| role_arn | ARN of an existing IAM role | `string` | `null` | no |
| create_role | Whether to create an IAM role | `bool` | `true` | no |
| policy_arns | List of IAM policy ARNs to attach | `list(string)` | `[]` | no |
| inline_policy | Inline IAM policy document (JSON) | `string` | `null` | no |
| environment_variables | Map of environment variables | `map(string)` | `{}` | no |
| vpc_config | VPC configuration | `object` | `null` | no |
| layers | List of Lambda layer ARNs | `list(string)` | `[]` | no |
| logging | CloudWatch Logs configuration | `object` | `{}` | no |
| dead_letter_config | Dead letter queue configuration | `object` | `null` | no |
| reserved_concurrent_executions | Reserved concurrent executions | `number` | `-1` | no |
| provisioned_concurrency | Provisioned concurrency configuration | `object` | `null` | no |
| tracing_mode | X-Ray tracing mode | `string` | `null` | no |
| ephemeral_storage_size | Ephemeral storage size in MB | `number` | `512` | no |
| function_url | Lambda function URL configuration | `object` | `null` | no |
| allowed_triggers | Map of allowed triggers | `map(object)` | `{}` | no |
| event_source_mappings | Map of event source mappings | `map(object)` | `{}` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| function_name | Name of the Lambda function |
| function_arn | ARN of the Lambda function |
| invoke_arn | Invoke ARN (for API Gateway) |
| qualified_arn | Qualified ARN (includes version) |
| version | Latest published version |
| source_code_hash | Base64-encoded SHA256 hash of the deployment package |
| source_code_size | Size in bytes of the deployment package |
| role_arn | ARN of the IAM role |
| role_name | Name of the created IAM role |
| log_group_name | Name of the CloudWatch log group |
| log_group_arn | ARN of the CloudWatch log group |
| function_url | Lambda function URL (if configured) |
| function_url_id | Lambda function URL ID (if configured) |

