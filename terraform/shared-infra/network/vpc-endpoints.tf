# VPC Endpoints — allow ECS Fargate tasks in the private VPC to reach AWS
# services without a NAT gateway or internet route.

# Security group shared by all interface endpoints.
resource "aws_security_group" "vpc_endpoints" {
  name   = "${var.project}-vpc-endpoints"
  vpc_id = aws_vpc.private.id

  ingress {
    description = "HTTPS from private VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.private_vpc_cidr]
  }

  tags = {
    Name = "${var.project}-vpc-endpoints"
  }
}

# ECR API — authentication and image manifest requests
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.private.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project}-ecr-api"
  }
}

# ECR DKR — Docker image layer downloads
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.private.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project}-ecr-dkr"
  }
}

# CloudWatch Logs — ECS task log shipping
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.private.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project}-logs"
  }
}

# S3 — ECR stores image layers in S3; gateway endpoints are free
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.private.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "${var.project}-s3"
  }
}

data "aws_region" "current" {}
