variable "project" {
  description = "Project name used as a prefix for resource names and tags."
  type        = string
}

variable "log_groups" {
  description = "Map of workload name to CloudWatch log group name. One Firehose stream and S3 prefix is created per entry."
  type        = map(string)
}
