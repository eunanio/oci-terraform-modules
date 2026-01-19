# EKS Module

Creates an AWS EKS (Elastic Kubernetes Service) cluster with comprehensive configuration including managed node groups, Fargate profiles, add-ons, and IRSA (IAM Roles for Service Accounts).

## Features

- EKS cluster with configurable Kubernetes version
- Managed node groups (on-demand and spot)
- Fargate profiles for serverless Kubernetes
- Cluster add-ons (CoreDNS, kube-proxy, VPC CNI, EBS CSI)
- OIDC provider for IAM Roles for Service Accounts (IRSA)
- Public/private endpoint access configuration
- Cluster logging to CloudWatch
- Encryption with KMS
- Access entries for cluster authentication

## Usage with Nori

```bash
nori release create my-cluster ghcr.io/eunanio/oci-terraform-modules/eks:v1.0.0 -f values.yaml
```

## Usage with OpenTofu/Terraform

```hcl
module "eks" {
  source = "oci://ghcr.io/eunanio/oci-terraform-modules/eks?tag=v1.0.0"

  cluster_name    = "my-cluster"
  cluster_version = "1.29"

  subnet_ids = ["subnet-abc123", "subnet-def456", "subnet-ghi789"]

  node_groups = {
    general = {
      instance_types = ["t3.medium", "t3.large"]
      scaling_config = {
        desired_size = 3
        min_size     = 2
        max_size     = 10
      }
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

# === Cluster Configuration ===
cluster_name: my-production-cluster
cluster_version: "1.29"

# === IAM Role ===
create_cluster_role: true
# cluster_role_arn: arn:aws:iam::123456789012:role/my-existing-role

# === Network Configuration ===
subnet_ids:
  - subnet-abc123  # Private subnet AZ-a
  - subnet-def456  # Private subnet AZ-b
  - subnet-ghi789  # Private subnet AZ-c

security_group_ids:
  - sg-additional123

# API Server Endpoint Access
endpoint_private_access: true
endpoint_public_access: true
public_access_cidrs:
  - 10.0.0.0/8
  - 203.0.113.0/24  # Office IP

# === Encryption ===
encryption_config:
  provider_key_arn: arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012
  resources:
    - secrets

# === Logging ===
enabled_cluster_log_types:
  - api
  - audit
  - authenticator
  - controllerManager
  - scheduler

cluster_log_retention_days: 30

# === Access Configuration ===
authentication_mode: API_AND_CONFIG_MAP
bootstrap_cluster_creator_admin_permissions: true

# === Node Groups ===
node_groups:
  # General purpose nodes
  general:
    instance_types:
      - t3.large
      - t3.xlarge
    capacity_type: ON_DEMAND
    disk_size: 100
    ami_type: AL2_x86_64

    scaling_config:
      desired_size: 3
      min_size: 2
      max_size: 20

    update_config:
      max_unavailable: 1

    labels:
      role: general
      nodegroup: general

    create_node_role: true
    tags:
      NodeGroup: general

  # Spot instances for cost optimization
  spot:
    instance_types:
      - t3.large
      - t3.xlarge
      - t3a.large
      - t3a.xlarge
    capacity_type: SPOT
    disk_size: 100
    ami_type: AL2_x86_64

    scaling_config:
      desired_size: 2
      min_size: 0
      max_size: 50

    labels:
      role: spot
      nodegroup: spot

    taints:
      - key: spot
        value: "true"
        effect: NO_SCHEDULE

    tags:
      NodeGroup: spot

  # GPU nodes for ML workloads
  gpu:
    instance_types:
      - g4dn.xlarge
      - g4dn.2xlarge
    capacity_type: ON_DEMAND
    disk_size: 200
    ami_type: AL2_x86_64_GPU

    scaling_config:
      desired_size: 0
      min_size: 0
      max_size: 10

    labels:
      role: gpu
      nodegroup: gpu
      nvidia.com/gpu: "true"

    taints:
      - key: nvidia.com/gpu
        value: "true"
        effect: NO_SCHEDULE

    tags:
      NodeGroup: gpu

  # ARM64 nodes
  arm:
    instance_types:
      - t4g.large
      - t4g.xlarge
    capacity_type: ON_DEMAND
    disk_size: 100
    ami_type: AL2_ARM_64

    scaling_config:
      desired_size: 2
      min_size: 1
      max_size: 10

    labels:
      role: arm
      nodegroup: arm
      kubernetes.io/arch: arm64

    tags:
      NodeGroup: arm

# === Fargate Profiles ===
fargate_profiles:
  # Kube-system namespace on Fargate
  kube-system:
    subnet_ids:
      - subnet-abc123
      - subnet-def456
    selectors:
      - namespace: kube-system
        labels:
          k8s-app: kube-dns
    create_pod_execution_role: true

  # Application namespace on Fargate
  serverless-apps:
    subnet_ids:
      - subnet-abc123
      - subnet-def456
      - subnet-ghi789
    selectors:
      - namespace: serverless
      - namespace: batch-jobs
        labels:
          compute: fargate

# === Add-ons ===
cluster_addons:
  coredns:
    addon_version: v1.10.1-eksbuild.6
    resolve_conflicts_on_create: OVERWRITE
    resolve_conflicts_on_update: PRESERVE

  kube-proxy:
    addon_version: v1.29.0-eksbuild.1
    resolve_conflicts_on_create: OVERWRITE

  vpc-cni:
    addon_version: v1.16.0-eksbuild.1
    resolve_conflicts_on_create: OVERWRITE
    configuration_values: |
      {
        "env": {
          "ENABLE_PREFIX_DELEGATION": "true",
          "WARM_PREFIX_TARGET": "1"
        }
      }

  aws-ebs-csi-driver:
    addon_version: v1.28.0-eksbuild.1
    service_account_role_arn: arn:aws:iam::123456789012:role/AmazonEKS_EBS_CSI_DriverRole

  amazon-cloudwatch-observability:
    addon_version: v1.3.0-eksbuild.1

# === IRSA ===
enable_irsa: true

# === Access Entries ===
access_entries:
  # Admin access for platform team
  platform-team:
    principal_arn: arn:aws:iam::123456789012:role/PlatformTeamRole
    type: STANDARD
    policy_associations:
      admin:
        policy_arn: arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy
        access_scope:
          type: cluster

  # Developer access (namespace-scoped)
  dev-team:
    principal_arn: arn:aws:iam::123456789012:role/DevTeamRole
    type: STANDARD
    policy_associations:
      edit:
        policy_arn: arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy
        access_scope:
          type: namespace
          namespaces:
            - development
            - staging

  # Read-only access
  readonly:
    principal_arn: arn:aws:iam::123456789012:role/ReadOnlyRole
    type: STANDARD
    policy_associations:
      view:
        policy_arn: arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy
        access_scope:
          type: cluster

# === Tags ===
tags:
  Environment: production
  Application: kubernetes
  Team: platform
  CostCenter: "12345"
```

