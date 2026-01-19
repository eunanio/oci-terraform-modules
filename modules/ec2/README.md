# EC2 Instance Module

Creates an AWS EC2 instance with comprehensive configuration options including EBS volumes, security groups, key pairs, and user data.

## Features

- Flexible instance configuration (type, AMI, placement)
- Key pair management (create or use existing)
- Security group creation or association
- Root and additional EBS volumes with encryption
- User data scripts support
- Elastic IP association
- IMDSv2 metadata options (secure by default)
- Credit specification for T-series instances
- Termination and stop protection

## Usage with Nori

```bash
nori release create my-instance ghcr.io/eunanio/oci-terraform-modules/ec2:v1.0.0 -f values.yaml
```

## Usage with OpenTofu

```hcl
module "ec2_instance" {
  source = "oci://ghcr.io/eunanio/oci-terraform-modules/ec2?tag=v1.0.0"

  name          = "web-server"
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.medium"
  subnet_id     = "subnet-abc123"

  vpc_security_group_ids = ["sg-xyz789"]
  iam_instance_profile   = "my-instance-profile"

  root_volume = {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Environment = "production"
  }
}
```

## Values File Example

```yaml
# values.yaml

# === Instance Configuration ===
name: web-server-01
ami: ami-0abcdef1234567890
instance_type: t3.medium
availability_zone: us-east-1a
subnet_id: subnet-abc123

# Private IP configuration
private_ip: 10.0.1.100
secondary_private_ips:
  - 10.0.1.101
  - 10.0.1.102

# Public IP (for instances in public subnets)
associate_public_ip_address: false

# === Key Pair ===
# Option 1: Use existing key pair
key_name: my-existing-key

# Option 2: Create new key pair
# create_key_pair: true
# public_key: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ...

# === Security Groups ===
# Option 1: Use existing security groups
vpc_security_group_ids:
  - sg-abc123
  - sg-def456

# Option 2: Create a security group
# create_security_group: true
# vpc_id: vpc-xyz789
# security_group_rules:
#   ingress:
#     - description: SSH access
#       from_port: 22
#       to_port: 22
#       protocol: tcp
#       cidr_blocks:
#         - 10.0.0.0/8
#     - description: HTTPS
#       from_port: 443
#       to_port: 443
#       protocol: tcp
#       cidr_blocks:
#         - 0.0.0.0/0
#     - description: HTTP
#       from_port: 80
#       to_port: 80
#       protocol: tcp
#       cidr_blocks:
#         - 0.0.0.0/0
#   egress:
#     - description: All outbound
#       from_port: 0
#       to_port: 0
#       protocol: "-1"
#       cidr_blocks:
#         - 0.0.0.0/0

# === IAM Instance Profile ===
iam_instance_profile: my-app-instance-profile

# === Root Volume ===
root_volume:
  volume_size: 50
  volume_type: gp3
  iops: 3000
  throughput: 125
  encrypted: true
  kms_key_id: arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012
  delete_on_termination: true

# === Additional EBS Volumes ===
ebs_volumes:
  data:
    device_name: /dev/xvdf
    volume_size: 100
    volume_type: gp3
    iops: 3000
    throughput: 125
    encrypted: true
    delete_on_termination: false
  logs:
    device_name: /dev/xvdg
    volume_size: 50
    volume_type: gp3
    encrypted: true
    delete_on_termination: true

# === User Data ===
user_data: |
  #!/bin/bash
  yum update -y
  yum install -y httpd
  systemctl start httpd
  systemctl enable httpd
  echo "Hello from $(hostname)" > /var/www/html/index.html

# For base64-encoded user data:
# user_data_base64: SGVsbG8gV29ybGQh

# Replace instance when user data changes
user_data_replace_on_change: false

# === Metadata Options (IMDSv2) ===
metadata_options:
  http_endpoint: enabled
  http_tokens: required  # Enforce IMDSv2
  http_put_response_hop_limit: 1
  instance_metadata_tags: enabled

# === Monitoring ===
monitoring: true  # Enable detailed monitoring

# === Placement ===
placement_group: my-placement-group
tenancy: default  # default, dedicated, or host
# host_id: h-abc123  # For dedicated host

# === Credit Specification (T-series) ===
credit_specification:
  cpu_credits: unlimited  # standard or unlimited

# === Instance Lifecycle ===
disable_api_termination: true  # Termination protection
disable_api_stop: false
instance_initiated_shutdown_behavior: stop  # stop or terminate
hibernation: false

# === Elastic IP ===
create_eip: true
eip_domain: vpc

# === Capacity Reservation ===
# capacity_reservation_specification:
#   capacity_reservation_preference: open  # open or none
#   capacity_reservation_target:
#     capacity_reservation_id: cr-abc123

# === Enclave Options ===
enclave_options_enabled: false

# === Source/Dest Check ===
source_dest_check: true  # Set to false for NAT instances

# === Tags ===
tags:
  Environment: production
  Application: web-server
  Team: platform
  CostCenter: "12345"

volume_tags:
  Backup: daily
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name for the EC2 instance | `string` | n/a | yes |
| ami | AMI ID for the instance | `string` | n/a | yes |
| subnet_id | Subnet ID for the instance | `string` | n/a | yes |
| instance_type | EC2 instance type | `string` | `"t3.micro"` | no |
| availability_zone | Availability zone for the instance | `string` | `null` | no |
| private_ip | Private IP address | `string` | `null` | no |
| secondary_private_ips | List of secondary private IPs | `list(string)` | `[]` | no |
| associate_public_ip_address | Associate a public IP | `bool` | `false` | no |
| key_name | Name of existing key pair | `string` | `null` | no |
| create_key_pair | Create a new key pair | `bool` | `false` | no |
| public_key | Public key material | `string` | `null` | no |
| vpc_security_group_ids | Security group IDs | `list(string)` | `[]` | no |
| create_security_group | Create a security group | `bool` | `false` | no |
| vpc_id | VPC ID for security group | `string` | `null` | no |
| security_group_rules | Security group rules | `object` | `{}` | no |
| iam_instance_profile | IAM instance profile | `string` | `null` | no |
| root_volume | Root EBS volume configuration | `object` | `{}` | no |
| ebs_volumes | Additional EBS volumes | `map(object)` | `{}` | no |
| user_data | User data script | `string` | `null` | no |
| user_data_base64 | Base64-encoded user data | `string` | `null` | no |
| metadata_options | Instance metadata options | `object` | `{}` | no |
| monitoring | Enable detailed monitoring | `bool` | `false` | no |
| placement_group | Placement group name | `string` | `null` | no |
| tenancy | Instance tenancy | `string` | `"default"` | no |
| credit_specification | Credit specification for T-series | `object` | `null` | no |
| disable_api_termination | Enable termination protection | `bool` | `false` | no |
| create_eip | Create Elastic IP | `bool` | `false` | no |
| tags | Tags to apply | `map(string)` | `{}` | no |
| volume_tags | Additional tags for EBS volumes | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_id | ID of the EC2 instance |
| instance_arn | ARN of the EC2 instance |
| instance_state | State of the EC2 instance |
| private_ip | Private IP address |
| private_dns | Private DNS name |
| public_ip | Public IP address |
| public_dns | Public DNS name |
| availability_zone | Availability zone |
| security_group_id | ID of created security group |
| security_group_arn | ARN of created security group |
| key_pair_name | Name of the key pair |
| key_pair_id | ID of created key pair |
| root_volume_id | ID of the root EBS volume |
| ebs_volumes | Map of additional EBS volume attributes |
| ebs_volume_ids | Map of EBS volume names to IDs |
| eip_id | ID of the Elastic IP |
| eip_public_ip | Public IP of the Elastic IP |
| eip_allocation_id | Allocation ID of the Elastic IP |
| primary_network_interface_id | ID of primary network interface |

