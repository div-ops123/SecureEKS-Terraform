# Create an S3 bucket and DynamoDB table for state management.

provider "aws" {
  region = "af-south-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "divine-eks-terraform-state"
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name = "eks-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}