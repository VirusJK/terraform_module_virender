# ============================================================================
# Terraform Backend Configuration - S3 with State Locking
# ============================================================================
# This file demonstrates how to set up remote state management in AWS
# ============================================================================

# ============================================================================
# SETUP INSTRUCTIONS
# ============================================================================
# Before using this backend configuration:
#
# 1. Create S3 bucket:
#    aws s3api create-bucket \
#      --bucket terraform-state-your-org \
#      --region us-east-1 \
#      --acl private
#
# 2. Enable versioning:
#    aws s3api put-bucket-versioning \
#      --bucket terraform-state-your-org \
#      --versioning-configuration Status=Enabled
#
# 3. Enable encryption:
#    aws s3api put-bucket-encryption \
#      --bucket terraform-state-your-org \
#      --server-side-encryption-configuration '{
#        "Rules": [{
#          "ApplyServerSideEncryptionByDefault": {
#            "SSEAlgorithm": "AES256"
#          }
#        }]
#      }'
#
# 4. Block public access:
#    aws s3api put-public-access-block \
#      --bucket terraform-state-your-org \
#      --public-access-block-configuration \
#      "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
#
# 5. Create DynamoDB table for state locking:
#    aws dynamodb create-table \
#      --table-name terraform-locks \
#      --attribute-definitions AttributeName=LockID,AttributeType=S \
#      --key-schema AttributeName=LockID,KeyType=HASH \
#      --billing-mode PAY_PER_REQUEST \
#      --region us-east-1
#
# 6. Update the backend configuration in versions.tf with your bucket name
#

# ============================================================================
# S3 Backend Configuration
# ============================================================================
# To enable this backend:
# 1. Uncomment the backend block in versions.tf
# 2. Run: terraform init
# 3. Confirm the migration when prompted

/*
backend "s3" {
  bucket         = "terraform-state-your-org"  # Change to your bucket name
  key            = "dev/terraform.tfstate"      # Change based on environment
  region         = "us-east-1"
  encrypt        = true                         # Enable encryption
  dynamodb_table = "terraform-locks"            # State locking table
}
*/

# ============================================================================
# WHY REMOTE STATE?
# ============================================================================
# Local vs Remote State:
#
# LOCAL STATE (.tfstate in working directory):
# - Pros:
#   * Simple for learning/development
#   * No external dependencies
#   * Full control locally
# - Cons:
#   * Risk of accidental deletion
#   * Not suitable for teams
#   * No automatic backups
#   * Sensitive data stored locally
#
# REMOTE STATE (S3 with locking):
# - Pros:
#   * Team collaboration (single source of truth)
#   * Automatic backups (S3 versioning)
#   * State locking (prevents concurrent modifications)
#   * Encryption at rest and in transit
#   * Auditing capabilities
#   * Disaster recovery
# - Cons:
#   * Requires AWS credentials
#   * Slightly slower operations
#   * Additional AWS costs (minimal)

# ============================================================================
# STATE LOCKING EXPLANATION
# ============================================================================
# DynamoDB state locking prevents multiple terraform operations from running
# simultaneously, which could cause conflicts and data corruption.
#
# How it works:
# 1. When terraform acquires state, it creates a lock in DynamoDB
# 2. Lock includes: LockID (unique identifier), Digest, Operator, Reason, Version
# 3. If another operation tries to acquire lock, it waits or fails
# 4. After terraform completes, lock is released
#
# Required DynamoDB table:
# - Primary key: LockID (String)
# - Name must match: terraform-locks (or your configured name)
# - No other attributes needed (DynamoDB-managed)

# ============================================================================
# TERRAFORM STATE FILE SECURITY
# ============================================================================
# The .tfstate file contains:
# - Resource IDs (safe to share)
# - Sensitive values (passwords, keys, tokens) - MUST BE PROTECTED
# - Input variables (may contain secrets)
#
# Security best practices:
# 1. Never commit .tfstate to version control (add to .gitignore)
# 2. Store remote state in encrypted S3 bucket
# 3. Enable S3 versioning for disaster recovery
# 4. Use IAM policies to restrict state access
# 5. Enable MFA delete for production
# 6. Use S3 Object Lock for compliance
# 7. Enable CloudTrail logging for audit trail

# ============================================================================
# ENVIRONMENT-SPECIFIC STATE FILES
# ============================================================================
# Recommended approach: separate state file per environment
#
# Dev environment:
#   key = "dev/terraform.tfstate"
#   bucket = "terraform-state-dev"
#
# QA environment:
#   key = "qa/terraform.tfstate"
#   bucket = "terraform-state-qa"
#
# Production environment:
#   key = "prod/terraform.tfstate"
#   bucket = "terraform-state-prod"
#
# This ensures:
# - Failed dev deployments don't affect production
# - Different access controls per environment
# - Compliance with environment isolation
# - Easier recovery in case of disaster

# ============================================================================
# STATE MIGRATION STEPS
# ============================================================================
# To migrate from local to S3 backend:
#
# 1. Uncomment backend block in versions.tf
# 2. Run: terraform init
# 3. Terraform will detect you want to migrate state:
#    Do you want to copy existing state to the new backend?
#    Enter a value: yes
# 4. Verify state in S3: 
#    aws s3 ls s3://terraform-state-your-org/dev/
# 5. Backup local state file (optional):
#    cp terraform.tfstate terraform.tfstate.backup

# ============================================================================
# DISASTER RECOVERY
# ============================================================================
# If state file is corrupted or lost:
#
# 1. Check S3 versioning for previous versions:
#    aws s3api list-object-versions \
#      --bucket terraform-state-your-org \
#      --prefix dev/terraform.tfstate
#
# 2. Restore previous version:
#    aws s3api get-object \
#      --bucket terraform-state-your-org \
#      --key dev/terraform.tfstate \
#      --version-id VERSION_ID \
#      terraform.tfstate
#
# 3. If all backups lost, use terraform refresh to rebuild state:
#    terraform refresh
#    (This will query AWS to determine current state)
#
# 4. Always keep automated backups enabled
