# RDS Module

Creates an AWS RDS database instance with comprehensive configuration options including multi-engine support, encryption, backups, monitoring, and high availability.

## Features

- Multi-engine support (MySQL, PostgreSQL, MariaDB, Oracle, SQL Server)
- Storage configuration with autoscaling
- Multi-AZ deployment for high availability
- Automated backups and snapshots
- Parameter and option groups
- Security group management
- Encryption with KMS
- Performance Insights
- Enhanced monitoring
- IAM database authentication

## Usage with Nori

```bash
nori release create my-database ghcr.io/eunanio/oci-terraform-modules/rds:v1.0.0 -f values.yaml
```

## Usage with OpenTofu/Terraform

```hcl
module "rds" {
  source = "oci://ghcr.io/eunanio/oci-terraform-modules/rds?tag=v1.0.0"

  identifier     = "my-database"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.medium"

  allocated_storage = 50
  storage_type      = "gp3"

  db_name  = "myapp"
  username = "admin"

  subnet_ids             = ["subnet-abc123", "subnet-def456"]
  vpc_security_group_ids = ["sg-xyz789"]

  multi_az            = true
  storage_encrypted   = true
  deletion_protection = true

  tags = {
    Environment = "production"
  }
}
```

## Values File Example

```yaml
# values.yaml

# === Instance Identifier ===
identifier: my-app-database

# === Engine Configuration ===
engine: postgres
engine_version: "15.4"
instance_class: db.r6g.large

# === Database Configuration ===
db_name: myapp
username: admin
# password: MySecurePassword123!  # If omitted, a random password is generated
port: 5432

# === Storage Configuration ===
allocated_storage: 100
max_allocated_storage: 500  # Enable autoscaling up to 500 GB
storage_type: gp3
iops: 3000
storage_throughput: 125

# === Network Configuration ===
subnet_ids:
  - subnet-abc123
  - subnet-def456
  - subnet-ghi789

# Option 1: Use existing security groups
vpc_security_group_ids:
  - sg-abc123

# Option 2: Create security group
create_security_group: true
vpc_id: vpc-xyz789
allowed_cidr_blocks:
  - 10.0.0.0/8
allowed_security_groups:
  - sg-app-servers

publicly_accessible: false
availability_zone: null  # Let AWS choose, or specify for single-AZ
multi_az: true

# === Encryption ===
storage_encrypted: true
kms_key_id: arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012

# === Backup Configuration ===
backup_retention_period: 30
backup_window: "03:00-04:00"
delete_automated_backups: false
copy_tags_to_snapshot: true
skip_final_snapshot: false
final_snapshot_identifier: my-app-database-final

# Restore from snapshot:
# snapshot_identifier: arn:aws:rds:us-east-1:123456789012:snapshot:my-snapshot

# === Maintenance ===
maintenance_window: "Mon:04:00-Mon:05:00"
auto_minor_version_upgrade: true
allow_major_version_upgrade: false
apply_immediately: false

# === Parameter Group ===
create_parameter_group: true
parameter_group_family: postgres15
parameters:
  - name: log_connections
    value: "1"
    apply_method: immediate
  - name: log_disconnections
    value: "1"
    apply_method: immediate
  - name: log_min_duration_statement
    value: "1000"
    apply_method: immediate
  - name: shared_preload_libraries
    value: pg_stat_statements
    apply_method: pending-reboot

# === Option Group (for Oracle/SQL Server) ===
# create_option_group: true
# major_engine_version: "19"
# options:
#   - option_name: STATSPACK
#   - option_name: OEM
#     port: 5500

# === Monitoring ===
# Enhanced Monitoring
monitoring_interval: 60
create_monitoring_role: true

# Performance Insights
performance_insights_enabled: true
performance_insights_retention_period: 7
# performance_insights_kms_key_id: arn:aws:kms:...

# CloudWatch Logs
enabled_cloudwatch_logs_exports:
  - postgresql
  - upgrade

# === Security ===
deletion_protection: true
iam_database_authentication_enabled: true

# === Engine-Specific Settings ===
# For Oracle/SQL Server:
# character_set_name: AL32UTF8
# license_model: bring-your-own-license

# Active Directory Integration:
# domain: d-1234567890
# domain_iam_role_name: my-ad-role

# Network type (IPv4 or dual-stack):
# network_type: DUAL

# CA Certificate:
# ca_cert_identifier: rds-ca-rsa2048-g1

# === Tags ===
tags:
  Environment: production
  Application: my-app
  Team: platform
  CostCenter: "12345"
  Backup: daily
```

