variable "project" {
  description = "Project name used as a prefix for resource tags and names."
  type        = string
}

variable "private_vpc_cidr" {
  description = "CIDR block for the private VPC."
  type        = string
  default     = "10.0.0.0/24"
}

variable "public_vpc_cidr" {
  description = "CIDR block for the public VPC."
  type        = string
  default     = "10.1.0.0/24"
}

variable "availability_zones" {
  description = "List of availability zones in which to create subnets."
  type        = list(string)
}
