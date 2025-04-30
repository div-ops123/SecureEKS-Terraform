variable "common_tags" {
  description = "Tags used to identify resources provisioned by Terraform in this project."
  type = map(string)
  default = {
    Terraform   = "true"
    Project = "eks-clw1"
  }
}

# AWS Account ID
variable "aws_account_id" {
  description = "The AWS account ID where the IAM roles will be created"
  type        = string
}

# EKS Cluster Name
variable "eks_cluster_name" {
  description = "The name of the EKS cluster the roles will interact with"
  type        = string
}

# The arn of the EKS cluster
variable "cluster_arn" {
  description = "The ARN of the EKS cluster."
  type        = string
}

variable "github_org_repo_name" {
  type = string
}

# User to be added to the eks-admin group
variable "eks_admin_user_name" {
  description = "IAM user to be added to eks-admin group"
  type        = string
}
variable "eks_dev_user_name" {
  description = "IAM user to be added to eks-dev group"
  type        = string
}
