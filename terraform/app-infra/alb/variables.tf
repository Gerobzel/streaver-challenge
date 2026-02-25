variable "project" {
  description = "Project name used as a prefix for resource names and tags."
  type        = string
}

variable "public_vpc_id" {
  description = "ID of the public VPC where the ALB will be deployed."
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB."
  type        = list(string)
}

variable "private_vpc_id" {
  description = "ID of the private VPC where ECS tasks run (used for the target group)."
  type        = string
}

variable "domain_name" {
  description = "External domain name registered in the SSL certificate."
  type        = string
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
