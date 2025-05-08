output "parameter_arns" {
  value = [
    aws_ssm_parameter.db_username.arn,
    aws_ssm_parameter.db_password.arn,
    aws_ssm_parameter.db_name.arn,
    aws_ssm_parameter.secret_key.arn,
    aws_ssm_parameter.rds_endpoint.arn
  ]
}