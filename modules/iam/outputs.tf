# Role Outputs
output "roles" {
  description = "Map of IAM role attributes"
  value = {
    for name, role in aws_iam_role.this : name => {
      arn         = role.arn
      name        = role.name
      unique_id   = role.unique_id
      create_date = role.create_date
    }
  }
}

output "role_arns" {
  description = "Map of IAM role names to ARNs"
  value       = { for name, role in aws_iam_role.this : name => role.arn }
}

# Instance Profile Outputs
output "instance_profiles" {
  description = "Map of IAM instance profile attributes"
  value = {
    for name, profile in aws_iam_instance_profile.this : name => {
      arn       = profile.arn
      name      = profile.name
      unique_id = profile.unique_id
    }
  }
}

output "instance_profile_arns" {
  description = "Map of IAM instance profile names to ARNs"
  value       = { for name, profile in aws_iam_instance_profile.this : name => profile.arn }
}

# User Outputs
output "users" {
  description = "Map of IAM user attributes"
  value = {
    for name, user in aws_iam_user.this : name => {
      arn       = user.arn
      name      = user.name
      unique_id = user.unique_id
    }
  }
}

output "user_arns" {
  description = "Map of IAM user names to ARNs"
  value       = { for name, user in aws_iam_user.this : name => user.arn }
}

output "user_login_profile_passwords" {
  description = "Map of user login profile encrypted passwords (requires PGP key)"
  value       = { for name, profile in aws_iam_user_login_profile.this : name => profile.encrypted_password }
  sensitive   = true
}

output "access_keys" {
  description = "Map of user access key details"
  value = {
    for name, key in aws_iam_access_key.this : name => {
      id                        = key.id
      encrypted_secret          = key.encrypted_secret
      encrypted_ses_smtp_password_v4 = key.encrypted_ses_smtp_password_v4
      create_date               = key.create_date
    }
  }
  sensitive = true
}

# Group Outputs
output "groups" {
  description = "Map of IAM group attributes"
  value = {
    for name, group in aws_iam_group.this : name => {
      arn       = group.arn
      name      = group.name
      unique_id = group.unique_id
    }
  }
}

output "group_arns" {
  description = "Map of IAM group names to ARNs"
  value       = { for name, group in aws_iam_group.this : name => group.arn }
}

# Policy Outputs
output "policies" {
  description = "Map of IAM policy attributes"
  value = {
    for name, policy in aws_iam_policy.this : name => {
      arn         = policy.arn
      name        = policy.name
      policy_id   = policy.policy_id
      path        = policy.path
    }
  }
}

output "policy_arns" {
  description = "Map of IAM policy names to ARNs"
  value       = { for name, policy in aws_iam_policy.this : name => policy.arn }
}

# OIDC Provider Outputs
output "oidc_providers" {
  description = "Map of OIDC provider attributes"
  value = {
    for name, provider in aws_iam_openid_connect_provider.this : name => {
      arn = provider.arn
      url = provider.url
    }
  }
}

output "oidc_provider_arns" {
  description = "Map of OIDC provider names to ARNs"
  value       = { for name, provider in aws_iam_openid_connect_provider.this : name => provider.arn }
}

