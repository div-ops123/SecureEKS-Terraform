resource "aws_ssm_parameter" "db_username" {
  name = "/devops-learning/db-username"
  type = "SecureString"
  value = var.db_username
}

resource "aws_ssm_parameter" "db_password" {
  name = "/devops-learning/db-password"
  type = "SecureString"
  value = var.db_password
}

resource "aws_ssm_parameter" "db_name" {
  name = "/devops-learning/db-name"
  type = "SecureString"
  value = var.db_name
}

resource "aws_ssm_parameter" "secret_key" {
  name = "/devops-learning/secret-key"
  type = "SecureString"
  value = var.secret_key
}

resource "aws_ssm_parameter" "rds_endpoint" {
  name = "/devops-learning/rds-endpoint"
  type = "String"
  value = var.rds_endpoint
}