## Engine-Specific Examples

### PostgreSQL

```yaml
engine: postgres
engine_version: "15.4"
parameter_group_family: postgres15
enabled_cloudwatch_logs_exports:
  - postgresql
  - upgrade
```

### MySQL

```yaml
engine: mysql
engine_version: "8.0.35"
parameter_group_family: mysql8.0
enabled_cloudwatch_logs_exports:
  - audit
  - error
  - general
  - slowquery
```

### MariaDB

```yaml
engine: mariadb
engine_version: "10.11.6"
parameter_group_family: mariadb10.11
enabled_cloudwatch_logs_exports:
  - audit
  - error
  - general
  - slowquery
```

### Oracle

```yaml
engine: oracle-ee
engine_version: "19.0.0.0.ru-2024-01.rur-2024-01.r1"
instance_class: db.r5.large
license_model: bring-your-own-license
character_set_name: AL32UTF8
```

### SQL Server

```yaml
engine: sqlserver-se
engine_version: "15.00.4365.2.v1"
instance_class: db.r5.large
license_model: license-included
character_set_name: SQL_Latin1_General_CP1_CI_AS
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| identifier | Identifier for the RDS instance | `string` | n/a | yes |
| engine | Database engine | `string` | n/a | yes |
| engine_version | Database engine version | `string` | n/a | yes |
| instance_class | RDS instance class | `string` | n/a | yes |
| subnet_ids | List of subnet IDs | `list(string)` | n/a | yes |
| username | Master username | `string` | n/a | yes |
| db_name | Name of the database | `string` | `null` | no |
| password | Master password | `string` | `null` | no |
| port | Database port | `number` | `null` | no |
| allocated_storage | Initial storage in GB | `number` | `20` | no |
| max_allocated_storage | Maximum storage for autoscaling | `number` | `0` | no |
| storage_type | Storage type | `string` | `"gp3"` | no |
| iops | Provisioned IOPS | `number` | `null` | no |
| storage_throughput | Storage throughput in MiBps | `number` | `null` | no |
| vpc_security_group_ids | Security group IDs | `list(string)` | `[]` | no |
| create_security_group | Create a security group | `bool` | `false` | no |
| multi_az | Enable Multi-AZ | `bool` | `false` | no |
| storage_encrypted | Enable encryption | `bool` | `true` | no |
| kms_key_id | KMS key ARN | `string` | `null` | no |
| backup_retention_period | Backup retention in days | `number` | `7` | no |
| monitoring_interval | Enhanced monitoring interval | `number` | `0` | no |
| performance_insights_enabled | Enable Performance Insights | `bool` | `false` | no |
| deletion_protection | Enable deletion protection | `bool` | `false` | no |
| tags | Tags to apply | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| db_instance_id | ID of the RDS instance |
| db_instance_arn | ARN of the RDS instance |
| db_instance_identifier | Identifier of the RDS instance |
| db_instance_endpoint | Connection endpoint |
| db_instance_address | Hostname of the instance |
| db_instance_port | Database port |
| db_instance_name | Name of the database |
| db_instance_username | Master username |
| db_instance_password | Master password |
| db_instance_engine | Database engine |
| db_instance_engine_version_actual | Running engine version |
| db_subnet_group_id | ID of the DB subnet group |
| security_group_id | ID of the created security group |
| db_parameter_group_id | ID of the DB parameter group |
| db_option_group_id | ID of the DB option group |
| monitoring_role_arn | ARN of the monitoring IAM role |

