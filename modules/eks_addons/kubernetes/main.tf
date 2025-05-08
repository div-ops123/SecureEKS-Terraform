# --- RBAC roles and Service Accounts ---

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
}

# Service Account for ASCP to assume IAM IRSA to access AWS Parameter Store
resource "kubernetes_service_account" "ascp_service_account" {
  metadata {
    name      = "secrets-provider-aws-sa"
    namespace = "kube-system"
    # links `secrets-provider-aws-sa` to an IAM role with permissions for Parameter Store
    annotations = {
      "eks.amazonaws.com/role-arn" = var.devops_learning_irsa_arn
    }
  }

  # Ensure the Service Account is created before Helm releases
  depends_on = [
    var.cluster_endpoint  # Ensure EKS cluster is ready
  ]
}


# ----------
# RBAC Roles: Is your way of custom-controlling who gets access to the EKS cluster via IAM.

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
}


# Prod Namespace - CI/CD (edit access)
resource "kubernetes_role_binding" "prod_editors" {
  # Ensure namespace is created before binding
  depends_on = [ kubernetes_namespace.prod ]

  metadata {
    name      = "prod-editors-binding"     # Binding name
    namespace = kubernetes_namespace.prod.metadata[0].name  # Prod namespace only
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"              # eferences the predefined `edit` ClusterRole, which is a built-in Kubernetes role.
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
  depends_on = [ kubernetes_namespace.dev ]

  metadata {
    name      = "dev-viewers-binding"      # Binding name
    namespace = kubernetes_namespace.dev.metadata[0].name  # Dev namespace only, created in namespaces.tf
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"              # eferences the predefined `view` ClusterRole, which is a built-in Kubernetes role.
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
}