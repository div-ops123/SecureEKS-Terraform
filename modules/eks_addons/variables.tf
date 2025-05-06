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
