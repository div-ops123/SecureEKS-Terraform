# -----------------------IAM User and Group------------------------
# Create IAM user
resource "aws_iam_user" "eks_admin_user" {
  name = var.eks_admin_user_name
}

# Create access key for the IAM user to enable programmatic access
resource "aws_iam_access_key" "eks_admin_user_key" {
  user = aws_iam_user.eks_admin_user.name
}

# Create IAM group for EKS Admins
resource "aws_iam_group" "eks_admin_group" {
  name = "eks-admins"
}

# Add user to eks-admin group
resource "aws_iam_group_membership" "eks_admin_group_membership" {
  name = "${aws_iam_group.eks_admin_group.name}-membership"
  users = [aws_iam_user.eks_admin_user.name]
  group = aws_iam_group.eks_admin_group.name
}

# Inline policy to allow assuming the EKSAdminRole
resource "aws_iam_group_policy" "eks_admin_assume_role_policy" {
  name = "AssumeEKSAdminRole"
  group = aws_iam_group.eks_admin_group.name
 
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowAssumeEKSAdminRole",
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Resource = aws_iam_role.eks_admin_role.arn
      }
    ]
  })
}

# Create IAM group for developers Admins
resource "aws_iam_group" "eks_dev_group" {
  name = "developers"
}

resource "aws_iam_user" "eks_dev_user" {
  name = var.eks_dev_user_name
}

resource "aws_iam_access_key" "eks_dev_user_key" {
  user = aws_iam_user.eks_dev_user.name
}

resource "aws_iam_group_membership" "eks_dev_group_membership" {
  name = "${aws_iam_group.eks_dev_group.name}-membership"
  users = [ aws_iam_user.eks_dev_user.name ]
  group = aws_iam_group.eks_dev_group.name
}

# policy to assume EKSDevRole
resource "aws_iam_group_policy" "developers_assume_role_policy" {
  name = "AssumeEKSDevRole"
  group = aws_iam_group.eks_dev_group.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowAssumeEKSDevRole"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = aws_iam_role.eks_dev_role.arn
      }
    ]
  })
}


# -----------------------IAM Roles------------------------
# Fetch EKS cluster OIDC issuer URL, required for IRSA.
data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name
  depends_on = [ var.cluster_arn ]  # ensures the eks cluster is created first.
}

# Congiure eks cluster with an OIDC to authenticate service account
resource "aws_iam_openid_connect_provider" "eks_oidc" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]
  # For production, manually retrieve and verify the thumbprint to ensure security. For now skip
  # Automate Thumbprint Retrieval using scripts
  # https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html
  thumbprint_list = []  # Not required for EKS; AWS manages it
}


