variable "private_subnet_ids" {
  type = list(string)
}

variable "worker_sg_id" {
  description = "Security Group ID for the worker nodes"
  type        = string
}

variable "ssh_key_name" {
  description = "Name of the EC2 key pair to enable SSH access to worker nodes"
  type        = string
  default     = "ubuntu-vm"
}

variable "eks_cluster_role_arn" {
  type = string
}

variable "eks_cluster_policy" {}
variable "eks_node_group_arn" {}
variable "eks_node_policy" {}
variable "eks_cni_policy" {}