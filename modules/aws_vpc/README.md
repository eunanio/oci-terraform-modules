# VPC Module

Creates an AWS VPC with comprehensive configuration including Internet Gateway, NAT Gateways, VPC Flow Logs, DHCP options, and VPC Endpoints.

## Features

- VPC with configurable CIDR and DNS settings
- Secondary CIDR blocks
- Internet Gateway
- NAT Gateways (single or per-AZ)
- VPC Flow Logs (CloudWatch or S3)
- DHCP options sets
- Gateway endpoints (S3, DynamoDB)
- Interface endpoints with security groups
- Default security group and NACL management

## Usage with Nori

```bash
nori release create my-vpc ghcr.io/eunanio/oci-terraform-modules/vpc:v1.0.0 -f values.yaml
```

## Usage with OpenTofu/Terraform

```hcl
module "vpc" {
  source = "oci://ghcr.io/eunanio/oci-terraform-modules/vpc?tag=v1.0.0"

  name       = "my-vpc"
  cidr_block = "10.0.0.0/16"

  create_igw = true

  nat_gateway_config = {
    enabled    = true
    single_nat = false
    subnet_ids = ["subnet-public-1", "subnet-public-2"]
  }

  flow_logs = {
    enabled      = true
    traffic_type = "ALL"
  }

  tags = {
    Environment = "production"
  }
}
```

## Values File Example

