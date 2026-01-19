# Cluster Configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = null
}

variable "cluster_role_arn" {
  description = "ARN of existing IAM role for the cluster"
  type        = string
  default     = null
}

variable "create_cluster_role" {
  description = "Whether to create the cluster IAM role"
  type        = bool
  default     = true
}

# Network Configuration
variable "subnet_ids" {
  description = "Subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Additional security group IDs for the cluster"
  type        = list(string)
  default     = []
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks that can access the public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Encryption
variable "encryption_config" {
  description = "Encryption configuration for secrets"
  type = object({
    provider_key_arn = string
    resources        = optional(list(string), ["secrets"])
  })
  default = null
}

# Logging
variable "enabled_cluster_log_types" {
  description = "List of control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_log_retention_days" {
  description = "CloudWatch log retention for cluster logs"
  type        = number
  default     = 30
}

# Access Configuration
variable "authentication_mode" {
  description = "Authentication mode for the cluster (CONFIG_MAP, API, or API_AND_CONFIG_MAP)"
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "bootstrap_cluster_creator_admin_permissions" {
  description = "Bootstrap cluster creator with admin permissions"
  type        = bool
  default     = true
}

# Node Groups
variable "node_groups" {
  description = "Map of EKS managed node groups"
  type = map(object({
    instance_types = list(string)
    capacity_type  = optional(string, "ON_DEMAND")
    disk_size      = optional(number, 50)
    
    scaling_config = optional(object({
      desired_size = optional(number, 2)
      min_size     = optional(number, 1)
      max_size     = optional(number, 10)
    }), {})
    
    update_config = optional(object({
      max_unavailable            = optional(number, 1)
      max_unavailable_percentage = optional(number)
    }), {})
    
    labels = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
    
    ami_type       = optional(string, "AL2_x86_64")
    release_version = optional(string)
    
    subnet_ids = optional(list(string))
    
    remote_access = optional(object({
      ec2_ssh_key               = optional(string)
      source_security_group_ids = optional(list(string), [])
    }))
    
    launch_template = optional(object({
      id      = optional(string)
      name    = optional(string)
      version = optional(string)
    }))
    
    node_role_arn   = optional(string)
    create_node_role = optional(bool, true)
    
    tags = optional(map(string), {})
  }))
  default = {}
}

# Fargate Profiles
variable "fargate_profiles" {
  description = "Map of Fargate profiles"
  type = map(object({
    subnet_ids = list(string)
    selectors = list(object({
      namespace = string
      labels    = optional(map(string), {})
    }))
    pod_execution_role_arn   = optional(string)
    create_pod_execution_role = optional(bool, true)
    tags                      = optional(map(string), {})
  }))
  default = {}
}

# Add-ons
variable "cluster_addons" {
  description = "Map of cluster add-ons to install"
  type = map(object({
    addon_version               = optional(string)
    resolve_conflicts_on_create = optional(string, "OVERWRITE")
    resolve_conflicts_on_update = optional(string, "PRESERVE")
    service_account_role_arn    = optional(string)
    configuration_values        = optional(string)
    preserve                    = optional(bool, true)
  }))
  default = {
    coredns = {}
    kube-proxy = {}
    vpc-cni = {}
  }
}

# OIDC Provider
variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts"
  type        = bool
  default     = true
}

# Access Entries
variable "access_entries" {
  description = "Map of access entries for the cluster"
  type = map(object({
    principal_arn     = string
    kubernetes_groups = optional(list(string), [])
    type              = optional(string, "STANDARD")
    policy_associations = optional(map(object({
      policy_arn = string
      access_scope = object({
        type       = string
        namespaces = optional(list(string), [])
      })
    })), {})
  }))
  default = {}
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

