# Assigns the Service Account to pods in kube-system namespace
resource "helm_release" "alb_controller" {
    name = "aws-load-balancer-controller"
    repository = "https://aws.github.io/eks-charts"
    chart = "aws-load-balancer-controller"
    namespace = "kube-system"

    set {
    name  = "clusterName"
    value = var.cluster_name
  }
  set {
    name  = "region"
    value = var.region
  }
  set {
    name  = "vpcId"
    value = var.vpc_id
  }
  set {
    name  = "serviceAccount.create"
    value = "false"                         # Use the existing Service Account
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"  # Matches kubernetes_service_account in kubernetes/
  }
}