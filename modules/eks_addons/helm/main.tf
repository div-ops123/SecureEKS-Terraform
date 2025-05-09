data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = ">= 2.15.0"
    }
  }
}

# Installs the AWS Load Balancer Controller on your EKS cluster to manage ALBs for Ingress traffic routing
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"   # Deploys the controller in the kube-system namespace

  set {
    name = "rbac.create"
    value = "true"
  }
  set {
    name  = "clusterName"
    value = data.aws_eks_cluster.cluster.name
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
    value = "aws-load-balancer-controller-sa"  # Matches kubernetes_service_account in kubernetes/
  }
  depends_on = [data.aws_eks_cluster.cluster]
}


# --- To sync Parameter Store to the Secret, use ASCP ---
# Fargate node groups are not supported.
# Requirement: Secrets Store CSI driver installed. ref: https://github.com/kubernetes-sigs/secrets-store-csi-driver/releases
# Allows Kubernetes mouth secrets in pods as volumes(files)
resource "helm_release" "csi_secrets_store" {
  name       = "csi-secrets-store"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  namespace  = "kube-system"
  version    = "1.5.0"  # Use a specific version for stability

  # Configure cluster name for context
  set {
    name  = "clusterName"
    value = data.aws_eks_cluster.cluster.name
  }

  # Enable sync of secrets to Kubernetes Secrets
  set {
    name  = "syncSecret.enabled"
    value = "true"
  }

  # Configure throttling to manage API rate limits
  set {
    name  = "k8sThrottlingParams"
    value = jsonencode({
      qps   = 50  # Queries per second
      burst = 100 # Burst limit
    })
  }

  # Ensure the Helm release depends on the EKS cluster and Kubernetes provider
  depends_on = [data.aws_eks_cluster.cluster]
}


# Install the (ASCP) to fetch secrets/parameters from AWS Secrets Manager and Parameter Store.
resource "helm_release" "secrets_provider_aws" {
  name       = "secrets-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"
  version    = "1.0.1"  # Use a specific version (check latest at https://github.com/aws/secrets-store-csi-driver-provider-aws/releases)

  # Use the chart default RBAC
  set {
    name = "rbac.create"
    value = "true"
  }

  # Configure cluster name for context
  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  # Use the existing Service Account
  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "secrets-provider-aws-sa"
  }

  # Ensure ASCP depends on the CSI Driver
  depends_on = [
    helm_release.csi_secrets_store,
    data.aws_eks_cluster.cluster
  ]
}