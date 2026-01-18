# oci-terraform-modules

A catalog of reusable Terraform modules distributed via OCI registries. These modules are designed to work seamlessly with [Nori](https://github.com/eunanio/nori) and OpenTofu

## Available Modules

| Module | Description | Documentation |
|--------|-------------|---------------|
| **lambda** | AWS Lambda function with flexible deployment options, IAM role management, VPC support, and comprehensive configuration | [View README](modules/lambda/README.md) |
| **s3** | S3 bucket with versioning, encryption, lifecycle rules, CORS, website hosting, replication, and object lock | [View README](modules/s3/README.md) |
| **route53** | Route53 hosted zones and DNS records with routing policies, health checks, and DNSSEC | [View README](modules/route53/README.md) |

## Usage

### With Nori

```bash
nori release create my-release ghcr.io/your-org/<module>:v1.0.0 -f values.yaml
```

### With OpenTofu/Terraform

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
4. Deploy using Nori or reference directly in your Terraform/OpenTofu configuration



