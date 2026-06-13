# ============================================================================
# Root Terraform Configuration - Outputs
# ============================================================================
# Outputs expose key infrastructure information for users and other systems
# ============================================================================

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "availability_zones" {
  description = "Availability zones used"
  value       = module.vpc.availability_zones
}

# EC2 Outputs
output "instance_ids" {
  description = "IDs of EC2 instances"
  value       = module.ec2.instance_ids
}

output "instance_private_ips" {
  description = "Private IP addresses of EC2 instances"
  value       = module.ec2.instance_private_ips
}

output "instance_public_ips" {
  description = "Public IP addresses of EC2 instances"
  value       = module.ec2.instance_public_ips
}

output "ec2_iam_role_name" {
  description = "Name of the EC2 IAM role"
  value       = module.ec2.iam_role_name
}

# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_url" {
  description = "URL to access the ALB"
  value       = module.alb.alb_url
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = module.alb.target_group_arn
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "Security group ID of the ALB"
  value       = module.security_groups.alb_security_group_id
}

output "ec2_security_group_id" {
  description = "Security group ID of EC2 instances"
  value       = module.security_groups.ec2_security_group_id
}

# Monitoring Outputs
output "sns_alarm_topic_arn" {
  description = "ARN of SNS topic for alarms"
  value       = module.monitoring.sns_alarm_topic_arn
}

output "cloudwatch_dashboard_name" {
  description = "Name of CloudWatch dashboard"
  value       = module.monitoring.dashboard_name
}

# Summary Output
output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    environment           = var.tags.Environment
    region                = var.aws_region
    vpc_id                = module.vpc.vpc_id
    instance_count        = var.instance_count
    instance_type         = var.instance_type
    alb_endpoint          = module.alb.alb_url
    application_endpoint  = module.alb.alb_url
  }
}
