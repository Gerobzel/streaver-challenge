# Route53 hosted zone for the domain
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name = "${var.project}-zone"
  }
}

# A record (alias) pointing the domain root to the ALB
resource "aws_route53_record" "alb" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
