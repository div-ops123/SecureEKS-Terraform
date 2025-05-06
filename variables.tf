variable "common_tags" {
  description = "Common tags for resources"
  type        = map(string)
  default     = {
    Terraform   = "true"
    Project     = "SecureEKS"
  }
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "github_org_repo_name" {
  description = "GitHub organization or repo name"
  type        = string
}

variable "aws_root_account" {
  description = "The AWS account for root"
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster, used to authenticate and configure kubectl access."
  type        = string
  default     = "my-first-cluster"
}