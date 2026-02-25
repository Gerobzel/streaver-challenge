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

variable "alert_email" {
  description = "Email address to receive alarm notifications."
  type        = string
}

# To add alarms for a new workload, append an object to this list.
variable "workloads" {
  description = "List of workloads to alert on. Each entry creates a full set of alarms scoped to that workload."
  type = list(object({
    name             = string # Used as a suffix in alarm names
    service_name     = string # ECS service name (for CPU/memory alarms)
    target_group_arn = string # ALB target group ARN (for request/error/latency alarms)
  }))
}
