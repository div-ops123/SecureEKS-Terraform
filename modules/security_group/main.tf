resource "aws_security_group" "eks_nodes" {
  name        = "${var.cluster_name}-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id
  tags        = merge(var.common_tags, {Name = "${var.cluster_name}-sg"})
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id
  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-sg"
      "elbv2.k8s.aws/cluster" = var.cluster_name  # Auto-detection by ALB Controller
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )
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

resource "aws_vpc_security_group_ingress_rule" "node_from_alb" {
  security_group_id            = aws_security_group.eks_nodes.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb_sg.id
  description                  = "Allow ALB to node traffic"
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


# alb controller sg

# inbound 80/443 traffic
resource "aws_vpc_security_group_ingress_rule" "alb_http_access" {
  security_group_id = aws_security_group.alb_sg.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow HTTP traffic to ALB"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_access" {
  security_group_id = aws_security_group.alb_sg.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow HTTPS traffic to ALB"
}

resource "aws_vpc_security_group_egress_rule" "alb_all_outbound" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound traffic"
}


# RDS sg
resource "aws_security_group" "rds_security_group" {
  name = "${var.cluster_name}-rds-sg"
  description = "Allows EKS worker nodes to access RDS on port 5432"
  vpc_id = var.vpc_id
  tags = merge(var.common_tags, { Name = "${var.cluster_name}-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "worker_nodes_to_rds" {
  security_group_id = aws_security_group.rds_security_group.id
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id
  description = "Allows EKS worker nodes to access RDS on port 5432"
}

resource "aws_vpc_security_group_egress_rule" "rds_engress" {
  security_group_id = aws_security_group.rds_security_group.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description = "Allow rds to send traffic to anywhere"
}