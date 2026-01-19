# Cluster Outputs
output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = aws_eks_cluster.this.version
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = aws_eks_cluster.this.status
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster API server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_platform_version" {
  description = "Platform version of the cluster"
  value       = aws_eks_cluster.this.platform_version
}

# OIDC Provider
output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL of the cluster"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = var.enable_irsa ? aws_iam_openid_connect_provider.cluster[0].arn : null
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider (without https://)"
  value       = var.enable_irsa ? replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "") : null
}

# Cluster IAM Role
output "cluster_role_arn" {
  description = "ARN of the cluster IAM role"
  value       = local.cluster_role_arn
}

output "cluster_role_name" {
  description = "Name of the cluster IAM role"
  value       = var.create_cluster_role ? aws_iam_role.cluster[0].name : null
}

# Cluster Security
output "cluster_security_group_id" {
  description = "ID of the cluster security group"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

# Node Groups
output "node_groups" {
  description = "Map of node group attributes"
  value = {
    for name, ng in aws_eks_node_group.this : name => {
      arn         = ng.arn
      id          = ng.id
      status      = ng.status
      role_arn    = ng.node_role_arn
      resources   = ng.resources
    }
  }
}

output "node_group_role_arns" {
  description = "Map of node group names to their IAM role ARNs"
  value = {
    for name, ng in var.node_groups : name =>
      ng.create_node_role ? aws_iam_role.node_group[name].arn : ng.node_role_arn
  }
}

output "node_group_role_names" {
  description = "Map of node group names to their IAM role names"
  value = {
    for name, ng in var.node_groups : name =>
      ng.create_node_role ? aws_iam_role.node_group[name].name : null
  }
}

# Fargate Profiles
output "fargate_profiles" {
  description = "Map of Fargate profile attributes"
  value = {
    for name, fp in aws_eks_fargate_profile.this : name => {
      arn    = fp.arn
      id     = fp.id
      status = fp.status
    }
  }
}

output "fargate_role_arns" {
  description = "Map of Fargate profile names to their IAM role ARNs"
  value = {
    for name, fp in var.fargate_profiles : name =>
      fp.create_pod_execution_role ? aws_iam_role.fargate[name].arn : fp.pod_execution_role_arn
  }
}

# Add-ons
output "cluster_addons" {
  description = "Map of cluster add-on attributes"
  value = {
    for name, addon in aws_eks_addon.this : name => {
      arn               = addon.arn
      id                = addon.id
      addon_version     = addon.addon_version
      created_at        = addon.created_at
      modified_at       = addon.modified_at
    }
  }
}

# CloudWatch Log Group
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = length(var.enabled_cluster_log_types) > 0 ? aws_cloudwatch_log_group.cluster[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = length(var.enabled_cluster_log_types) > 0 ? aws_cloudwatch_log_group.cluster[0].arn : null
}

