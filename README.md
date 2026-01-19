# oci-terraform-modules

A catalog of reusable Terraform module. These modules are designed to work seamlessly with [Nori](https://github.com/eunanio/nori) and OpenTofu

## Available Modules

| Module | Description | Documentation |
|--------|-------------|---------------|
| **lambda** | AWS Lambda function with flexible deployment options, IAM role management, VPC support, and comprehensive configuration | [View README](modules/lambda/README.md) |
| **s3** | S3 bucket with versioning, encryption, lifecycle rules, CORS, website hosting, replication, and object lock | [View README](modules/s3/README.md) |
| **route53** | Route53 hosted zones and DNS records with routing policies, health checks, and DNSSEC | [View README](modules/route53/README.md) |
| **iam** | IAM roles, users, groups, policies, instance profiles, and OIDC providers | [View README](modules/iam/README.md) |
| **ec2** | EC2 instances with EBS volumes, security groups, key pairs, and user data | [View README](modules/ec2/README.md) |
| **rds** | RDS database instances with multi-engine support, encryption, backups, and monitoring | [View README](modules/rds/README.md) |
| **ecs-fargate** | ECS Fargate services with task definitions, auto-scaling, and load balancer integration | [View README](modules/ecs-fargate/README.md) |
| **eks** | EKS clusters with managed node groups, Fargate profiles, add-ons, and IRSA support | [View README](modules/eks/README.md) |
| **sqs** | SQS queues (standard/FIFO) with dead letter queues and encryption | [View README](modules/sqs/README.md) |
| **vpc** | VPC with Internet Gateway, NAT Gateways, flow logs, and VPC endpoints | [View README](modules/vpc/README.md) |
| **subnet** | Subnets with route tables, NACLs, and subnet groups for databases | [View README](modules/subnet/README.md) |

## Usage

### With [Nori](https://github.com/eunanio/nori)

```bash
nori release create my-release ghcr.io/eunanio/oci-terraform-modules/<module>:v1.0.0 -f values.yaml
```

### With OpenTofu

```hcl
module "example" {
  source = "oci://ghcr.io/eunanio/oci-terraform-modules/s3?tag=v1.0.0"

  # Module-specific variables...
}
```

## Getting Started

1. Choose a module from the catalog above
2. Review the module's README for available inputs and outputs
3. Create a `values.yaml` file with your configuration
4. Deploy using Nori or reference directly in your OpenTofu configuration



