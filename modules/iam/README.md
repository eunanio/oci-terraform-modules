# IAM Module

Comprehensive AWS IAM management for roles, users, groups, policies, instance profiles, and OIDC providers.

## Features

- IAM roles with customizable assume role policies
- IAM users with optional console and programmatic access
- IAM groups with policy attachments
- Custom IAM policies
- Instance profiles for EC2
- OIDC providers for EKS/GitHub Actions
- Account alias and password policy management

## Usage with Nori

```bash
nori release create my-iam ghcr.io/eunanio/oci-terraform-modules/iam:v1.0.0 -f values.yaml
```

## Usage with OpenTofu

```hcl
module "iam" {
  source = "oci://ghcr.io/eunanio/oci-terraform-modules/iam?tag=v1.0.0"

  roles = {
    ec2-instance-role = {
      description = "Role for EC2 instances"
      assume_role_principals = {
        services = ["ec2.amazonaws.com"]
      }
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ]
      create_instance_profile = true
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Values File Example

```yaml
# values.yaml

# === IAM Roles ===
roles:
  # EC2 Instance Role with instance profile
  ec2-app-role:
    description: Role for application EC2 instances
    path: /application/
    max_session_duration: 7200
    assume_role_principals:
      services:
        - ec2.amazonaws.com
    managed_policy_arns:
      - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
      - arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
    inline_policies:
      s3-access: |
        {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Action": ["s3:GetObject", "s3:ListBucket"],
              "Resource": ["arn:aws:s3:::my-bucket", "arn:aws:s3:::my-bucket/*"]
            }
          ]
        }
    create_instance_profile: true
    tags:
      Application: my-app

  # Lambda execution role
  lambda-execution-role:
    description: Execution role for Lambda functions
    assume_role_principals:
      services:
        - lambda.amazonaws.com
    managed_policy_arns:
      - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
      - arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess

  # Cross-account assume role
  cross-account-role:
    description: Role for cross-account access
    assume_role_principals:
      aws:
        - arn:aws:iam::123456789012:root
    assume_role_conditions:
      - test: StringEquals
        variable: sts:ExternalId
        values:
          - my-external-id
    managed_policy_arns:
      - arn:aws:iam::aws:policy/ReadOnlyAccess

  # EKS service account role (IRSA)
  eks-pod-role:
    description: Role for EKS pods via IRSA
    assume_role_principals:
      federated:
        - arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE
    assume_role_conditions:
      - test: StringEquals
        variable: oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE:sub
        values:
          - system:serviceaccount:default:my-service-account
    managed_policy_arns:
      - arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# === IAM Users ===
users:
  # Service account user with programmatic access only
  ci-deploy-user:
    path: /service-accounts/
    create_access_key: true
    managed_policy_arns:
      - arn:aws:iam::aws:policy/PowerUserAccess
    tags:
      Purpose: CI/CD deployment

  # Admin user with console access
  admin-user:
    path: /admins/
    create_login_profile: true
    password_reset_required: true
    groups:
      - administrators
    tags:
      Department: Engineering

  # Developer user
  developer-user:
    path: /developers/
    create_login_profile: true
    create_access_key: true
    groups:
      - developers
    tags:
      Department: Engineering

# === IAM Groups ===
groups:
  administrators:
    path: /groups/
    managed_policy_arns:
      - arn:aws:iam::aws:policy/AdministratorAccess

  developers:
    path: /groups/
    managed_policy_arns:
      - arn:aws:iam::aws:policy/PowerUserAccess
      - arn:aws:iam::aws:policy/IAMUserChangePassword
    inline_policies:
      deny-iam-changes: |
        {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Deny",
              "Action": [
                "iam:CreateUser",
                "iam:DeleteUser",
                "iam:CreateRole",
                "iam:DeleteRole"
              ],
              "Resource": "*"
            }
          ]
        }

  readonly:
    path: /groups/
    managed_policy_arns:
      - arn:aws:iam::aws:policy/ReadOnlyAccess

# === IAM Policies ===
policies:
  custom-s3-policy:
    description: Custom S3 access policy
    path: /custom/
    policy: |
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Action": [
              "s3:GetObject",
              "s3:PutObject",
              "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::my-app-bucket/*"
          }
        ]
      }
    tags:
      Application: my-app

  secrets-manager-policy:
    description: Secrets Manager access policy
    policy: |
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Action": [
              "secretsmanager:GetSecretValue",
              "secretsmanager:DescribeSecret"
            ],
            "Resource": "arn:aws:secretsmanager:*:*:secret:my-app/*"
          }
        ]
      }

# === OIDC Providers ===
oidc_providers:
  github-actions:
    url: https://token.actions.githubusercontent.com
    client_id_list:
      - sts.amazonaws.com
    thumbprint_list:
      - 6938fd4d98bab03faadb97b34396831e3780aea1
    tags:
      Purpose: GitHub Actions OIDC

# === Account Settings ===
account_alias: my-company-production

account_password_policy:
  minimum_password_length: 14
  require_lowercase_characters: true
  require_uppercase_characters: true
  require_numbers: true
  require_symbols: true
  allow_users_to_change_password: true
  max_password_age: 90
  password_reuse_prevention: 24
  hard_expiry: false

# === Tags ===
tags:
  Environment: production
  ManagedBy: terraform
  Team: platform
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| roles | Map of IAM roles to create | `map(object)` | `{}` | no |
| users | Map of IAM users to create | `map(object)` | `{}` | no |
| groups | Map of IAM groups to create | `map(object)` | `{}` | no |
| policies | Map of IAM policies to create | `map(object)` | `{}` | no |
| oidc_providers | Map of OIDC providers to create | `map(object)` | `{}` | no |
| account_alias | AWS account alias | `string` | `null` | no |
| account_password_policy | Account password policy settings | `object` | `null` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| roles | Map of IAM role attributes |
| role_arns | Map of IAM role names to ARNs |
| instance_profiles | Map of IAM instance profile attributes |
| instance_profile_arns | Map of IAM instance profile names to ARNs |
| users | Map of IAM user attributes |
| user_arns | Map of IAM user names to ARNs |
| user_login_profile_passwords | Map of user login profile encrypted passwords |
| access_keys | Map of user access key details |
| groups | Map of IAM group attributes |
| group_arns | Map of IAM group names to ARNs |
| policies | Map of IAM policy attributes |
| policy_arns | Map of IAM policy names to ARNs |
| oidc_providers | Map of OIDC provider attributes |
| oidc_provider_arns | Map of OIDC provider names to ARNs |

