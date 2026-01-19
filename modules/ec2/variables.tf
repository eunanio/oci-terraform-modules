# Instance Configuration
variable "name" {
  description = "Name for the EC2 instance"
  type        = string
}

variable "ami" {
  description = "AMI ID for the instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "availability_zone" {
  description = "Availability zone for the instance"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Subnet ID for the instance"
  type        = string
}

variable "private_ip" {
  description = "Private IP address to associate with the instance"
  type        = string
  default     = null
}

variable "secondary_private_ips" {
  description = "List of secondary private IPs to associate with the instance"
  type        = list(string)
  default     = []
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address"
  type        = bool
  default     = false
}

# Key Pair
variable "key_name" {
  description = "Name of existing key pair to use"
  type        = string
  default     = null
}

variable "create_key_pair" {
  description = "Whether to create a new key pair"
  type        = bool
  default     = false
}

variable "public_key" {
  description = "Public key material for creating new key pair"
  type        = string
  default     = null
}

# Security Groups
variable "vpc_security_group_ids" {
  description = "List of security group IDs to associate"
  type        = list(string)
  default     = []
}

variable "create_security_group" {
  description = "Whether to create a security group for the instance"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID for the security group (required if create_security_group is true)"
  type        = string
  default     = null
}

variable "security_group_rules" {
  description = "Security group rules for the created security group"
  type = object({
    ingress = optional(list(object({
      description      = optional(string)
      from_port        = number
      to_port          = number
      protocol         = string
      cidr_blocks      = optional(list(string), [])
      ipv6_cidr_blocks = optional(list(string), [])
      security_groups  = optional(list(string), [])
      self             = optional(bool, false)
    })), [])
    egress = optional(list(object({
      description      = optional(string)
      from_port        = number
      to_port          = number
      protocol         = string
      cidr_blocks      = optional(list(string), [])
      ipv6_cidr_blocks = optional(list(string), [])
      security_groups  = optional(list(string), [])
      self             = optional(bool, false)
    })), [])
  })
  default = {
    ingress = []
    egress = [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
  }
}

# IAM Instance Profile
variable "iam_instance_profile" {
  description = "IAM instance profile name or ARN"
  type        = string
  default     = null
}

# Root Volume
variable "root_volume" {
  description = "Root EBS volume configuration"
  type = object({
    volume_size           = optional(number, 8)
    volume_type           = optional(string, "gp3")
    iops                  = optional(number)
    throughput            = optional(number)
    encrypted             = optional(bool, true)
    kms_key_id            = optional(string)
    delete_on_termination = optional(bool, true)
  })
  default = {}
}

# Additional EBS Volumes
variable "ebs_volumes" {
  description = "Additional EBS volumes to attach"
  type = map(object({
    device_name           = string
    volume_size           = number
    volume_type           = optional(string, "gp3")
    iops                  = optional(number)
    throughput            = optional(number)
    encrypted             = optional(bool, true)
    kms_key_id            = optional(string)
    delete_on_termination = optional(bool, true)
    snapshot_id           = optional(string)
  }))
  default = {}
}

# User Data
variable "user_data" {
  description = "User data script for the instance"
  type        = string
  default     = null
}

variable "user_data_base64" {
  description = "Base64-encoded user data"
  type        = string
  default     = null
}

variable "user_data_replace_on_change" {
  description = "Whether to replace instance when user data changes"
  type        = bool
  default     = false
}

# Metadata Options (IMDSv2)
variable "metadata_options" {
  description = "Instance metadata service options"
  type = object({
    http_endpoint               = optional(string, "enabled")
    http_tokens                 = optional(string, "required")
    http_put_response_hop_limit = optional(number, 1)
    instance_metadata_tags      = optional(string, "disabled")
  })
  default = {}
}

# Monitoring
variable "monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = false
}

# Placement
variable "placement_group" {
  description = "Placement group for the instance"
  type        = string
  default     = null
}

variable "tenancy" {
  description = "Instance tenancy (default, dedicated, host)"
  type        = string
  default     = "default"
}

variable "host_id" {
  description = "Dedicated host ID for the instance"
  type        = string
  default     = null
}

# Credit Specification (T-series instances)
variable "credit_specification" {
  description = "Credit specification for T-series instances"
  type = object({
    cpu_credits = string # standard or unlimited
  })
  default = null
}

# Instance Lifecycle
variable "disable_api_termination" {
  description = "Enable termination protection"
  type        = bool
  default     = false
}

variable "disable_api_stop" {
  description = "Enable stop protection"
  type        = bool
  default     = false
}

variable "instance_initiated_shutdown_behavior" {
  description = "Shutdown behavior (stop or terminate)"
  type        = string
  default     = "stop"
}

variable "hibernation" {
  description = "Enable hibernation"
  type        = bool
  default     = false
}

# Elastic IP
variable "create_eip" {
  description = "Whether to create and associate an Elastic IP"
  type        = bool
  default     = false
}

variable "eip_domain" {
  description = "Indicates if this EIP is for use in VPC"
  type        = string
  default     = "vpc"
}

# Capacity Reservation
variable "capacity_reservation_specification" {
  description = "Capacity reservation specification"
  type = object({
    capacity_reservation_preference = optional(string)
    capacity_reservation_target = optional(object({
      capacity_reservation_id                 = optional(string)
      capacity_reservation_resource_group_arn = optional(string)
    }))
  })
  default = null
}

# Enclave Options
variable "enclave_options_enabled" {
  description = "Enable Nitro Enclaves"
  type        = bool
  default     = false
}

# Source/Dest Check
variable "source_dest_check" {
  description = "Enable source/destination check"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "volume_tags" {
  description = "Additional tags for EBS volumes"
  type        = map(string)
  default     = {}
}

