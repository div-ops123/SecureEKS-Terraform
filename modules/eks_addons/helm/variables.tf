# The name of the EKS cluster
variable "cluster_name" {
  description = "The name of the EKS cluster, used to authenticate and configure kubectl access."
  type        = string
}

variable "cluster_endpoint" {
  description = "The endpoint of the EKS cluster used by the Kubernetes provider to connect to the cluster."
  type        = string
}

# variable "ascp_service_account" {}
variable "region" {}
variable "vpc_id" {}