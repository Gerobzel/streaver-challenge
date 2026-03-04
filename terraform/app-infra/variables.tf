variable "project" {
  description = "Project name — must match the value used in shared-infra."
  type        = string
}

variable "domain_name" {
  description = "External domain name for the application."
  type        = string
}

variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications."
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "image_tag" {
  description = "Image tag for the ECS service (managed by CodeDeploy after first deploy)."
  type        = string
  default     = "latest"
}
