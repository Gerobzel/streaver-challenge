variable "project" {
  description = "Project name used as a prefix for resource names and tags."
  type        = string
}

variable "alb_arn" {
  description = "ARN of the ALB to associate the WAF Web ACL with."
  type        = string
}
