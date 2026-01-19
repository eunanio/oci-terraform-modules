# SQS Module

Creates an AWS SQS (Simple Queue Service) queue with comprehensive configuration including standard and FIFO queues, dead letter queues, encryption, and queue policies.

## Features

- Standard and FIFO queues
- Dead letter queue configuration
- Message retention and visibility timeout
- Encryption (SSE-SQS or SSE-KMS)
- Queue policies
- Redrive policy
- Content-based deduplication (FIFO)
- High throughput mode (FIFO)

## Usage with Nori

```bash
nori release create my-queue ghcr.io/eunanio/oci-terraform-modules/sqs:v1.0.0 -f values.yaml
```

## Usage with OpenTofu

```hcl
module "sqs" {
  source = "oci://ghcr.io/eunanio/oci-terraform-modules/sqs?tag=v1.0.0"

  name = "my-queue"

  message_retention_seconds  = 86400
  visibility_timeout_seconds = 60

  create_dlq        = true
  max_receive_count = 3

  tags = {
    Environment = "production"
  }
}
```

## Values File Example

```yaml
# values.yaml

# === Queue Name ===
name: my-application-queue

# === Queue Type ===
fifo_queue: false  # Set to true for FIFO queue

# === FIFO Queue Settings (only applies if fifo_queue: true) ===
# content_based_deduplication: true
# deduplication_scope: messageGroup  # or queue
# fifo_throughput_limit: perMessageGroupId  # or perQueue (for high throughput)

# === Message Settings ===
delay_seconds: 0               # Delay before messages become available (0-900)
max_message_size: 262144       # Maximum message size in bytes (1024-262144)
message_retention_seconds: 345600  # 4 days (60-1209600, max 14 days)
receive_wait_time_seconds: 10  # Long polling (0-20)
visibility_timeout_seconds: 60 # Time message is invisible after receive (0-43200)

# === Encryption ===
# Option 1: SQS managed encryption (default)
sqs_managed_sse_enabled: true

# Option 2: KMS encryption
# sqs_managed_sse_enabled: false  # Disable SQS managed SSE when using KMS
# kms_master_key_id: arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012
# kms_data_key_reuse_period_seconds: 300

# === Dead Letter Queue ===
create_dlq: true
# dlq_name: my-custom-dlq-name  # Optional, defaults to {name}-dlq
dlq_message_retention_seconds: 1209600  # 14 days
max_receive_count: 3  # Messages move to DLQ after this many receives

# Or use an existing DLQ:
# create_dlq: false
# existing_dlq_arn: arn:aws:sqs:us-east-1:123456789012:existing-dlq

# === Queue Policy ===
# Option 1: Raw policy document
# policy: |
#   {
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Effect": "Allow",
#         "Principal": {"Service": "sns.amazonaws.com"},
#         "Action": "sqs:SendMessage",
#         "Resource": "*",
#         "Condition": {
#           "ArnEquals": {
#             "aws:SourceArn": "arn:aws:sns:us-east-1:123456789012:my-topic"
#           }
#         }
#       }
#     ]
#   }

# Option 2: Policy statements (will be converted to policy document)
create_policy: true
policy_statements:
  # Allow SNS to send messages
  - sid: AllowSNS
    effect: Allow
    principals:
      type: Service
      identifiers:
        - sns.amazonaws.com
    actions:
      - sqs:SendMessage
    conditions:
      - test: ArnEquals
        variable: aws:SourceArn
        values:
          - arn:aws:sns:us-east-1:123456789012:my-topic

  # Allow Lambda to receive messages
  - sid: AllowLambda
    effect: Allow
    principals:
      type: AWS
      identifiers:
        - arn:aws:iam::123456789012:role/my-lambda-role
    actions:
      - sqs:ReceiveMessage
      - sqs:DeleteMessage
      - sqs:GetQueueAttributes

  # Allow EventBridge to send messages
  - sid: AllowEventBridge
    effect: Allow
    principals:
      type: Service
      identifiers:
        - events.amazonaws.com
    actions:
      - sqs:SendMessage
    conditions:
      - test: ArnEquals
        variable: aws:SourceArn
        values:
          - arn:aws:events:us-east-1:123456789012:rule/my-rule

# === Tags ===
tags:
  Environment: production
  Application: my-app
  Team: platform
  CostCenter: "12345"
```

