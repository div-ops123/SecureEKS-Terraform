resource "aws_security_group" "eks_nodes" {
  name        = "eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id
  tags        = merge(var.common_tags, {Name = "eks-node-sg"})
}


# Allow control plane -> worker nodes (for kubelet / webhook)
resource "aws_vpc_security_group_ingress_rule" "from_control_plane" {
  security_group_id = aws_security_group.eks_nodes.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.cluster_control_plane_cidr
  description       = "Worker nodes Allow inbound traffic from EKS control plane"
}

# Allow node-to-node traffic for Kubernetes (typical range: 1025–65535)
resource "aws_vpc_security_group_ingress_rule" "node_to_node" {
  security_group_id = aws_security_group.eks_nodes.id # Destination
  from_port         = 1025
  to_port           = 65535
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"                     # Source (from anywhere to sg_id)
  description       = "Allow communication between worker nodes"
}

# Access apps on this port range(30000-32767)
resource "aws_vpc_security_group_ingress_rule" "nodeport_access" {
  security_group_id = aws_security_group.eks_nodes.id
  from_port         = 30000
  to_port           = 32767
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow NodePort traffic to worker nodes"
}

# Allow HTTPS for image pulls etc.
resource "aws_vpc_security_group_egress_rule" "https_outbound" {
  security_group_id = aws_security_group.eks_nodes.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow outbound HTTPS for pulling images"
}

# Allow DNS and other egress (optional but common)
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.eks_nodes.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound traffic"
}
