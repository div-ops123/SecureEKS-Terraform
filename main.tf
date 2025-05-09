data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_eks_cluster" "cluster" {
  name       = var.cluster_name
  depends_on = [module.eks]  # Depend on the entire eks module
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--region", var.aws_region, "--cluster-name", data.aws_eks_cluster.cluster.name] # Auth via AWS CLI
  }
}


provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--region", var.aws_region, "--cluster-name", data.aws_eks_cluster.cluster.name] # Auth via AWS CLI
    }
  }
}


module "vpc" {
  source = "./modules/vpc"

  # Optionally override variables if needed
  AZs           = data.aws_availability_zones.available.names
  cluster_name  = var.cluster_name
  common_tags   = var.common_tags
}

module "sg" {
  source = "./modules/security_group"

  # Optionally override variables if needed
  vpc_id       = module.vpc.vpc_id
  cluster_name = var.cluster_name
  common_tags  = var.common_tags
}

module "eks" {
  source               = "./modules/eks"

  # Optionally override variables if needed
  cluster_name = var.cluster_name
  private_subnet_ids   = module.vpc.private_subnets_ids
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
  aws_root_account     = var.aws_root_account 
  github_org_repo_name = var.github_org_repo_name
  eks_admin_user_name  = "daniel"
  eks_dev_user_name    = "mathins"
  aws_region           = var.aws_region
  common_tags          = var.common_tags
}


module "rds" {
  source                = "./modules/rds"
  cluster_name          = var.cluster_name
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnets_ids
  eks_nodes_sg_id       = module.sg.eks_nodes_sg_id
  rds_security_group_id = module.sg.rds_security_group_id
  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  db_username           = var.db_username
  db_password           = var.db_password
  db_name               = var.db_name
  common_tags           = var.common_tags
}

module "ssm" {
  source       = "./modules/ssm"
  db_username  = var.db_username
  db_password  = var.db_password
  db_name      = "devops_learning"
  secret_key   = var.secret_key
  rds_endpoint = module.rds.rds_endpoint
}


module "kubernetes" {
  source                    = "./modules/eks_addons/kubernetes"  
  providers = {
    kubernetes = kubernetes
  }

  cluster_name              = module.eks.cluster_name
  region                    = var.aws_region
  cluster_endpoint          = data.aws_eks_cluster.cluster.endpoint
  node_role_arn             = module.iam.eks_node_group_arn
  eks_admin_role_arn        = module.iam.eks_admin_role_arn
  dev_role_arn              = module.iam.eks_dev_role_arn
  cicd_role_arn             = module.iam.eks_cicd_role_arn
  alb_irsa_arn              = module.iam.alb_irsa_arn
  devops_learning_irsa_arn  = module.iam.devops_learning_irsa_arn
  depends_on                = [module.eks]
}

module "helm" {
  source               = "./modules/eks_addons/helm"
  providers = {
    helm = helm
  }

  cluster_name         = module.eks.cluster_name
  vpc_id               = module.vpc.vpc_id
  region               = var.aws_region
  depends_on           = [module.eks, module.kubernetes]
}