## FIFO Queue Example

```yaml
# fifo-queue-values.yaml

name: my-fifo-queue  # .fifo suffix added automatically
fifo_queue: true

# FIFO-specific settings
content_based_deduplication: true  # Auto-deduplicate based on message content
deduplication_scope: messageGroup  # Deduplicate per message group
fifo_throughput_limit: perMessageGroupId  # High throughput mode

message_retention_seconds: 86400
visibility_timeout_seconds: 30

create_dlq: true
max_receive_count: 5

sqs_managed_sse_enabled: true

tags:
  QueueType: FIFO
  Environment: production
```

## Standard Queue with SNS Integration

```yaml
# sns-integration-values.yaml

name: orders-queue

message_retention_seconds: 604800  # 7 days
visibility_timeout_seconds: 120
receive_wait_time_seconds: 20  # Long polling

create_dlq: true
dlq_message_retention_seconds: 1209600  # 14 days
max_receive_count: 3

create_policy: true
policy_statements:
  - sid: AllowSNSPublish
    principals:
      type: Service
      identifiers:
        - sns.amazonaws.com
    actions:
      - sqs:SendMessage
    conditions:
      - test: ArnEquals
        variable: aws:SourceArn
        values:
          - arn:aws:sns:us-east-1:123456789012:orders-topic

tags:
  Service: orders
```

## Lambda Integration Example

```yaml
# lambda-integration-values.yaml

name: processing-queue

visibility_timeout_seconds: 900  # Should be >= Lambda timeout
receive_wait_time_seconds: 20

create_dlq: true
max_receive_count: 3

# KMS encryption for sensitive data
kms_master_key_id: alias/my-key
kms_data_key_reuse_period_seconds: 300

create_policy: true
policy_statements:
  - sid: AllowLambdaAccess
    principals:
      type: AWS
      identifiers:
        - arn:aws:iam::123456789012:role/lambda-execution-role
    actions:
      - sqs:ReceiveMessage
      - sqs:DeleteMessage
      - sqs:GetQueueAttributes
      - sqs:ChangeMessageVisibility

tags:
  Consumer: lambda
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the SQS queue | `string` | n/a | yes |
| fifo_queue | Whether this is a FIFO queue | `bool` | `false` | no |
| content_based_deduplication | Enable content-based deduplication | `bool` | `false` | no |
| deduplication_scope | Deduplication scope for FIFO | `string` | `null` | no |
| fifo_throughput_limit | FIFO throughput limit | `string` | `null` | no |
| delay_seconds | Delay before messages available | `number` | `0` | no |
| max_message_size | Maximum message size in bytes | `number` | `262144` | no |
| message_retention_seconds | Message retention period | `number` | `345600` | no |
| receive_wait_time_seconds | Long polling wait time | `number` | `0` | no |
| visibility_timeout_seconds | Visibility timeout | `number` | `30` | no |
| sqs_managed_sse_enabled | Enable SQS managed SSE | `bool` | `true` | no |
| kms_master_key_id | KMS key ID for encryption | `string` | `null` | no |
| create_dlq | Create a dead letter queue | `bool` | `false` | no |
| dlq_name | Name of the DLQ | `string` | `null` | no |
| dlq_message_retention_seconds | DLQ message retention | `number` | `1209600` | no |
| max_receive_count | Receives before moving to DLQ | `number` | `3` | no |
| existing_dlq_arn | ARN of existing DLQ | `string` | `null` | no |
| policy | JSON policy document | `string` | `null` | no |
| create_policy | Create queue policy | `bool` | `false` | no |
| policy_statements | List of policy statements | `list(object)` | `[]` | no |
| tags | Tags to apply | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| queue_id | URL of the SQS queue |
| queue_arn | ARN of the SQS queue |
| queue_url | URL of the SQS queue |
| queue_name | Name of the SQS queue |
| dlq_id | URL of the dead letter queue |
| dlq_arn | ARN of the dead letter queue |
| dlq_url | URL of the dead letter queue |
| dlq_name | Name of the dead letter queue |

