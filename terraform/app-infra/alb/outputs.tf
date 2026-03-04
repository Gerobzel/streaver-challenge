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

output "listener_arn" {
  description = "ARN of the HTTPS production listener (used by CodeDeploy deployment group)."
  value       = aws_lb_listener.https.arn
}

output "target_group_arn_blue" {
  description = "ARN of the blue target group."
  value       = aws_lb_target_group.blue.arn
}

output "target_group_name_blue" {
  description = "Name of the blue target group (used by CodeDeploy deployment group)."
  value       = aws_lb_target_group.blue.name
}

output "target_group_arn_green" {
  description = "ARN of the green target group."
  value       = aws_lb_target_group.green.arn
}

output "target_group_name_green" {
  description = "Name of the green target group (used by CodeDeploy deployment group)."
  value       = aws_lb_target_group.green.name
}
