# ============================================================================
# Root Terraform Configuration - Versions and Required Providers
# ============================================================================
# This file specifies the Terraform version and required providers
# ============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }

  # Uncomment the backend configuration below when setting up S3 state backend
  # See backend/backend.tf for S3 backend setup instructions
  # backend "s3" {
  #   bucket         = "terraform-state-your-org"
  #   key            = "dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.tags.Project
      Environment = var.tags.Environment
      ManagedBy = "Terraform"
      CreatedAt = timestamp()
    }
  }
}
