variable "common_tags" {
  description = "Tags used to identify resources provisioned by Terraform in this project."
  type = map(string)
}

variable "cidr_block" {
  description = "CIDR block for your vpc"
  type        = string
  default     = "10.0.0.0/16"
}

variable "AZs" {
  description = "Availability zones which can be accessed by an AWS account within the region configured in the provider"
  type        = list(string)
}

variable "private_subnets" {
  description = "The IPv4 CIDR block for the private subnet."
  type = list(string)
  default = [ "10.0.3.0/24", "10.0.4.0/24" ]
}

variable "public_subnets" {
  description = "The IPv4 CIDR block for the public subnet."
  type = list(string)
  default = [ "10.0.103.0/24", "10.0.104.0/24" ]
}

variable "cluster_name" {
  description = "The name of the EKS cluster, used to authenticate and configure kubectl access."
  type        = string
}