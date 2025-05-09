resource "kubernetes_namespace" "dev" {
  metadata {
    name = "dev"
  }
  depends_on = [ data.aws_eks_cluster.cluster ]
}

resource "kubernetes_namespace" "prod" {
  metadata {
    name = "prod"
  }
  depends_on = [ data.aws_eks_cluster.cluster ]
}