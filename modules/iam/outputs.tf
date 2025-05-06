# ARN of the EKSAdminRole
output "eks_admin_role_arn" {
  description = "The ARN of the EKSAdminRole, used for admin access to the EKS cluster"
  value       = aws_iam_role.eks_admin_role.arn
}

# ARN of the EKSDevRole
output "eks_dev_role_arn" {
  description = "The ARN of the EKSDevRole, used for developer access to the EKS cluster"
  value       = aws_iam_role.eks_dev_role.arn
}

# ARN of the EKSCICDRole
output "eks_cicd_role_arn" {
  description = "The ARN of the EKSCICDRole, used for CI/CD pipeline access to the EKS cluster"
  value       = aws_iam_role.eks_cicd_role.arn
}

output "eks_admin_group_name" {
  description = "The name of the IAM group for EKS Admins"
  value       = aws_iam_group.eks_admin_group.name
}

output "eks_admin_user_name" {
  description = "The name of the IAM user in the EKS Admin group"
  value       = aws_iam_user.eks_admin_user.name
}

# Access Key ID for the EKS Admin User
output "eks_admin_user_access_key_id" {
  description = "The access key ID for the EKS admin user"
  value       = aws_iam_access_key.eks_admin_user_key.id
}

# Secret Access Key for the EKS Admin User
output "eks_admin_user_secret_access_key" {
  description = "The secret access key for the EKS admin user (sensitive)"
  value       = aws_iam_access_key.eks_admin_user_key.secret
  sensitive   = true
}

output "eks_dev_user_name" {
  description = "The name of the IAM user in the EKS Dev group"
  value       = aws_iam_user.eks_dev_user.name
}

# Access Key ID for the EKS Dev User
output "eks_dev_user_access_key_id" {
  description = "The access key ID for the EKS dev user"
  value       = aws_iam_access_key.eks_dev_user_key.id
}

# Secret Access Key for the EKS dev User
output "eks_dev_user_secret_access_key" {
  description = "The secret access key for the EKS dev user (sensitive)"
  value       = aws_iam_access_key.eks_dev_user_key.secret
  sensitive   = true
}

output "eks_cluster_role_arn" {
  value = aws_iam_role.eks_cluster.arn
}

output "alb_role_arn" {
  value = aws_iam_role.alb_role.arn
}

output "eks_node_group_arn" {
  value = aws_iam_role.eks_node.arn
}

output "eks_cluster_policy" {
  value = aws_iam_role_policy_attachment.eks_cluster_policy
}

output "eks_node_policy" {
  value = aws_iam_role_policy_attachment.eks_node_policy
}

output "eks_cni_policy" {
  value = aws_iam_role_policy_attachment.eks_cni_policy
}
