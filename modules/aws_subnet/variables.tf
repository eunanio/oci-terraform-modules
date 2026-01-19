# VPC Configuration
variable "vpc_id" {
  description = "ID of the VPC where subnets will be created"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

# Subnets
variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    cidr_block              = string
    availability_zone       = string
    map_public_ip_on_launch = optional(bool, false)
    
    # Route table
    create_route_table     = optional(bool, true)
    route_table_id         = optional(string)
    routes = optional(list(object({
      destination_cidr_block     = optional(string)
      destination_prefix_list_id = optional(string)
      gateway_id                 = optional(string)
      nat_gateway_id             = optional(string)
      transit_gateway_id         = optional(string)
      vpc_peering_connection_id  = optional(string)
      vpc_endpoint_id            = optional(string)
      network_interface_id       = optional(string)
    })), [])
    
    # Network ACL
    create_nacl = optional(bool, false)
    nacl_id     = optional(string)
    nacl_ingress = optional(list(object({
      rule_no         = number
      action          = string
      from_port       = number
      to_port         = number
      protocol        = string
      cidr_block      = optional(string)
      ipv6_cidr_block = optional(string)
    })), [])
    nacl_egress = optional(list(object({
      rule_no         = number
      action          = string
      from_port       = number
      to_port         = number
      protocol        = string
      cidr_block      = optional(string)
      ipv6_cidr_block = optional(string)
    })), [])
    
    tags = optional(map(string), {})
  }))
}

# Shared Routes
variable "public_route_table_routes" {
  description = "Routes to add to public subnets route tables"
  type = list(object({
    destination_cidr_block     = optional(string)
    destination_prefix_list_id = optional(string)
    gateway_id                 = optional(string)
    nat_gateway_id             = optional(string)
    transit_gateway_id         = optional(string)
    vpc_peering_connection_id  = optional(string)
  }))
  default = []
}

variable "private_route_table_routes" {
  description = "Routes to add to private subnets route tables"
  type = list(object({
    destination_cidr_block     = optional(string)
    destination_prefix_list_id = optional(string)
    gateway_id                 = optional(string)
    nat_gateway_id             = optional(string)
    transit_gateway_id         = optional(string)
    vpc_peering_connection_id  = optional(string)
  }))
  default = []
}

# Internet Gateway (for public subnets)
variable "internet_gateway_id" {
  description = "ID of the Internet Gateway for public subnets"
  type        = string
  default     = null
}

# NAT Gateway (for private subnets)
variable "nat_gateway_ids" {
  description = "Map of AZ to NAT Gateway ID for private subnets"
  type        = map(string)
  default     = {}
}

variable "single_nat_gateway_id" {
  description = "Single NAT Gateway ID for all private subnets"
  type        = string
  default     = null
}

# Subnet Groups
variable "create_db_subnet_group" {
  description = "Whether to create a DB subnet group"
  type        = bool
  default     = false
}

variable "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  type        = string
  default     = null
}

variable "db_subnet_group_subnet_names" {
  description = "List of subnet names to include in DB subnet group"
  type        = list(string)
  default     = []
}

variable "create_elasticache_subnet_group" {
  description = "Whether to create an ElastiCache subnet group"
  type        = bool
  default     = false
}

variable "elasticache_subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  type        = string
  default     = null
}

variable "elasticache_subnet_group_subnet_names" {
  description = "List of subnet names to include in ElastiCache subnet group"
  type        = list(string)
  default     = []
}

variable "create_redshift_subnet_group" {
  description = "Whether to create a Redshift subnet group"
  type        = bool
  default     = false
}

variable "redshift_subnet_group_name" {
  description = "Name of the Redshift subnet group"
  type        = string
  default     = null
}

variable "redshift_subnet_group_subnet_names" {
  description = "List of subnet names to include in Redshift subnet group"
  type        = list(string)
  default     = []
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "subnet_tags" {
  description = "Additional tags for all subnets"
  type        = map(string)
  default     = {}
}

variable "route_table_tags" {
  description = "Additional tags for all route tables"
  type        = map(string)
  default     = {}
}

