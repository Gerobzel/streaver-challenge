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

variable "domain_name" {
  description = "External domain name registered in the SSL certificate."
  type        = string
}