## IRSA (IAM Roles for Service Accounts) Example

After creating the cluster, you can create IAM roles for Kubernetes service accounts:

```hcl
# Create IAM role for a service account
resource "aws_iam_role" "s3_access" {
  name = "eks-s3-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider_url}:sub" = "system:serviceaccount:default:my-service-account"
            "${module.eks.oidc_provider_url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| subnet_ids | Subnet IDs for the cluster | `list(string)` | n/a | yes |
| cluster_version | Kubernetes version | `string` | `null` | no |
| create_cluster_role | Create cluster IAM role | `bool` | `true` | no |
| cluster_role_arn | ARN of existing cluster role | `string` | `null` | no |
| security_group_ids | Additional security group IDs | `list(string)` | `[]` | no |
| endpoint_private_access | Enable private endpoint | `bool` | `true` | no |
| endpoint_public_access | Enable public endpoint | `bool` | `true` | no |
| public_access_cidrs | CIDRs for public endpoint | `list(string)` | `["0.0.0.0/0"]` | no |
| encryption_config | Secrets encryption config | `object` | `null` | no |
| enabled_cluster_log_types | Log types to enable | `list(string)` | all types | no |
| node_groups | Map of node groups | `map(object)` | `{}` | no |
| fargate_profiles | Map of Fargate profiles | `map(object)` | `{}` | no |
| cluster_addons | Map of add-ons | `map(object)` | `{}` | no |
| enable_irsa | Enable IRSA | `bool` | `true` | no |
| access_entries | Map of access entries | `map(object)` | `{}` | no |
| tags | Tags to apply | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | ID of the EKS cluster |
| cluster_arn | ARN of the EKS cluster |
| cluster_name | Name of the EKS cluster |
| cluster_version | Kubernetes version |
| cluster_status | Status of the cluster |
| cluster_endpoint | API server endpoint |
| cluster_certificate_authority_data | Certificate data |
| cluster_oidc_issuer_url | OIDC issuer URL |
| oidc_provider_arn | ARN of OIDC provider |
| oidc_provider_url | URL of OIDC provider |
| cluster_role_arn | ARN of cluster IAM role |
| cluster_security_group_id | Cluster security group ID |
| node_groups | Map of node group attributes |
| node_group_role_arns | Map of node group role ARNs |
| fargate_profiles | Map of Fargate profile attributes |
| fargate_role_arns | Map of Fargate role ARNs |
| cluster_addons | Map of add-on attributes |
| cloudwatch_log_group_name | Name of log group |

