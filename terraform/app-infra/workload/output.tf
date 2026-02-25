output "service_name" {
  description = "Name of the ECS service."
  value       = aws_ecs_service.main.name
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition."
  value       = aws_ecs_task_definition.main.arn
}

output "log_group_name" {
  description = "Name of the CloudWatch log group for this workload."
  value       = aws_cloudwatch_log_group.main.name
}
