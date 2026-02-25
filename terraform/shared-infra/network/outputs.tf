output "private_vpc_id" {
  description = "ID of the private VPC."
  value       = aws_vpc.private.id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs, one per availability zone."
  value       = aws_subnet.private[*].id
}

output "public_vpc_id" {
  description = "ID of the public VPC."
  value       = aws_vpc.public.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs, one per availability zone."
  value       = aws_subnet.public[*].id
}
