output "devops_learning_fqdn" {
  description = "The fully qualified domain name for the frontend"
  value       = aws_route53_record.devops_learning_frontend.fqdn
}