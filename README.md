# Secure EKS Cluster with Terraform

This project, provisions an AWS Elastic Kubernetes Service (EKS) cluster using Terraform. It features a modular architecture with secure IAM roles and Kubernetes RBAC, enabling fine-grained access control for administrators, developers, and CI/CD pipelines. The setup is designed for production-grade environments, with namespace isolation, secure authentication, and integration with GitHub Actions for CI/CD.

## Features

- **Modular Terraform Structure**: Organized into reusable modules for VPC, IAM, EKS, security groups, IRSA, and RBAC configuration.
- **IAM Roles**:
  - Administrator: Full cluster access via `system:masters`.
  - Developer: Read-only access (`view`) in the `dev` namespace, with RBAC debugging capabilities.
  - CI/CD: Edit access (`edit`) in the `prod` namespace via GitHub Actions OIDC.
- **Kubernetes RBAC**: Namespace isolation with `dev` for developers and `prod` for CI/CD pipelines.
- **Secure Authentication**: IAM users with access keys and role assumption for programmatic access.
- **Terraform State Management**: Remote backend with S3 and DynamoDB for state storage and locking.
- **Access Scripts**: Bash scripts (`assume-role.sh`, `assume-role-dev.sh`) for easy admin and developer access to the cluster.

## Prerequisites

To use this project, ensure you have the following:

- An AWS account with permissions to create EKS, IAM, VPC, S3, and DynamoDB resources.
- [Terraform](https://www.terraform.io/downloads.html) >= 1.5.0.
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials.
- [kubectl](https://kubernetes.io/docs/tasks/tools/) for interacting with the EKS cluster.
- [jq](https://stedolan.github.io/jq/) for parsing JSON in access scripts.

## Architecture

This project deploys a secure EKS cluster in a custom VPC with public and private subnets. IAM roles control access to the cluster, while Kubernetes RBAC enforces namespace-specific permissions. The setup integrates with GitHub Actions for CI/CD deployments to the `prod` namespace.

**High-Level Flow**:
- **VPC**: Public and private subnets for EKS and worker nodes.
- **EKS**: Managed Kubernetes cluster with worker node groups.
- **IAM**: Roles for admins (full access), developers (read-only), and CI/CD (edit access).
- **RBAC**: `dev` namespace for read-only developer access, `prod` namespace for CI/CD deployments.
- **State Management**: S3 bucket for Terraform state, DynamoDB for state locking.

[Networking Diagram comming soon.]

## Configuration Details

- **IAM Roles**:
  - Admin: Maps to `system:masters` for full cluster control.
  - Developer: Maps to `dev-viewers` group with `view` ClusterRole in `dev` namespace, plus RBAC debugging (`rolebindings`, `roles`).
  - CI/CD: Maps to `prod-editors` group with `edit` ClusterRole in `prod` namespace, using GitHub Actions OIDC.
- **RBAC**:
  - `dev` namespace: Read-only for developers.
  - `prod` namespace: Read/write for CI/CD pipelines.
## IRSA Configuration
- Configured EKS OIDC provider using Terraform to enable IAM Roles for Service Accounts.
- Integrated IRSA with the AWS Load Balancer Controller for secure ALB management.

- **State Management**: Terraform state is stored in an S3 bucket with versioning and locked via DynamoDB.

## ALB Configuration
- Configured AWS Load Balancer Controller to provision an ALB for routing traffic to www.my-custom-domain.com.
- Implemented health checks (/health) to ensure reliable traffic routing.
- Provisioned an IRSA-enabled IAM role (EKSALBRole) using Terraform for secure ALB management.

## Contributing

Contributions are welcome for bug fixes or documentation improvements. Please:
- Open an issue to discuss proposed changes.
- Submit a pull request with clear commit messages.

## Contact

Created by Divine Nwadigo.  
- GitHub: https://github.com/div-ops123

## Acknowledgments

- Built with [Terraform](https://www.terraform.io/), [AWS EKS](https://aws.amazon.com/eks/), and [Kubernetes](https://kubernetes.io/).
- Inspired by AWS best practices and Terraform documentation.

---
```bash
# Verify Helm releases:
helm list -n kube-system

# Confirm ASCP RBAC is enabled (default or manifest):
kubectl get clusterrole secrets-provider-aws-role
kubectl get clusterrolebinding secrets-provider-aws-binding

# Apply
terraform init
terraform apply -var-file=secrets.tfvars
```