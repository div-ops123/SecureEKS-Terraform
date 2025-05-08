# The name of the EKS cluster
variable "cluster_name" {
  description = "The name of the EKS cluster, used to authenticate and configure kubectl access."
  type        = string
}

# The API server endpoint of the EKS cluster
variable "cluster_endpoint" {
  description = "The endpoint of the EKS cluster used by the Kubernetes provider to connect to the cluster."
  type        = string
}

# The base64-encoded CA certificate for connecting securely to the EKS cluster
variable "cluster_ca" {
  description = "The base64-encoded certificate authority data required to establish secure communication with the EKS API server."
  type        = string
}

variable "alb_irsa_arn" {}
variable "node_role_arn" {}
variable "ascp_irsa_arn" {}
variable "devops_learning_irsa_arn" {}
variable "eks_admin_role_arn" {}
variable "cluster_arn" {}
variable "dev_role_arn" {}
variable "cicd_role_arn" {}
variable "region" {}
variable "vpc_id" {}