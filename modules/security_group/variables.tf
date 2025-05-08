variable "vpc_id" {
  description = "The VPC ID to associate with the security group"
  type        = string
}

variable "common_tags" {
  description = "Tags used to identify resources provisioned by Terraform in this project."
  type = map(string)
}

# You can usually set cluster_control_plane_cidr to "0.0.0.0/0" to make it open if you're unsure or let AWS handle it (less secure), or use the specific CIDR given in EKS console → Networking tab.
variable "cluster_control_plane_cidr" {
  description = "The CIDR block of the EKS control plane (retrieved from AWS docs or EKS settings)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "cluster_name" {
  description = "The name of the EKS cluster, used to authenticate and configure kubectl access."
  type        = string
}