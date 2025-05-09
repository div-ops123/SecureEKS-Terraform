# The name of the EKS cluster
variable "cluster_name" {
  description = "The name of the EKS cluster, used to authenticate and configure kubectl access."
  type        = string
}

variable "region" {
  type = string
}

# The API server endpoint of the EKS cluster
variable "cluster_endpoint" {
  description = "The endpoint of the EKS cluster used by the Kubernetes provider to connect to the cluster."
  type        = string
}

# The base64-encoded CA certificate for connecting securely to the EKS cluster
# variable "cluster_ca" {
#   description = "The base64-encoded certificate authority data required to establish secure communication with the EKS API server."
#   type        = string
# }

# The IAM role ARN used by the EKS worker nodes (for aws-auth ConfigMap)
variable "node_role_arn" {
  description = "The ARN of the IAM role used by the EKS worker nodes, which is required for adding them to the aws-auth ConfigMap."
  type        = string
}

# IAM Role ARN for EKS Admins
variable "eks_admin_role_arn" {
  description = "The ARN of the IAM role for EKS cluster administrators"
  type        = string
}

variable "dev_role_arn" {
  description = "The ARN of the IAM role used by developers, to get access to EKS cluster."
  type        = string
}

variable "cicd_role_arn" {
  description = "The ARN of the IAM role used by CI/CD tools, to get access to EKS cluster."
  type        = string
}

variable "alb_irsa_arn" {
  description = "The IRSA ARN with permissions to manage ALB."
  type        = string
}

variable "devops_learning_irsa_arn" {
  description = "The IRSA ARN with permissions to read Parameter Store parameters."
  type        = string
}
