variable "cluster_name" {}
variable "vpc_id" {}
variable "private_subnet_ids" { type = list(string) }
variable "eks_nodes_sg_id" {}
variable "rds_security_group_id" {}
variable "instance_class" {}
variable "allocated_storage" {}
variable "db_name" {}
variable "db_username" { sensitive = true }
variable "db_password" { sensitive = true }

variable "common_tags" {
  description = "Tags used to identify resources provisioned by Terraform in this project."
  type = map(string)
}