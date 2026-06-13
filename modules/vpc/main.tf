# ============================================================================
# VPC Module - Main Configuration
# ============================================================================
# This module creates the foundational networking infrastructure:
# - VPC
# - Public Subnets (across multiple AZs)
# - Internet Gateway
# - Route Tables and Routes
# - NAT Gateway (optional)
# ============================================================================

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-vpc"
    }
  )
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-igw"
    }
  )
}

# Create Public Subnets
# Using for_each to create multiple subnets across AZs
resource "aws_subnet" "public" {
  for_each = {
    az1 = {
      cidr_block            = var.public_subnet_cidrs[0]
      availability_zone     = data.aws_availability_zones.available.names[0]
    }
    az2 = {
      cidr_block            = var.public_subnet_cidrs[1]
      availability_zone     = data.aws_availability_zones.available.names[1]
    }
  }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-subnet-${each.key}"
    }
  )
}

# Create Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-rt"
    }
  )
}

# Create Route to Internet Gateway
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Associate Public Subnets with Route Table
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Data source to get available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}
