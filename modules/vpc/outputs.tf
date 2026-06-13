# ============================================================================
# VPC Module - Outputs
# ============================================================================
# These outputs expose VPC infrastructure to other modules
# ============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of public subnets"
  value       = [for subnet in aws_subnet.public : subnet.cidr_block]
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = [for subnet in aws_subnet.public : subnet.availability_zone]
}
