# Locals for assume role policy generation
locals {
  # Generate assume role policies for roles that don't have a custom policy
  assume_role_policies = {
    for name, role in var.roles : name => role.assume_role_policy != null ? role.assume_role_policy : jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = merge(
            length(try(role.assume_role_principals.services, [])) > 0 ? {
              Service = role.assume_role_principals.services
            } : {},
            length(try(role.assume_role_principals.aws, [])) > 0 ? {
              AWS = role.assume_role_principals.aws
            } : {},
            length(try(role.assume_role_principals.federated, [])) > 0 ? {
              Federated = role.assume_role_principals.federated
            } : {}
          )
          Action = "sts:AssumeRole"
          dynamic "Condition" {
            for_each = length(try(role.assume_role_conditions, [])) > 0 ? [1] : []
            content {
              for condition in role.assume_role_conditions : condition.test => {
                (condition.variable) = condition.values
              }
            }
          }
        }
      ]
    })
  }
}

# IAM Roles
resource "aws_iam_role" "this" {
  for_each = var.roles

  name                  = each.key
  description           = each.value.description
  path                  = each.value.path
  max_session_duration  = each.value.max_session_duration
  force_detach_policies = each.value.force_detach_policies
  permissions_boundary  = each.value.permissions_boundary
  assume_role_policy    = local.assume_role_policies[each.key]

  tags = merge(var.tags, each.value.tags)
}

# Managed policy attachments for roles
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = {
    for pair in flatten([
      for role_name, role in var.roles : [
        for policy_arn in role.managed_policy_arns : {
          role_name  = role_name
          policy_arn = policy_arn
        }
      ]
    ]) : "${pair.role_name}-${pair.policy_arn}" => pair
  }

  role       = aws_iam_role.this[each.value.role_name].name
  policy_arn = each.value.policy_arn
}

# Inline policies for roles
resource "aws_iam_role_policy" "inline" {
  for_each = {
    for pair in flatten([
      for role_name, role in var.roles : [
        for policy_name, policy in role.inline_policies : {
          role_name   = role_name
          policy_name = policy_name
          policy      = policy
        }
      ]
    ]) : "${pair.role_name}-${pair.policy_name}" => pair
  }

  name   = each.value.policy_name
  role   = aws_iam_role.this[each.value.role_name].id
  policy = each.value.policy
}

# Instance Profiles
resource "aws_iam_instance_profile" "this" {
  for_each = { for name, role in var.roles : name => role if role.create_instance_profile }

  name = each.key
  role = aws_iam_role.this[each.key].name
  path = each.value.path

  tags = merge(var.tags, each.value.tags)
}

# IAM Users
resource "aws_iam_user" "this" {
  for_each = var.users

  name                 = each.key
  path                 = each.value.path
  permissions_boundary = each.value.permissions_boundary
  force_destroy        = each.value.force_destroy

  tags = merge(var.tags, each.value.tags)
}

# User login profiles (console access)
resource "aws_iam_user_login_profile" "this" {
  for_each = { for name, user in var.users : name => user if user.create_login_profile }

  user                    = aws_iam_user.this[each.key].name
  password_reset_required = each.value.password_reset_required
  pgp_key                 = each.value.pgp_key
}

# User access keys (programmatic access)
resource "aws_iam_access_key" "this" {
  for_each = { for name, user in var.users : name => user if user.create_access_key }

  user    = aws_iam_user.this[each.key].name
  pgp_key = each.value.pgp_key
}

# Managed policy attachments for users
resource "aws_iam_user_policy_attachment" "managed" {
  for_each = {
    for pair in flatten([
      for user_name, user in var.users : [
        for policy_arn in user.managed_policy_arns : {
          user_name  = user_name
          policy_arn = policy_arn
        }
      ]
    ]) : "${pair.user_name}-${pair.policy_arn}" => pair
  }

  user       = aws_iam_user.this[each.value.user_name].name
  policy_arn = each.value.policy_arn
}

# Inline policies for users
resource "aws_iam_user_policy" "inline" {
  for_each = {
    for pair in flatten([
      for user_name, user in var.users : [
        for policy_name, policy in user.inline_policies : {
          user_name   = user_name
          policy_name = policy_name
          policy      = policy
        }
      ]
    ]) : "${pair.user_name}-${pair.policy_name}" => pair
  }

  name   = each.value.policy_name
  user   = aws_iam_user.this[each.value.user_name].name
  policy = each.value.policy
}

# IAM Groups
resource "aws_iam_group" "this" {
  for_each = var.groups

  name = each.key
  path = each.value.path
}

# Managed policy attachments for groups
resource "aws_iam_group_policy_attachment" "managed" {
  for_each = {
    for pair in flatten([
      for group_name, group in var.groups : [
        for policy_arn in group.managed_policy_arns : {
          group_name = group_name
          policy_arn = policy_arn
        }
      ]
    ]) : "${pair.group_name}-${pair.policy_arn}" => pair
  }

  group      = aws_iam_group.this[each.value.group_name].name
  policy_arn = each.value.policy_arn
}

# Inline policies for groups
resource "aws_iam_group_policy" "inline" {
  for_each = {
    for pair in flatten([
      for group_name, group in var.groups : [
        for policy_name, policy in group.inline_policies : {
          group_name  = group_name
          policy_name = policy_name
          policy      = policy
        }
      ]
    ]) : "${pair.group_name}-${pair.policy_name}" => pair
  }

  name   = each.value.policy_name
  group  = aws_iam_group.this[each.value.group_name].name
  policy = each.value.policy
}

# User group memberships
resource "aws_iam_user_group_membership" "this" {
  for_each = { for name, user in var.users : name => user if length(user.groups) > 0 }

  user   = aws_iam_user.this[each.key].name
  groups = each.value.groups

  depends_on = [aws_iam_group.this]
}

# IAM Policies
resource "aws_iam_policy" "this" {
  for_each = var.policies

  name        = each.key
  description = each.value.description
  path        = each.value.path
  policy      = each.value.policy

  tags = merge(var.tags, each.value.tags)
}

# OIDC Providers
resource "aws_iam_openid_connect_provider" "this" {
  for_each = var.oidc_providers

  url             = each.value.url
  client_id_list  = each.value.client_id_list
  thumbprint_list = each.value.thumbprint_list

  tags = merge(var.tags, each.value.tags)
}

# Account Alias
resource "aws_iam_account_alias" "this" {
  count = var.account_alias != null ? 1 : 0

  account_alias = var.account_alias
}

# Account Password Policy
resource "aws_iam_account_password_policy" "this" {
  count = var.account_password_policy != null ? 1 : 0

  allow_users_to_change_password = var.account_password_policy.allow_users_to_change_password
  hard_expiry                    = var.account_password_policy.hard_expiry
  max_password_age               = var.account_password_policy.max_password_age
  minimum_password_length        = var.account_password_policy.minimum_password_length
  password_reuse_prevention      = var.account_password_policy.password_reuse_prevention
  require_lowercase_characters   = var.account_password_policy.require_lowercase_characters
  require_numbers                = var.account_password_policy.require_numbers
  require_symbols                = var.account_password_policy.require_symbols
  require_uppercase_characters   = var.account_password_policy.require_uppercase_characters
}

