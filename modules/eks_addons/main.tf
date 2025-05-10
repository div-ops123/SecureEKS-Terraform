data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
  depends_on = [var.cluster_endpoint] # Ensure cluster is ready
}


module "kubernetes" {
  source = "./kubernetes"
  alb_irsa_arn             = var.alb_irsa_arn
  region                   = var.region
  cluster_name             = data.aws_eks_cluster.cluster.name
  cluster_endpoint         = data.aws_eks_cluster.cluster.endpoint
  node_role_arn            = var.node_role_arn
  devops_learning_irsa_arn = var.devops_learning_irsa_arn
  eks_admin_role_arn       = var.eks_admin_role_arn
  dev_role_arn             = var.dev_role_arn
  cicd_role_arn            = var.cicd_role_arn
  depends_on               = [data.aws_eks_cluster.cluster]
}

module "helm" {
  source           = "./helm"
  vpc_id           = var.vpc_id
  region           = var.region
  cluster_name     = data.aws_eks_cluster.cluster.name
  depends_on       = [data.aws_eks_cluster.cluster]
}