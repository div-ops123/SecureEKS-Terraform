# Create a hosted zone if it doesn't exist
resource "aws_route53_zone" "devops_learning_domain_name" {
  name = var.domain_name
}

# Create an A record pointing to the ALB
resource "aws_route53_record" "devops_learning_frontend" {
  zone_id = aws_route53_zone.devops_learning_domain_name.zone_id
  name    = "frontend.${var.domain_name}"
  type    = "A"

  alias {
    name    = var.alb_dns_name
    zone_id = var.alb_zone_id
    evaluate_target_health = true
  }
  depends_on = [ var.alb_dns_name ]
}