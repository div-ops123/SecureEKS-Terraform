# S3 backend Prevents state conflict

terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }

  backend "s3" {
    # name of s3 bucket provisioned in remote_state.tf
    bucket = "divine-eks-terraform-state"
    # 
    key    = "eks-terraform/terraform.tfstate"
    region = "af-south-1"
    # name of dynamodb table provisioned in remote_state.tf
    use_lockfile = true
  }
}