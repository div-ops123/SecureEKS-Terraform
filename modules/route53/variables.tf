variable "domain_name" {
  type        = string
  description = "The domain name for the Route 53 hosted zone (e.g., your-domain.com)"
}

variable "alb_dns_name" {
  type        = string
  description = "The DNS name of the ALB created by the Ingress"
}

variable "alb_zone_id" {
  type        = string
  description = "The Route 53 zone ID of the ALB"
}