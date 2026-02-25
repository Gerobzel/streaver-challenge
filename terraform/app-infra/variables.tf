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

variable "image_tag_stable" {
  description = "Image tag for the stable ECS service."
  type        = string
  default     = "latest"
}

variable "image_tag_canary" {
  description = "Image tag for the canary ECS service."
  type        = string
  default     = "latest"
}

variable "weight_stable" {
  description = "ALB traffic weight for the stable target group (0–100)."
  type        = number
  default     = 100
}

variable "weight_canary" {
  description = "ALB traffic weight for the canary target group (0–100)."
  type        = number
  default     = 0
}
