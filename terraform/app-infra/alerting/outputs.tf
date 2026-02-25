output "sns_topic_arn" {
  description = "ARN of the SNS alarms topic."
  value       = aws_sns_topic.alarms.arn
}
