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

variable "aws_region" {
  default = "af-south-1"
}

variable "instance_class" { default = "db.t3.micro" }
variable "allocated_storage" { default = 20 }

variable "db_name" { default = "devops_learning" }
variable "db_username" { sensitive = true }
variable "db_password" { sensitive = true }
variable "secret_key" { sensitive = true }