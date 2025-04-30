data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "./modules/vpc"

  # Optionally override variables if needed
  AZs    = data.aws_availability_zones.available.names
}

module "sg" {
  source = "./modules/security_group"

  # Optionally override variables if needed
  vpc_id = module.vpc.vpc_id
}

module "eks" {
  source               = "./modules/eks"

  # Optionally override variables if needed
  private_subnet_ids   = module.vpc.private_subnets
  worker_sg_id         = module.sg.eks_nodes_sg_id
  eks_cluster_role_arn = module.iam.eks_cluster_role_arn
  eks_node_group_arn   = module.iam.eks_node_group_arn
  eks_node_policy      = module.iam.eks_node_policy
  eks_cluster_policy   = module.iam.eks_cluster_policy
  eks_cni_policy       = module.iam.eks_cni_policy
}

module "iam" {
  source               = "./modules/iam"

  # Optionally override variables if needed
  eks_cluster_name     = module.eks.cluster_name
  cluster_arn          = module.eks.cluster_arn
  aws_account_id       = var.aws_account_id
  github_org_repo_name = var.github_org_repo_name
  eks_admin_user_name  = "daniel"
  eks_dev_user_name    = "mathins"
}


# Without eks_admin module, AWS EKS automatically grants full admin access (system:masters) to the IAM entity that created the cluster
# UUNCOMMENT this only when you want to give admin access to additional iam principal
module "eks_admin" {
  source                          = "./modules/eks_admin"

  # Optionally override variables if needed
  cluster_name                    = module.eks.cluster_name
  cluster_arn                     = module.eks.cluster_arn
  cluster_endpoint                = module.eks.cluster_endpoint
  cluster_ca                      = module.eks.cluster_ca_certificate
  node_role_arn                   = module.iam.eks_node_group_arn
  eks_admin_role_arn              = module.iam.eks_admin_role_arn
  dev_role_arn                    = module.iam.eks_dev_role_arn
  cicd_role_arn                   = module.iam.eks_cicd_role_arn
}

