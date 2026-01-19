# Subnet Module

Creates AWS subnets with comprehensive configuration including route tables, Network ACLs, and subnet groups for databases.

## Features

- Public and private subnets
- Route tables with automatic IGW/NAT routing
- Custom routes (Transit Gateway, VPC Peering, etc.)
- Network ACLs
- DB subnet groups (RDS)
- ElastiCache subnet groups
- Redshift subnet groups

## Usage with Nori

```bash
nori release create my-subnets ghcr.io/eunanio/oci-terraform-modules/subnet:v1.0.0 -f values.yaml
```

## Usage with OpenTofu/Terraform

```hcl
module "subnets" {
  source = "oci://ghcr.io/eunanio/oci-terraform-modules/subnet?tag=v1.0.0"

  vpc_id      = module.vpc.vpc_id
  name_prefix = "my-app"

  internet_gateway_id   = module.vpc.igw_id
  single_nat_gateway_id = module.vpc.nat_gateway_ids[0]

  subnets = {
    public-1a = {
      cidr_block              = "10.0.1.0/24"
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = true
    }
    private-1a = {
      cidr_block        = "10.0.10.0/24"
      availability_zone = "us-east-1a"
    }
  }

  create_db_subnet_group       = true
  db_subnet_group_subnet_names = ["private-1a", "private-1b"]

  tags = {
    Environment = "production"
  }
}
```

## Values File Example

```yaml
# values.yaml

# === VPC Reference ===
vpc_id: vpc-abc123
name_prefix: production

# === Gateway References ===
internet_gateway_id: igw-abc123

# NAT Gateway - Option 1: Per-AZ NAT Gateways
nat_gateway_ids:
  us-east-1a: nat-abc123
  us-east-1b: nat-def456
  us-east-1c: nat-ghi789

# NAT Gateway - Option 2: Single NAT Gateway
# single_nat_gateway_id: nat-abc123

# === Subnets ===
subnets:
  # Public Subnets
  public-1a:
    cidr_block: "10.0.1.0/24"
    availability_zone: us-east-1a
    map_public_ip_on_launch: true
    create_route_table: true
    tags:
      Tier: public
      kubernetes.io/role/elb: "1"

  public-1b:
    cidr_block: "10.0.2.0/24"
    availability_zone: us-east-1b
    map_public_ip_on_launch: true
    create_route_table: true
    tags:
      Tier: public
      kubernetes.io/role/elb: "1"

  public-1c:
    cidr_block: "10.0.3.0/24"
    availability_zone: us-east-1c
    map_public_ip_on_launch: true
    create_route_table: true
    tags:
      Tier: public
      kubernetes.io/role/elb: "1"

  # Private Subnets (Application Tier)
  private-1a:
    cidr_block: "10.0.10.0/24"
    availability_zone: us-east-1a
    create_route_table: true
    tags:
      Tier: private
      kubernetes.io/role/internal-elb: "1"

  private-1b:
    cidr_block: "10.0.11.0/24"
    availability_zone: us-east-1b
    create_route_table: true
    tags:
      Tier: private
      kubernetes.io/role/internal-elb: "1"

  private-1c:
    cidr_block: "10.0.12.0/24"
    availability_zone: us-east-1c
    create_route_table: true
    tags:
      Tier: private
      kubernetes.io/role/internal-elb: "1"

  # Database Subnets (Isolated)
  database-1a:
    cidr_block: "10.0.20.0/24"
    availability_zone: us-east-1a
    create_route_table: true
    # No NAT route for isolated subnets
    tags:
      Tier: database

  database-1b:
    cidr_block: "10.0.21.0/24"
    availability_zone: us-east-1b
    create_route_table: true
    tags:
      Tier: database

  database-1c:
    cidr_block: "10.0.22.0/24"
    availability_zone: us-east-1c
    create_route_table: true
    tags:
      Tier: database

  # Subnet with Custom Routes
  custom-1a:
    cidr_block: "10.0.30.0/24"
    availability_zone: us-east-1a
    create_route_table: true
    routes:
      - destination_cidr_block: "172.16.0.0/16"
        transit_gateway_id: tgw-abc123
      - destination_cidr_block: "192.168.0.0/16"
        vpc_peering_connection_id: pcx-abc123

  # Subnet with Custom NACL
  secure-1a:
    cidr_block: "10.0.40.0/24"
    availability_zone: us-east-1a
    create_route_table: true
    create_nacl: true
    nacl_ingress:
      - rule_no: 100
        action: allow
        from_port: 443
        to_port: 443
        protocol: tcp
        cidr_block: "10.0.0.0/16"
      - rule_no: 110
        action: allow
        from_port: 1024
        to_port: 65535
        protocol: tcp
        cidr_block: "0.0.0.0/0"
    nacl_egress:
      - rule_no: 100
        action: allow
        from_port: 443
        to_port: 443
        protocol: tcp
        cidr_block: "0.0.0.0/0"
      - rule_no: 110
        action: allow
        from_port: 1024
        to_port: 65535
        protocol: tcp
        cidr_block: "10.0.0.0/16"

# === Shared Routes ===
# Additional routes for all public subnets
public_route_table_routes: []

# Additional routes for all private subnets
private_route_table_routes:
  - destination_cidr_block: "172.16.0.0/12"
    transit_gateway_id: tgw-abc123

# === Subnet Groups ===
create_db_subnet_group: true
db_subnet_group_name: production-db
db_subnet_group_subnet_names:
  - database-1a
  - database-1b
  - database-1c

create_elasticache_subnet_group: true
elasticache_subnet_group_name: production-cache
elasticache_subnet_group_subnet_names:
  - private-1a
  - private-1b
  - private-1c

create_redshift_subnet_group: false
# redshift_subnet_group_name: production-redshift
# redshift_subnet_group_subnet_names:
#   - database-1a
#   - database-1b

# === Tags ===
tags:
  Environment: production
  Team: platform
  CostCenter: "12345"

subnet_tags:
  ManagedBy: terraform

route_table_tags: {}
```

