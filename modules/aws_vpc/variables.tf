# VPC Configuration
variable "name" {
  description = "Name for the VPC and related resources"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_tenancy" {
  description = "Instance tenancy (default, dedicated)"
  type        = string
  default     = "default"
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_network_address_usage_metrics" {
  description = "Enable network address usage metrics"
  type        = bool
  default     = false
}

# Secondary CIDR Blocks
variable "secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks to associate with the VPC"
  type        = list(string)
  default     = []
}

# Internet Gateway
variable "create_igw" {
  description = "Whether to create an Internet Gateway"
  type        = bool
  default     = true
}

# NAT Gateway
variable "nat_gateway_config" {
  description = "NAT Gateway configuration"
  type = object({
    enabled          = optional(bool, false)
    single_nat       = optional(bool, false)
    allocation_ids   = optional(list(string), [])
    subnet_ids       = optional(list(string), [])
  })
  default = {}
}

# VPC Flow Logs
variable "flow_logs" {
  description = "VPC Flow Logs configuration"
  type = object({
    enabled                 = optional(bool, false)
    traffic_type            = optional(string, "ALL")
    destination_type        = optional(string, "cloud-watch-logs")
    log_destination         = optional(string)
    log_format              = optional(string)
    max_aggregation_interval = optional(number, 600)
    create_log_group        = optional(bool, true)
    log_retention_days      = optional(number, 30)
    create_iam_role         = optional(bool, true)
    iam_role_arn            = optional(string)
  })
  default = {}
}

# DHCP Options
variable "dhcp_options" {
  description = "DHCP options configuration"
  type = object({
    domain_name          = optional(string)
    domain_name_servers  = optional(list(string))
    ntp_servers          = optional(list(string))
    netbios_name_servers = optional(list(string))
    netbios_node_type    = optional(number)
  })
  default = null
}

# VPC Endpoints
variable "gateway_endpoints" {
  description = "Gateway VPC endpoints (S3, DynamoDB)"
  type = map(object({
    service_name        = string
    route_table_ids     = optional(list(string), [])
    policy              = optional(string)
    private_dns_enabled = optional(bool, false)
  }))
  default = {}
}

variable "interface_endpoints" {
  description = "Interface VPC endpoints"
  type = map(object({
    service_name        = string
    subnet_ids          = optional(list(string), [])
    security_group_ids  = optional(list(string), [])
    private_dns_enabled = optional(bool, true)
    policy              = optional(string)
  }))
  default = {}
}

variable "create_endpoint_security_group" {
  description = "Whether to create a security group for interface endpoints"
  type        = bool
  default     = false
}

variable "endpoint_security_group_rules" {
  description = "Security group rules for interface endpoints"
  type = object({
    ingress_cidr_blocks = optional(list(string), [])
    ingress_rules = optional(list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      description = optional(string)
    })), [])
  })
  default = {}
}

# Default Security Group
variable "manage_default_security_group" {
  description = "Whether to manage the default security group"
  type        = bool
  default     = false
}

variable "default_security_group_ingress" {
  description = "Ingress rules for default security group"
  type = list(object({
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string))
    ipv6_cidr_blocks = optional(list(string))
    self             = optional(bool)
    description      = optional(string)
  }))
  default = []
}

variable "default_security_group_egress" {
  description = "Egress rules for default security group"
  type = list(object({
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string))
    ipv6_cidr_blocks = optional(list(string))
    self             = optional(bool)
    description      = optional(string)
  }))
  default = []
}

# Default Network ACL
variable "manage_default_network_acl" {
  description = "Whether to manage the default network ACL"
  type        = bool
  default     = false
}

variable "default_network_acl_ingress" {
  description = "Ingress rules for default network ACL"
  type = list(object({
    rule_no    = number
    action     = string
    from_port  = number
    to_port    = number
    protocol   = string
    cidr_block = optional(string)
    ipv6_cidr_block = optional(string)
  }))
  default = []
}

variable "default_network_acl_egress" {
  description = "Egress rules for default network ACL"
  type = list(object({
    rule_no    = number
    action     = string
    from_port  = number
    to_port    = number
    protocol   = string
    cidr_block = optional(string)
    ipv6_cidr_block = optional(string)
  }))
  default = []
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_tags" {
  description = "Additional tags for the VPC"
  type        = map(string)
  default     = {}
}

variable "igw_tags" {
  description = "Additional tags for the Internet Gateway"
  type        = map(string)
  default     = {}
}

variable "nat_gateway_tags" {
  description = "Additional tags for NAT Gateways"
  type        = map(string)
  default     = {}
}

