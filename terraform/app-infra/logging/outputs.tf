output "s3_bucket_name" {
  description = "Name of the S3 bucket storing archived logs."
  value       = aws_s3_bucket.logs.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket storing archived logs."
  value       = aws_s3_bucket.logs.arn
}