```yaml
# values.yaml

# === VPC Configuration ===
name: production-vpc
cidr_block: "10.0.0.0/16"
instance_tenancy: default

enable_dns_support: true
enable_dns_hostnames: true
enable_network_address_usage_metrics: false

# === Secondary CIDR Blocks ===
secondary_cidr_blocks:
  - "100.64.0.0/16"  # Additional CIDR for pods (EKS)

# === Internet Gateway ===
create_igw: true

# === NAT Gateway ===
nat_gateway_config:
  enabled: true
  single_nat: false  # Set to true for cost savings (single NAT for all AZs)
  subnet_ids:
    - subnet-public-1a  # Public subnet IDs where NATs will be created
    - subnet-public-1b
    - subnet-public-1c
  # allocation_ids:     # Optional: Use existing EIPs
  #   - eipalloc-abc123
  #   - eipalloc-def456

# === VPC Flow Logs ===
flow_logs:
  enabled: true
  traffic_type: ALL  # ACCEPT, REJECT, or ALL
  destination_type: cloud-watch-logs  # or s3
  
  # CloudWatch Logs settings
  create_log_group: true
  log_retention_days: 30
  create_iam_role: true
  
  # S3 settings (when destination_type: s3)
  # log_destination: arn:aws:s3:::my-flow-logs-bucket/vpc-flow-logs/
  
  # Custom log format (optional)
  # log_format: "${version} ${account-id} ${interface-id} ${srcaddr} ${dstaddr} ${srcport} ${dstport} ${protocol} ${packets} ${bytes} ${start} ${end} ${action} ${log-status}"
  
  max_aggregation_interval: 60  # 60 or 600 seconds

# === DHCP Options ===
dhcp_options:
  domain_name: ec2.internal
  domain_name_servers:
    - AmazonProvidedDNS
  # ntp_servers:
  #   - 169.254.169.123
  # netbios_name_servers: []
  # netbios_node_type: 2

# === Gateway VPC Endpoints ===
gateway_endpoints:
  s3:
    service_name: com.amazonaws.us-east-1.s3
    route_table_ids:
      - rtb-private-1a
      - rtb-private-1b
    # policy: |
    #   {
    #     "Version": "2012-10-17",
    #     "Statement": [...]
    #   }
  
  dynamodb:
    service_name: com.amazonaws.us-east-1.dynamodb
    route_table_ids:
      - rtb-private-1a
      - rtb-private-1b

# === Interface VPC Endpoints ===
create_endpoint_security_group: true
endpoint_security_group_rules:
  ingress_cidr_blocks:
    - "10.0.0.0/16"
  # ingress_rules:
  #   - from_port: 443
  #     to_port: 443
  #     protocol: tcp
  #     cidr_blocks: ["10.0.0.0/16"]
  #     description: HTTPS from VPC

interface_endpoints:
  ecr_api:
    service_name: com.amazonaws.us-east-1.ecr.api
    subnet_ids:
      - subnet-private-1a
      - subnet-private-1b
    private_dns_enabled: true
  
  ecr_dkr:
    service_name: com.amazonaws.us-east-1.ecr.dkr
    subnet_ids:
      - subnet-private-1a
      - subnet-private-1b
    private_dns_enabled: true
  
  logs:
    service_name: com.amazonaws.us-east-1.logs
    subnet_ids:
      - subnet-private-1a
      - subnet-private-1b
    private_dns_enabled: true
  
  ssm:
    service_name: com.amazonaws.us-east-1.ssm
    subnet_ids:
      - subnet-private-1a
      - subnet-private-1b
    private_dns_enabled: true
  
  ssmmessages:
    service_name: com.amazonaws.us-east-1.ssmmessages
    subnet_ids:
      - subnet-private-1a
      - subnet-private-1b
    private_dns_enabled: true
  
  ec2messages:
    service_name: com.amazonaws.us-east-1.ec2messages
    subnet_ids:
      - subnet-private-1a
      - subnet-private-1b
    private_dns_enabled: true
  
  secretsmanager:
    service_name: com.amazonaws.us-east-1.secretsmanager
    subnet_ids:
      - subnet-private-1a
      - subnet-private-1b
    private_dns_enabled: true
  
  sts:
    service_name: com.amazonaws.us-east-1.sts
    subnet_ids:
      - subnet-private-1a
      - subnet-private-1b
    private_dns_enabled: true

# === Default Security Group ===
manage_default_security_group: true
default_security_group_ingress: []  # Deny all ingress
default_security_group_egress: []   # Deny all egress

# === Default Network ACL ===
manage_default_network_acl: true
default_network_acl_ingress:
  - rule_no: 100
    action: allow
    from_port: 0
    to_port: 0
    protocol: "-1"
    cidr_block: "0.0.0.0/0"

default_network_acl_egress:
  - rule_no: 100
    action: allow
    from_port: 0
    to_port: 0
    protocol: "-1"
    cidr_block: "0.0.0.0/0"

# === Tags ===
tags:
  Environment: production
  Team: platform
  CostCenter: "12345"

vpc_tags:
  kubernetes.io/cluster/my-cluster: shared

igw_tags: {}

nat_gateway_tags:
  Backup: "false"
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name for the VPC | `string` | n/a | yes |
| cidr_block | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| instance_tenancy | Instance tenancy | `string` | `"default"` | no |
| enable_dns_support | Enable DNS support | `bool` | `true` | no |
| enable_dns_hostnames | Enable DNS hostnames | `bool` | `true` | no |
| secondary_cidr_blocks | Secondary CIDR blocks | `list(string)` | `[]` | no |
| create_igw | Create Internet Gateway | `bool` | `true` | no |
| nat_gateway_config | NAT Gateway configuration | `object` | `{}` | no |
| flow_logs | VPC Flow Logs configuration | `object` | `{}` | no |
| dhcp_options | DHCP options configuration | `object` | `null` | no |
| gateway_endpoints | Gateway VPC endpoints | `map(object)` | `{}` | no |
| interface_endpoints | Interface VPC endpoints | `map(object)` | `{}` | no |
| create_endpoint_security_group | Create endpoint security group | `bool` | `false` | no |
| manage_default_security_group | Manage default security group | `bool` | `false` | no |
| manage_default_network_acl | Manage default network ACL | `bool` | `false` | no |
| tags | Tags to apply | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_arn | ARN of the VPC |
| vpc_cidr_block | CIDR block of the VPC |
| vpc_main_route_table_id | ID of the main route table |
| vpc_default_security_group_id | ID of the default security group |
| vpc_default_network_acl_id | ID of the default network ACL |
| secondary_cidr_blocks | List of secondary CIDR blocks |
| igw_id | ID of the Internet Gateway |
| igw_arn | ARN of the Internet Gateway |
| nat_gateway_ids | List of NAT Gateway IDs |
| nat_gateway_public_ips | List of NAT Gateway public IPs |
| nat_eip_ids | List of NAT EIP IDs |
| dhcp_options_id | ID of the DHCP options set |
| flow_log_id | ID of the VPC Flow Log |
| gateway_endpoint_ids | Map of gateway endpoint IDs |
| interface_endpoint_ids | Map of interface endpoint IDs |
| endpoint_security_group_id | ID of the endpoint security group |