# IAM policy for ALB Controller
# Or download here: curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json
resource "aws_iam_policy" "alb_controller_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "Policy for AWS Load Balancer Controller to manage ALBs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.eks_cluster_name}" = "false"
          }
        }
      },
      # Add other permissions from iam-policy.json (abridged for brevity)
      {
        Effect = "Allow"
        Action = [
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "acm:GetCertificate",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:Describe*",
          "elasticloadbalancing:*",
          "iam:CreateServiceLinkedRole",
          "waf-regional:*",
          "wafv2:*",
          "shield:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role for IRSA (AWS Load Balancer Controller)
resource "aws_iam_role" "alb_irsa" {
  name        = "${var.eks_cluster_name}-alb-controller-irsa"
  description = "IAM Role for AWS Load Balancer Controller ServiceAccount to manage ALBs"

  # IRSA trust policy specifig who can assume role. In our case the ALB controller's service account
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        # Allows the eks OIDC provider to assume this role        
        Principal = {
          Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        # On behalf of `aws-load-balancer-controller-sa` service account
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller-sa"
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name    = "EKSALBIRSARole"
    Purpose = "ALB Access for EKS cluster ALB Controller"
  })
}

# Attach the ALB Controller Policy to the IRSA Role
resource "aws_iam_role_policy_attachment" "alb_role_policy" {
  role       = aws_iam_role.alb_irsa.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}


# --- START ---
# IAM Policy for Parameter Store Access
resource "aws_iam_policy" "parameter_store_policy" {
  name = "DevopsLearningParameterStorePolicy"
  description = "Policy for accessing Parameter Store parameters for DevOps Learning app"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/devops-learning/*"        
      }
    ]
  })
}

# IAM Role for IRSA (Parameter Store Access) - Defines who can assume this role
resource "aws_iam_role" "devops_learning_irsa" {
  name = "${var.eks_cluster_name}-devops-learning-irsa"
  description = "IAM Role for DevOps Learning ASCP ServiceAccount to access Parameter Store"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        # Allows the eks OIDC provider to assume this role
        Principal = {
          Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        # On behalf of `secrets-provider-aws-sa` service account
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:secrets-provider-aws-sa"
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name    = "DevopsLearningIRSARole"
    Purpose = "Parameter Store Access for DevOps Learning ASCP"
  })
}

# Attach the Parameter Store Policy to the IRSA Role
resource "aws_iam_role_policy_attachment" "devops_learning_irsa_policy" {
  role = aws_iam_role.devops_learning_irsa.name
  policy_arn = aws_iam_policy.parameter_store_policy.arn
}
# --- END ---


# IAM Role for EKS Admins (EKSAdminRole)
resource "aws_iam_role" "eks_admin_role" {
  depends_on = [ aws_iam_group.eks_admin_group ]

  name = "EKSAdminRole"
  description = "IAM role for EKS cluster administrators"

  # Trust policy allowing the eks-admins group to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = var.aws_root_account
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.common_tags, {
    Name = "EKSAdminRole"
    Purpose = "EKS Cluster Admin Access"
  })
}

# Inline policy for eks:AccessKubernetesApi permission
resource "aws_iam_role_policy" "eks_admin_access" {
  name   = "EKSAccessPolicy"
  role   = aws_iam_role.eks_admin_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["eks:AccessKubernetesApi", "eks:DescribeCluster"]
        Resource = var.cluster_arn
      }
    ]
  })
}

# Attach AmazonEKSClusterPolicy to EKSAdminRole
resource "aws_iam_role_policy_attachment" "eks_admin_cluster_policy" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


# IAM Role for Developers (EKSDevRole)
resource "aws_iam_role" "eks_dev_role" {
  depends_on  = [ aws_iam_group.eks_dev_group ]
  name        = "EKSDevRole"
  description = "This role will be assumed by developers in my account to interact with the EKS cluster with limited access"

  # Trust policy allowing the account root to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.aws_root_account
        }
        Action = "sts:AssumeRole"
        Condition = {}
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "EKSDevRole"
    Purpose = "EKS Developer Access"
  })
}

# custom policy including only eks:AccessKubernetesApi and eks:DescribeCluster for least privilege
resource "aws_iam_role_policy" "eks_dev_custom_policy" {
  name   = "EKSCustomPolicy"
  role   = aws_iam_role.eks_dev_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [ "eks:DescribeCluster", "eks:AccessKubernetesApi" ]
        Resource = [var.cluster_arn]
      }
    ]
  })
}


# IAM Role for CI/CD Pipelines (EKSCICDRole)
resource "aws_iam_role" "eks_cicd_role" {
  name        = "EKSCICDRole"
  description = "CI/CD Pipelines access to EKS Cluster, e.g., GitHub Actions OIDC for CI/CD"

  # Trust policy allowing GitHub Actions OIDC provider to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # Ensure the GitHub OIDC provider (arn:aws:iam::140023408689:oidc-provider/token.actions.githubusercontent.com) is configured in AWS IAM
          # Federated = "arn:aws:iam::140023408689:oidc-provider/token.actions.githubusercontent.com"
          Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = var.github_org_repo_name
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "EKSCICDRole"
    Purpose = "EKS CI/CD Access"
  })
}

# Inline policy for eks:AccessKubernetesApi permission
resource "aws_iam_role_policy" "eks_cicd_access" {
  name   = "EKSAccessPolicy"
  role   = aws_iam_role.eks_cicd_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["eks:AccessKubernetesApi", "eks:DescribeCluster"]
        Resource = var.cluster_arn
      }
    ]
  })
}

# Attach AmazonEC2ContainerRegistryFullAccess to EKSCICDRole
resource "aws_iam_role_policy_attachment" "eks_cicd_ecr_full_access" {
  role       = aws_iam_role.eks_cicd_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

# Attach AmazonEKSClusterPolicy to EKSCICDRole
resource "aws_iam_role_policy_attachment" "eks_cicd_cluster_policy" {
  role       = aws_iam_role.eks_cicd_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


# IAM Role that EKS will assume
resource "aws_iam_role" "eks_cluster" {
  name = "EKSClusterRole"  # The name of the IAM role

  # Define the trust policy that allows EKS to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Action = "sts:AssumeRole"  # Allows the specified service to assume this role
            Effect = "Allow"
            Principal = {
                Service = "eks.amazonaws.com"  # Only the EKS service can assume this role
            }
        }
    ]
  })
}

# Attach the AmazonEKSClusterPolicy to the IAM Role
# gives the EKS cluster the permissions it needs to create and manage Kubernetes clusters on AWS (like EC2 instances, networking, etc.).
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name  # Attach to the role we just created
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"  # AWS-managed policy
}


# -----------------------------------------------------
# IAM Role for EC2 instances (EKS worker nodes)
# This allows EC2 to assume a role and interact with AWS services securely.
# Needs to be mapped in `aws-auth` so that nodes can register.
# -----------------------------------------------------
resource "aws_iam_role" "eks_node" {
  name = "EKSNodeRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# -----------------------------------------------------
# Attach necessary IAM policies to the EC2 worker node role
# -----------------------------------------------------

# Allows the worker nodes to join the EKS cluster, register themselves, and interact with AWS Services
resource "aws_iam_role_policy_attachment" "eks_node_policy" {
  role = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Enables the worker nodes to use the Amazon VPC CNI plugin for pod networking
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Enables the worker nodes to pull container images from Amazon ECR
resource "aws_iam_role_policy_attachment" "eks_ecr_readonly" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}