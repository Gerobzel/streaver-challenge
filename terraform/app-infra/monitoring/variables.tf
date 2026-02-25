variable "project" {
  description = "Project name used as a prefix for resource names and tags."
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster (shared across all workloads)."
  type        = string
}

variable "alb_arn" {
  description = "ARN of the ALB (shared across all workloads)."
  type        = string
}

# To add monitoring for a new workload, append an object to this list.
variable "workloads" {
  description = "List of workloads to monitor. Each entry adds metrics and log panels to the dashboard."
  type = list(object({
    name             = string # Display name and metric label
    service_name     = string # ECS service name (for CPU/memory metrics)
    target_group_arn = string # ALB target group ARN (for request/error/latency metrics)
    log_group_name   = string # CloudWatch log group (for the log panel)
  }))
}
