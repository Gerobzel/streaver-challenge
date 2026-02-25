variable "name" {
  description = "Workload variant name (e.g. hello-world-stable, hello-world-canary)."
  type        = string
}

variable "project" {
  description = "Project name used as a prefix for resource names and tags."
  type        = string
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository to pull the container image from."
  type        = string
}

variable "cluster_id" {
  description = "ID of the ECS cluster."
  type        = string
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster."
  type        = string
}

variable "task_execution_role_arn" {
  description = "ARN of the ECS task execution role."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs where tasks will run."
  type        = list(string)
}

variable "private_vpc_id" {
  description = "ID of the private VPC."
  type        = string
}

variable "image_tag" {
  description = "Tag of the container image to deploy."
  type        = string
  default     = "latest"
}

variable "desired_count" {
  description = "Number of task instances to run."
  type        = number
  default     = 1
}

variable "target_group_arn" {
  description = "ARN of the ALB target group to attach the ECS service to."
  type        = string
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of ECS tasks."
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of ECS tasks."
  type        = number
  default     = 4
}

variable "autoscaling_cpu_target" {
  description = "Target average CPU utilization (%) to trigger scaling."
  type        = number
  default     = 60
}

variable "autoscaling_memory_target" {
  description = "Target average memory utilization (%) to trigger scaling."
  type        = number
  default     = 70
}

variable "autoscaling_requests_per_target" {
  description = "Target request count per task to trigger scaling."
  type        = number
  default     = 1000
}

variable "alb_arn" {
  description = "ARN of the ALB (required to build the resource label for request count scaling)."
  type        = string
}
