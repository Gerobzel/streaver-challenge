# Networks definitions

# Private VPC
resource "aws_vpc" "private" {
  cidr_block           = var.private_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project}-private"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.private.id

  route {
    cidr_block                = var.public_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.private_to_public.id
  }

  tags = {
    Name = "${var.project}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}


# Private subnet
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.private.id
  cidr_block        = cidrsubnet(var.private_vpc_cidr, 4, count.index)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project}-private-${var.availability_zones[count.index]}"
  }
}


# Public VPC
resource "aws_vpc" "public" {
  cidr_block           = var.public_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project}-public"
  }
}

resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.public.id

  tags = {
    Name = "${var.project}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.public.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public.id
  }

  route {
    cidr_block                = var.private_vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.private_to_public.id
  }

  tags = {
    Name = "${var.project}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_vpc_peering_connection" "private_to_public" {
  vpc_id      = aws_vpc.private.id
  peer_vpc_id = aws_vpc.public.id
  auto_accept = true

  tags = {
    Name = "${var.project}-peering"
  }
}


# Public Subnet
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.public.id
  cidr_block              = cidrsubnet(var.public_vpc_cidr, 4, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-public-${var.availability_zones[count.index]}"
  }
}
