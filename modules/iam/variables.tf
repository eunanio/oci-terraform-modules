# IAM Roles
variable "roles" {
  description = "Map of IAM roles to create"
  type = map(object({
    description           = optional(string, "")
    path                  = optional(string, "/")
    max_session_duration  = optional(number, 3600)
    force_detach_policies = optional(bool, false)
    permissions_boundary  = optional(string)
    assume_role_policy    = optional(string)
    assume_role_principals = optional(object({
      services    = optional(list(string), [])
      aws         = optional(list(string), [])
      federated   = optional(list(string), [])
    }))
    assume_role_conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
    managed_policy_arns = optional(list(string), [])
    inline_policies = optional(map(string), {})
    create_instance_profile = optional(bool, false)
    tags = optional(map(string), {})
  }))
  default = {}
}

# IAM Users
variable "users" {
  description = "Map of IAM users to create"
  type = map(object({
    path                 = optional(string, "/")
    permissions_boundary = optional(string)
    force_destroy        = optional(bool, false)
    create_login_profile = optional(bool, false)
    password_reset_required = optional(bool, true)
    create_access_key    = optional(bool, false)
    pgp_key              = optional(string)
    managed_policy_arns  = optional(list(string), [])
    inline_policies      = optional(map(string), {})
    groups               = optional(list(string), [])
    tags                 = optional(map(string), {})
  }))
  default = {}
}

# IAM Groups
variable "groups" {
  description = "Map of IAM groups to create"
  type = map(object({
    path                = optional(string, "/")
    managed_policy_arns = optional(list(string), [])
    inline_policies     = optional(map(string), {})
  }))
  default = {}
}

# IAM Policies
variable "policies" {
  description = "Map of IAM policies to create"
  type = map(object({
    description = optional(string, "")
    path        = optional(string, "/")
    policy      = string
    tags        = optional(map(string), {})
  }))
  default = {}
}

# OIDC Providers
variable "oidc_providers" {
  description = "Map of OIDC providers to create"
  type = map(object({
    url             = string
    client_id_list  = list(string)
    thumbprint_list = optional(list(string), [])
    tags            = optional(map(string), {})
  }))
  default = {}
}

# Account Settings
variable "account_alias" {
  description = "AWS account alias"
  type        = string
  default     = null
}

variable "account_password_policy" {
  description = "Account password policy settings"
  type = object({
    allow_users_to_change_password = optional(bool, true)
    hard_expiry                    = optional(bool, false)
    max_password_age               = optional(number, 0)
    minimum_password_length        = optional(number, 14)
    password_reuse_prevention      = optional(number, 24)
    require_lowercase_characters   = optional(bool, true)
    require_numbers                = optional(bool, true)
    require_symbols                = optional(bool, true)
    require_uppercase_characters   = optional(bool, true)
  })
  default = null
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

