output "nameservers" {
  description = "Nameservers for the Route53 hosted zone (delegate these at your registrar)."
  value       = aws_route53_zone.main.name_servers
}

output "zone_id" {
  description = "ID of the Route53 hosted zone."
  value       = aws_route53_zone.main.zone_id
}
