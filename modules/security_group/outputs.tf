output "eks_nodes_sg_id" {
  description = "ID of the EKS worker node security group"
  value       = aws_security_group.eks_nodes.id
}
