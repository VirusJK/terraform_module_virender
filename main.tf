# ============================================================================
# Root Terraform Configuration - Main Module Instantiation
# ============================================================================
# This file orchestrates all modules to create the complete infrastructure
# ============================================================================

# ============================================================================
# VPC Module
# ============================================================================
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  project_name        = local.project_name
  tags                = local.common_tags
}

# ============================================================================
# Security Groups Module
# ============================================================================
module "security_groups" {
  source = "./modules/security-group"

  vpc_id              = module.vpc.vpc_id
  project_name        = local.project_name
  admin_cidr_blocks   = var.admin_cidr_blocks
  tags                = local.common_tags
}

# ============================================================================
# EC2 Module - Application Instances
# ============================================================================
module "ec2" {
  source = "./modules/ec2"

  instance_type        = var.instance_type
  instance_count       = var.instance_count
  root_volume_size     = var.root_volume_size
  subnet_ids           = module.vpc.public_subnet_ids
  security_group_id    = module.security_groups.ec2_security_group_id
  project_name         = local.project_name
  environment          = var.tags.Environment
  cpu_alarm_threshold  = var.cpu_alarm_threshold
  tags                 = local.common_tags

  depends_on = [module.security_groups]
}

# ============================================================================
# Application Load Balancer Module
# ============================================================================
module "alb" {
  source = "./modules/alb"

  alb_security_group_id         = module.security_groups.alb_security_group_id
  subnet_ids                    = module.vpc.public_subnet_ids
  vpc_id                        = module.vpc.vpc_id
  instance_ids                  = module.ec2.instance_ids
  project_name                  = local.project_name
  target_port                   = 80
  health_check_path             = "/health"
  health_check_interval         = 30
  health_check_timeout          = 5
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 3
  enable_deletion_protection    = var.enable_deletion_protection
  response_time_alarm_threshold = var.response_time_alarm_threshold
  request_count_alarm_threshold = var.request_count_alarm_threshold
  tags                          = local.common_tags

  depends_on = [module.security_groups, module.ec2]
}

# ============================================================================
# Monitoring Module
# ============================================================================
module "monitoring" {
  source = "./modules/monitoring"

  project_name         = local.project_name
  aws_region           = var.aws_region
  log_retention_days   = var.log_retention_days
  alarm_email          = var.alarm_email
  enable_dashboard     = var.enable_dashboard
  enable_error_logging = var.enable_error_logging
  tags                 = local.common_tags

  depends_on = [module.vpc, module.ec2, module.alb]
}
