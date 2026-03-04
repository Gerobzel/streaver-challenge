variable "project" {
  description = "Project name used as a prefix for resource names and tags."
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster."
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service managed by this deployment group."
  type        = string
}

variable "listener_arn" {
  description = "ARN of the ALB production HTTPS listener."
  type        = string
}

variable "target_group_name_blue" {
  description = "Name of the blue (current) ALB target group."
  type        = string
}

variable "target_group_name_green" {
  description = "Name of the green (new) ALB target group."
  type        = string
}

variable "alarm_names" {
  description = "CloudWatch alarm names that trigger an automatic rollback during the canary window."
  type        = list(string)
  default     = []
}
