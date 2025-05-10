# --- RBAC roles and Service Accounts ---
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
  depends_on = [var.cluster_endpoint] # Ensure cluster is ready
}

terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.36.0"
    }
  }
}

# Service Accounnts with IRSA

# The `aws-load-balancer-controller-sa` Service Account is used by the ALB Controller pods to assume the IAM role via IRSA and manage ALBs.
resource "kubernetes_service_account" "alb_controller_service_account" {
  metadata {
    name      = "aws-load-balancer-controller-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = var.alb_irsa_arn
    }
  }
  depends_on = [data.aws_eks_cluster.cluster]
}

# Service Account for ASCP to assume IAM IRSA to access AWS Parameter Store
resource "kubernetes_service_account" "secrets_provider_aws" {
  metadata {
    name      = "secrets-provider-aws-sa"
    namespace = "kube-system"
    # links `secrets-provider-aws-sa` to an IAM role with permissions for Parameter Store
    annotations = {
      "eks.amazonaws.com/role-arn" = var.devops_learning_irsa_arn
    }
  }

  # Ensure the Service Account is created before Helm releases
  depends_on = [data.aws_eks_cluster.cluster]
}


# ----------
# RBAC Roles: Is your way of custom-controlling who gets access to the EKS cluster via IAM.

# RBAC for AWS Load Balancer Controller
# Defines a ClusterRole named "aws-load-balancer-controller" to grant permissions needed by the AWS Load Balancer Controller.
resource "kubernetes_cluster_role" "alb_controller" {
  metadata {
    name = "aws-load-balancer-controller" # Name of the ClusterRole, matching the expected name by the Helm chart.
  }

  # Rule 1: Allows the controller to read (get, list, watch) Ingresses, Services, Pods, and Nodes.
  # This enables the controller to discover Ingresses and Services to create ALBs and query Pods/Nodes for routing.
  rule {
    api_groups = ["", "extensions", "networking.k8s.io"]  # Covers core API (""), legacy extensions, and networking.k8s.io APIs.
    resources  = [ "ingresses", "services", "pods", "nodes" ]  # Resources the controller needs to manage or query.
    verbs      = [ "get", "list", "watch" ]  # Read-only operations for monitoring and discovery.
  }

  # Rule 2: Allows the controller to update the status of Ingress resources.
  # This is needed to report the ALB's DNS name back to the Ingress status.
  rule {
    api_groups = ["", "extensions", "networking.k8s.io"]  # Same API groups for Ingress.
    resources  = [ "ingresses/status" ]  # Specifically the status subresource of Ingresses.
    verbs      = [ "update" ]  # Allows updating the Ingress status.
  }

  # Ensures the EKS cluster is provisioned before creating the ClusterRole.
  depends_on = [data.aws_eks_cluster.cluster]
}

# Binds the aws-load-balancer-controller ClusterRole to the aws-load-balancer-controller-sa ServiceAccount.
# This grants the permissions defined in the ClusterRole to the ServiceAccount used by the controller's pods.
resource "kubernetes_cluster_role_binding" "alb_controller" {
  metadata {
    name = "aws-load-balancer-controller-binding"  # Name of the ClusterRoleBinding.
  }

  # References the ClusterRole created above.
  role_ref {
    api_group = "rbac.authorization.k8s.io"  # RBAC API group.
    kind      = "ClusterRole"  # Type of role being referenced.
    name      = kubernetes_cluster_role.alb_controller.metadata[0].name  # Links to the alb_controller ClusterRole.
  }

  # Specifies the ServiceAccount that will receive the permissions.
  subject {
    kind = "ServiceAccount"  # Type of subject.
    name = kubernetes_service_account.alb_controller_service_account.metadata[0].name  # Name of the ServiceAccount created in kubernetes_service_account.alb_controller_service_account.
    namespace = kubernetes_service_account.alb_controller_service_account.metadata[0].namespace  # Namespace where the ServiceAccount resides.
  }

  # Ensures the EKS cluster is ready before creating the binding.
  depends_on = [data.aws_eks_cluster.cluster]
}


# RBAC for AWS Secrets Store CSI Driver Provider (ASCP)
# Defines a ClusterRole named "secrets-provider-aws-role" to grant permissions needed by ASCP.
resource "kubernetes_cluster_role" "secrets_provider_aws" {
  metadata {
    name = "secrets-provider-aws-role"  # Name of the ClusterRole, matching the expected name by the ASCP Helm chart.
  }

  # Rule 1: Allows ASCP to read (get, list) Pods and Nodes.
  # Needed to identify pods requesting secrets and node information for secret mounting.
  rule {
    api_groups = [ "" ]  # Core Kubernetes API group.
    resources  = [ "pods", "nodes" ]  # Resources ASCP needs to query.
    verbs      = [ "get", "list" ]  # Read-only operations.
  }

  # Rule 2: Allows ASCP to read and watch SecretProviderClasses.
  # Needed to process SecretProviderClass resources (e.g., devops-learning-secrets) for fetching secrets from AWS.
  rule {
    api_groups = [ "secrets-store.csi.x-k8s.io" ]  # Custom API group for Secrets Store CSI Driver.
    resources  = [ "secretproviderclasses" ]  # Custom resource defining secret sources.
    verbs      = [ "get", "list", "watch" ]  # Read and monitor SecretProviderClasses.
  }

  # Ensures the EKS cluster is provisioned before creating the ClusterRole.
  depends_on = [data.aws_eks_cluster.cluster]
}

