resource "aws_eks_cluster" "main" {
  name = var.cluster_name # Name of the EKS cluster
  role_arn = var.eks_cluster_role_arn  # IAM role the cluster will use (already created)
  vpc_config {
    # subnet_ids defines where the cluster will create the networking components (like control plane ENIs)
    subnet_ids = var.private_subnet_ids
  }
  # Ensure OIDC is enabled
  enabled_cluster_log_types = ["api", "audit"]

  # This ensures the IAM policy is attached BEFORE creating the cluster
  depends_on = [ var.eks_cluster_policy ]
}


# -----------------------------------------------------
# Provision the EKS Node Group (EC2 worker nodes)
# -----------------------------------------------------

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name        # Attach node group to this EKS cluster
  node_group_name = "main"                           # Friendly name for the node group
  node_role_arn   = var.eks_node_group_arn        # EC2 instances will assume this IAM role
  subnet_ids      = var.private_subnet_ids           # Worker nodes will be launched in these subnets (usually private)
  scaling_config {
    desired_size = 2
    min_size = 1
    max_size = 3
  }
  instance_types = [ "t3.medium" ]
  remote_access {
    ec2_ssh_key = var.ssh_key_name
    source_security_group_ids = [var.worker_sg_id]
  }

  # Ensure IAM policies are attached before creating the node group
  depends_on = [ 
    var.eks_cluster_policy,
    var.eks_node_policy,
    var.eks_cni_policy
  ]
}


