variable "project" {
  description = "Project name used as a prefix for resource names and tags."
  type        = string
}

variable "domain_name" {
  description = "Root domain name to manage in Route53."
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB (alias target)."
  type        = string
}

variable "alb_zone_id" {
  description = "Hosted zone ID of the ALB (required for alias records)."
  type        = string
}
