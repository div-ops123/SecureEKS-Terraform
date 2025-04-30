# # Define an IAM Role that EKS will assume
# resource "aws_iam_role" "eks_cluster" {
#   name = "EKSClusterRole"  # The name of the IAM role

#   # Define the trust policy that allows EKS to assume this role
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#         {
#             Action = "sts:AssumeRole"  # Allows the specified service to assume this role
#             Effect = "Allow"
#             Principal = {
#                 Service = "eks.amazonaws.com"  # Only the EKS service can assume this role
#             }
#         }
#     ]
#   })
# }

# # Attach the AmazonEKSClusterPolicy to the IAM Role
# # gives the EKS cluster the permissions it needs to create and manage Kubernetes clusters on AWS (like EC2 instances, networking, etc.).
# resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
#   role       = aws_iam_role.eks_cluster.name  # Attach to the role we just created
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"  # AWS-managed policy
# }


resource "aws_eks_cluster" "main" {
  name = "my-first-cluster" # Name of the EKS cluster
  role_arn = var.eks_cluster_role_arn  # IAM role the cluster will use (already created)
  vpc_config {
    # subnet_ids defines where the cluster will create the networking components (like control plane ENIs)
    subnet_ids = var.private_subnet_ids  # <-- You'll pass this from root module by reading VPC module output
  }

  # This ensures the IAM policy is attached BEFORE creating the cluster
  depends_on = [ var.eks_cluster_policy ]
}


# # -----------------------------------------------------
# # IAM Role for EC2 instances (EKS worker nodes)
# # This allows EC2 to assume a role and interact with AWS services securely.
# # Needs to be mapped in `aws-auth` so that nodes can register.
# # -----------------------------------------------------
# resource "aws_iam_role" "eks_node" {
#   name = "EKSNodeRole"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# # -----------------------------------------------------
# # Attach necessary IAM policies to the EC2 worker node role
# # -----------------------------------------------------

# # Allows the worker nodes to join the EKS cluster, register themselves, and interact with AWS Services
# resource "aws_iam_role_policy_attachment" "eks_node_policy" {
#   role = aws_iam_role.eks_node.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
# }

# # Enables the worker nodes to use the Amazon VPC CNI plugin for pod networking
# resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
#   role = aws_iam_role.eks_node.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
# }

# # Enables the worker nodes to pull container images from Amazon ECR
# resource "aws_iam_role_policy_attachment" "eks_ecr_readonly" {
#   role       = aws_iam_role.eks_node.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
# }


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


