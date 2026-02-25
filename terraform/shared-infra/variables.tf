variable "project" {
  description = "Project name used as a prefix for resource names and tags."
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones in which to create subnets."
  type        = list(string)
}

variable "aws_region" {
  description = "AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}
