output "eks_nodes_sg_id" {
  description = "ID of the EKS worker node security group"
  value       = aws_security_group.eks_nodes.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds_security_group.id
}