## Multi-AZ Setup Example

```yaml
# Complete 3-AZ setup with public, private, and database tiers
vpc_id: vpc-abc123
name_prefix: prod

internet_gateway_id: igw-abc123
nat_gateway_ids:
  us-east-1a: nat-111
  us-east-1b: nat-222
  us-east-1c: nat-333

subnets:
  # Public tier (3 AZs)
  public-1a:
    cidr_block: "10.0.0.0/24"
    availability_zone: us-east-1a
    map_public_ip_on_launch: true
  public-1b:
    cidr_block: "10.0.1.0/24"
    availability_zone: us-east-1b
    map_public_ip_on_launch: true
  public-1c:
    cidr_block: "10.0.2.0/24"
    availability_zone: us-east-1c
    map_public_ip_on_launch: true

  # Private tier (3 AZs)
  private-1a:
    cidr_block: "10.0.10.0/24"
    availability_zone: us-east-1a
  private-1b:
    cidr_block: "10.0.11.0/24"
    availability_zone: us-east-1b
  private-1c:
    cidr_block: "10.0.12.0/24"
    availability_zone: us-east-1c

  # Database tier (3 AZs - isolated)
  db-1a:
    cidr_block: "10.0.20.0/24"
    availability_zone: us-east-1a
  db-1b:
    cidr_block: "10.0.21.0/24"
    availability_zone: us-east-1b
  db-1c:
    cidr_block: "10.0.22.0/24"
    availability_zone: us-east-1c

create_db_subnet_group: true
db_subnet_group_subnet_names:
  - db-1a
  - db-1b
  - db-1c
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_id | ID of the VPC | `string` | n/a | yes |
| name_prefix | Prefix for resource names | `string` | n/a | yes |
| subnets | Map of subnets to create | `map(object)` | n/a | yes |
| internet_gateway_id | ID of the Internet Gateway | `string` | `null` | no |
| nat_gateway_ids | Map of AZ to NAT Gateway ID | `map(string)` | `{}` | no |
| single_nat_gateway_id | Single NAT Gateway ID | `string` | `null` | no |
| public_route_table_routes | Routes for public subnets | `list(object)` | `[]` | no |
| private_route_table_routes | Routes for private subnets | `list(object)` | `[]` | no |
| create_db_subnet_group | Create DB subnet group | `bool` | `false` | no |
| db_subnet_group_subnet_names | Subnets for DB group | `list(string)` | `[]` | no |
| create_elasticache_subnet_group | Create ElastiCache subnet group | `bool` | `false` | no |
| create_redshift_subnet_group | Create Redshift subnet group | `bool` | `false` | no |
| tags | Tags to apply | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| subnet_ids | Map of subnet names to IDs |
| subnet_arns | Map of subnet names to ARNs |
| subnet_cidr_blocks | Map of subnet names to CIDR blocks |
| subnet_availability_zones | Map of subnet names to AZs |
| subnets | Map of all subnet attributes |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| route_table_ids | Map of subnet names to route table IDs |
| network_acl_ids | Map of subnet names to NACL IDs |
| db_subnet_group_id | ID of the DB subnet group |
| db_subnet_group_name | Name of the DB subnet group |
| elasticache_subnet_group_id | ID of the ElastiCache subnet group |
| elasticache_subnet_group_name | Name of the ElastiCache subnet group |
| redshift_subnet_group_id | ID of the Redshift subnet group |
| availability_zones | List of availability zones used |

