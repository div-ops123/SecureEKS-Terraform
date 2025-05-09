# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets_ids
}

output "private_subnets_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets_ids
}

# Security Group Outputs
output "eks_nodes_sg_id" {
  description = "ID of the EKS worker node security group"
  value       = module.sg.eks_nodes_sg_id
}

# EKS Cluster Outputs
output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "The certificate authority data for the EKS cluster"
  value       = module.eks.cluster_ca_certificate
}

# IAM Outputs
output "node_role_arn" {
  description = "The ARN of the IAM role for EKS worker nodes"
  value       = module.iam.eks_node_group_arn
}

output "eks_admin_role_arn" {
  description = "The ARN of the EKSAdminRole for cluster admin access"
  value       = module.iam.eks_admin_role_arn
}

output "eks_dev_role_arn" {
  description = "The ARN of the EKSDevRole for developer access"
  value       = module.iam.eks_dev_role_arn
}

output "eks_cicd_role_arn" {
  description = "The ARN of the EKSCICDRole for CI/CD pipeline access"
  value       = module.iam.eks_cicd_role_arn
}

output "eks_admin_group_name" {
  description = "The name of the IAM group for EKS admins"
  value       = module.iam.eks_admin_group_name
}

output "eks_admin_user_name" {
  description = "The name of the IAM user in the EKS admins group"
  value       = module.iam.eks_admin_user_name
}

output "eks_admin_user_access_key_id" {
  description = "The access key ID for the EKS admin user"
  value       = module.iam.eks_admin_user_access_key_id
}

output "eks_admin_user_secret_access_key" {
  description = "The secret access key for the EKS admin user (sensitive)"
  value       = module.iam.eks_admin_user_secret_access_key
  sensitive   = true
}

output "eks_dev_user_name" {
  description = "The name of the IAM user in the EKS dev group"
  value       = module.iam.eks_dev_user_name
}

output "eks_dev_user_access_key_id" {
  description = "The access key ID for the EKS developer user"
  value       = module.iam.eks_dev_user_access_key_id
}

output "eks_dev_user_secret_access_key" {
  description = "The secret access key for the EKS developer user (sensitive)"
  value       = module.iam.eks_dev_user_secret_access_key
  sensitive   = true
}

output "rds_endpoint" {
  value = module.rds.rds_endpoint
}