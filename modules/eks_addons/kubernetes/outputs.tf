output "secrets_provider_aws" {
  value = kubernetes_service_account.secrets_provider_aws
}

output "secrets_provider_aws_subject" {
  description = "The IRSA subject string for the ASCP ServiceAccount (system:serviceaccount:<namespace>:<name>)"
  value       = "system:serviceaccount:${kubernetes_service_account.secrets_provider_aws.metadata[0].namespace}:${kubernetes_service_account.secrets_provider_aws.metadata[0].name}"
}