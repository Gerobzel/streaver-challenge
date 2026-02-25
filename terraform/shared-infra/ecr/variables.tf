variable "project" {
  description = "Project name used as a prefix for resource names and tags."
  type        = string
}

variable "app_name" {
  description = "Application name used as the ECR repository suffix."
  type        = string
}
