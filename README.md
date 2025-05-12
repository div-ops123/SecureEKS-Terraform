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


---

## How To Start Frash

1. **Delete the Terraform State File from S3**
   - Remove the state file `eks-terraform/terraform.tfstate` from the S3 bucket `divine-eks-terraform-state`.
   - Since versioning is enabled, you need to ensure all versions of the state file are deleted to prevent Terraform from accessing historical states.

```bash
aws s3 rm s3://divine-eks-terraform-state/eks-terraform/terraform.tfstate
```

   - If you’re sure no other state files in the bucket are needed, you can delete all objects in the bucket:
       ```bash
       aws s3 rm s3://divine-eks-terraform-state --recursive
       ```

2. **Clear the DynamoDB Lock Table**
   - Check for any lock entries in the `eks-terraform-locks` DynamoDB table associated with your state file.
```bash
aws dynamodb delete-table --table-name eks-terraform-locks || true
```

3. **Clean Up Local Files**
   - Remove the local Terraform files and directories in your working directory to ensure no cached state or configuration interferes:
```bash
rm -rf .terraform .tfstate.backup .terraform.lock.hcl
```

### How To Run first time:
- follow from here
# Comment out backend "s3" block in backend.tf, and ensure no module is defined in root main.tf

4. **Reinitialize Terraform**
   - Run `terraform init` to reinitialize the working directory with the S3 backend. Since the state file and lock entries are deleted, Terraform will treat this as a fresh initialization with no prior state.
```bash
terraform init && terraform plan
```

# Uncomment backend "s3" block in backend.tf

# Reinitialize with S3 backend

### Important Notes
- **Backup First**: Before deleting the S3 state file or DynamoDB entries, consider downloading the state file from S3 as a backup:
```bash
aws s3 cp s3://divine-eks-terraform-state/eks-terraform/terraform.tfstate terraform.tfstate.backup
```
  This ensures you can recover if you accidentally delete critical state data.

---

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

---
# Errors Faced and Solutions:
1. Your previous terraform apply failed because the Kubernetes provider tried to connect to http://localhost (default endpoint) instead of the EKS cluster’s endpoint. This happened because the provider wasn’t configured with the cluster’s details, and your local kubeconfig wasn’t set up.
Solution:

---
2. **Legacy Modules:** A Terraform module is considered "legacy" if it contains its own provider block (e.g., provider "kubernetes" in modules/eks_addons/kubernetes/main.tf). Legacy modules cannot use count, for_each, or depends_on because Terraform cannot resolve provider configurations dynamically in these cases.

- **Fix:** Remove Provider Configurations from Modules
To resolve the error, you need to:

1. Move provider configurations to root main.tf.
2. Pass providers to the kubernetes and helm modules using provider inheritance.
3. Keep the depends_on clauses to ensure the EKS cluster and node group are created before the add-ons.
---

3. **Kubernetes Namespace Not Deleting Errors**
- Diagnosed and resolved stuck Kubernetes namespace by removing Ingress finalizers, ensuring complete EKS cluster cleanup.

#### Symptoms
- `terraform destroy` fails with `context deadline exceeded` for a namespace (e.g., `prod`).
- Resources like Ingresses, deployments, or secrets prevent deletion.

#### Step-by-Step Troubleshooting and Fix

1. **Check Namespace Status**:
   ```bash
   kubectl get namespace prod -o yaml
   ```
   - Look for `status.phase: Terminating` and `spec.finalizers: [kubernetes]`.
   - Check `status.conditions` for messages like `SomeResourcesRemain` or `SomeFinalizersRemain`.

3. **Delete Remaining Resources**

4. **Handle Stuck Ingress (AWS Load Balancer Controller)**:
   - If Ingress deletion times out (`error: timed out waiting for the condition`):
     ```bash
     kubectl get ingress devops-learning-frontend-ingress -n prod -o yaml
     ```
     Check for finalizers like `group.ingress.k8s.aws/my-first-cluster.alb-group`.
   - Remove Ingress finalizer:
     ```bash
     kubectl patch ingress devops-learning-frontend-ingress -n prod -p '{"metadata":{"finalizers":null}}' --type=merge
     ```
   - Verify deletion:
     ```bash
     kubectl get ingress -n prod
     kubectl get namespace -n prod
     ```

5. **Check for Orphaned ALBs**:
   ```bash
   aws elbv2 describe-load-balancers --region af-south-1
   ```
   Delete if present:
   ```bash
   aws elbv2 delete-load-balancer --load-balancer-arn <alb-arn> --region af-south-1
   ```

7. **Retry terraform destroy**:
   ```bash
   terraform destroy -auto-approve
   ```


---

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
aws eks update-kubeconfig --region af-south-1 --name my-first-cluster

# Verify Helm releases:
helm list -n kube-system
kubectl get pods -n kube-system

# Confirm ASCP and ALB RBAC:
kubectl get clusterrole secrets-provider-aws-role -o yaml
kubectl get clusterrolebinding secrets-provider-aws-binding

kubectl get clusterrole aws-load-balancer-controller
kubectl get clusterrolebinding aws-load-balancer-controller-binding

# Apply
terraform init
terraform apply
```