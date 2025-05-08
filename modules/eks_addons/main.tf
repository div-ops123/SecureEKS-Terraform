# Configure Kubernetes provider using EKS outputs
provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name] # Auth via AWS CLI
  }
}


module "kubernetes" {
  source = "./kubernetes"
  alb_irsa_arn             = var.alb_irsa_arn
  cluster_ca               = var.cluster_ca
  cluster_name             = var.cluster_name
  cluster_arn              = var.cluster_arn
  cluster_endpoint         = var.cluster_endpoint
  node_role_arn            = var.node_role_arn
  devops_learning_irsa_arn = var.devops_learning_irsa_arn
  eks_admin_role_arn       = var.eks_admin_role_arn
  dev_role_arn             = var.dev_role_arn
  cicd_role_arn            = var.cicd_role_arn
}

module "helm" {
  source           = "./helm"
  vpc_id           = var.vpc_id
  region           = var.region
  cluster_name     = var.cluster_name
  cluster_endpoint = var.cluster_endpoint
}