# Binds the secrets-provider-aws-role ClusterRole to the secrets-provider-aws-sa ServiceAccount.
# This grants the permissions defined in the ClusterRole to the ServiceAccount used by ASCP pods.
resource "kubernetes_cluster_role_binding" "secrets_provider_aws" {
  metadata {
    name = "secrets-provider-aws-binding"  # Name of the ClusterRoleBinding.
  }

  # References the ClusterRole created above.
  role_ref {
    api_group = "rbac.authorization.k8s.io"  # RBAC API group.
    kind      = "ClusterRole"  # Type of role being referenced.
    name      = kubernetes_cluster_role.secrets_provider_aws.metadata[0].name  # Links to the secrets_provider_aws ClusterRole.
  }

  subject {
    kind = "ServiceAccount"  # Type of subject.
    name = kubernetes_service_account.secrets_provider_aws.metadata[0].name  # Name of the ServiceAccount created in kubernetes_service_account.ascp_service_account.
    namespace = kubernetes_service_account.secrets_provider_aws.metadata[0].namespace  # Namespace where the ServiceAccount resides.
  }

  # Ensures the EKS cluster is ready before creating the binding.
  depends_on = [data.aws_eks_cluster.cluster]
}



# Map IAM roles to Kubernetes users/groups in the aws-auth ConfigMap
# resource "kubernetes_config_map" "aws_auth" {
resource "kubernetes_config_map_v1_data" "aws_auth_patch" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapRoles = yamlencode([
      {
        rolearn  = var.node_role_arn                    # IAM Role for worker nodes
        username = "system:node:{{EC2PrivateDNSName}}"  # Templated name for worker nodes(ec2) joining the cluster
        groups   = ["system:bootstrappers", "system:nodes"]
      },
      {
        rolearn  = var.eks_admin_role_arn               # IAM Principal to assign eks permission to
        username = "eks-admin"                          # Name kubernetes gives to this IAM Principal
        groups   = ["system:masters"]                   # system:masters implicitly provides cluster-admin privileges
      },
      {
        rolearn = var.dev_role_arn
        username = "developer"                          # How Kubernetes will refer to this IAM role
        groups   = ["dev-viewers"]                      # The RBAC group to assign inside the cluster. Read-only for developers
      },
      {
        rolearn = var.cicd_role_arn
        username = "cicd"                               # How Kubernetes will refer to this IAM role
        groups   = ["prod-editors"]                     # The RBAC group to assign inside the cluster. Edit for DevOps
      }
    ])
  }
  force = true
  depends_on = [data.aws_eks_cluster.cluster]
}


# Optional: Bind the "system:masters" group to the cluster-admin role
# Optional because in EKS, system:masters is implicitly treated as cluster-admin.
resource "kubernetes_cluster_role_binding" "admin" {
  metadata {
    name = "admin-binding"                    # Name of the binding
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"                 # References the predefined `cluster-admin` ClusterRole, which is a built-in Kubernetes role.
    name      = "cluster-admin"               # This is the highest privilege role in Kubernetes
  }
  
  # This tells Kubernetes: “If a user belongs to system:masters, give them the cluster-admin role, which is full power over the cluster.”
  subject {
    kind      = "Group"
    name      = "system:masters"              # This is the group our IAM role was mapped to via aws-auth
    api_group = "rbac.authorization.k8s.io"
  }
  depends_on = [data.aws_eks_cluster.cluster]
}


# Prod Namespace - CI/CD (edit access)
resource "kubernetes_role_binding" "prod_editors" {
  # Ensure namespace is created before binding
  depends_on = [ kubernetes_namespace.prod, data.aws_eks_cluster.cluster ]

  metadata {
    name      = "prod-editors-binding"     # Binding name
    namespace = kubernetes_namespace.prod.metadata[0].name  # Prod namespace only
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"              # References the predefined `edit` ClusterRole, which is a built-in Kubernetes role.
    name      = "edit"                     # Predefined cluster role that allows read/write access
  }

  # Connects the RBAC permission to your IAM role via the mapped group in aws-auth.
  subject {
    kind      = "Group"
    name      = "prod-editors"             # Group mapped in aws-auth
    api_group = "rbac.authorization.k8s.io"
  }
}


# Dev Namespace - Developers (read-only)
resource "kubernetes_role_binding" "dev_viewers" {
  # Ensure namespace is created before binding
  depends_on = [ data.aws_eks_cluster.cluster, kubernetes_namespace.dev ]

  metadata {
    name      = "dev-viewers-binding"      # Binding name
    namespace = kubernetes_namespace.dev.metadata[0].name  # Dev namespace only, created in namespaces.tf
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"              # References the predefined `view` ClusterRole, which is a built-in Kubernetes role.
    name      = "view"                     # Predefined cluster role that allows read-only access
  }

  subject {
    kind      = "Group"
    name      = "dev-viewers"              # Group mapped in aws-auth
    api_group = "rbac.authorization.k8s.io"
  }
}

# Custom Role for developers to view RBAC resources in the dev namespace
# If developers frequently debug or audit RBAC configurations (e.g., checking rolebindings or roles in the dev namespace),
# enable the view-rbac Role (namespace-scoped) to allow developers to debug RBAC issues in the dev namespace
resource "kubernetes_role" "view_rbac" {
  metadata {
    name      = "view-rbac"
    namespace = kubernetes_namespace.dev.metadata[0].name
  }
  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["rolebindings", "roles"]
    verbs      = ["get", "list", "watch"]
  }
  depends_on = [data.aws_eks_cluster.cluster]
}

# Bind the view-rbac Role to the dev-viewers group
resource "kubernetes_role_binding" "dev_viewers_rbac" {
  metadata {
    name      = "dev-viewers-rbac-binding"
    namespace = kubernetes_namespace.dev.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"      # References the custom view-rbac Role defined in the same module
    name      = "view-rbac"
  }
  subject {
    kind      = "Group"
    name      = "dev-viewers"
    api_group = "rbac.authorization.k8s.io"
  }
  depends_on = [data.aws_eks_cluster.cluster]
}