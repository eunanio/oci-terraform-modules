# Zone Configuration
variable "zone_name" {
  description = "Name of the hosted zone (e.g., example.com)"
  type        = string
}

variable "comment" {
  description = "Comment for the hosted zone"
  type        = string
  default     = ""
}

variable "force_destroy" {
  description = "Destroy all records when destroying the zone"
  type        = bool
  default     = false
}

variable "private_zone" {
  description = "Whether this is a private hosted zone"
  type        = bool
  default     = false
}

variable "vpc_associations" {
  description = "VPC associations for private hosted zones"
  type = list(object({
    vpc_id     = string
    vpc_region = optional(string)
  }))
  default = []
}

variable "delegation_set_id" {
  description = "ID of the reusable delegation set to associate with the zone"
  type        = string
  default     = null
}

# DNSSEC
variable "dnssec_signing" {
  description = "Enable DNSSEC signing for the zone"
  type = object({
    enabled                = bool
    kms_key_arn            = optional(string)
  })
  default = null
}

# Query Logging
variable "query_logging" {
  description = "Query logging configuration"
  type = object({
    cloudwatch_log_group_arn = string
  })
  default = null
}

# DNS Records
variable "records" {
  description = "List of DNS records to create"
  type = list(object({
    name = string
    type = string
    ttl  = optional(number)
    records = optional(list(string))
    
    # Alias record configuration
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = optional(bool, false)
    }))
    
    # Routing policy configuration
    routing_policy = optional(object({
      # Simple routing (default)
      simple = optional(object({}))
      
      # Weighted routing
      weighted = optional(object({
        weight         = number
        set_identifier = string
      }))
      
      # Latency-based routing
      latency = optional(object({
        region         = string
        set_identifier = string
      }))
      
      # Geolocation routing
      geolocation = optional(object({
        continent      = optional(string)
        country        = optional(string)
        subdivision    = optional(string)
        set_identifier = string
      }))
      
      # Failover routing
      failover = optional(object({
        type           = string # PRIMARY or SECONDARY
        set_identifier = string
      }))
      
      # Multivalue answer routing
      multivalue = optional(object({
        set_identifier = string
      }))
      
      # IP-based routing
      ip_based = optional(object({
        collection_id  = string
        set_identifier = string
      }))
    }))
    
    # Health check ID
    health_check_id = optional(string)
    
    # Allow overwrite of existing records
    allow_overwrite = optional(bool, false)
  }))
  default = []
}

# Health Checks
variable "health_checks" {
  description = "Map of health checks to create"
  type = map(object({
    type              = string # HTTP, HTTPS, HTTP_STR_MATCH, HTTPS_STR_MATCH, TCP, CALCULATED, CLOUDWATCH_METRIC, RECOVERY_CONTROL
    
    # For endpoint health checks
    fqdn              = optional(string)
    ip_address        = optional(string)
    port              = optional(number)
    resource_path     = optional(string)
    
    # Check parameters
    failure_threshold = optional(number, 3)
    request_interval  = optional(number, 30)
    
    # String match
    search_string     = optional(string)
    
    # Invert health check
    invert_healthcheck = optional(bool, false)
    
    # Enable SNI
    enable_sni        = optional(bool)
    
    # Regions
    regions           = optional(list(string))
    
    # Calculated health check
    child_health_checks = optional(list(string))
    child_healthcheck_threshold = optional(number)
    
    # CloudWatch alarm health check
    cloudwatch_alarm_name   = optional(string)
    cloudwatch_alarm_region = optional(string)
    insufficient_data_health_status = optional(string)
    
    # Disabled
    disabled          = optional(bool, false)
    
    tags = optional(map(string), {})
  }))
  default = {}
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

