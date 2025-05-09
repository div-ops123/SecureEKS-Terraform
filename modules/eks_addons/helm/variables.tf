# The name of the EKS cluster
variable "cluster_name" {
  description = "The name of the EKS cluster, used to authenticate and configure kubectl access."
  type        = string
}

variable "region" {}
variable "vpc_id" {}