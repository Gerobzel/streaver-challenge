output "alb_arn" {
  description = "ARN of the ALB (used to associate WAF)."
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB."
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB (required for Route53 alias records)."
  value       = aws_lb.main.zone_id
}

output "target_group_arn_stable" {
  description = "ARN of the stable target group."
  value       = aws_lb_target_group.stable.arn
}

output "target_group_arn_canary" {
  description = "ARN of the canary target group."
  value       = aws_lb_target_group.canary.arn
}
