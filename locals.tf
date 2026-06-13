# ============================================================================
# Root Terraform Configuration - Locals
# ============================================================================
# Computed values and local variables used throughout the configuration
# ============================================================================

locals {
  # Standardized project name
  project_name = "${var.tags.Project}-${var.tags.Environment}"

  # Common tags applied to all resources
  common_tags = merge(
    var.tags,
    {
      CreatedDate = timestamp()
      LastModified = timestamp()
    }
  )

  # Environment-specific naming conventions
  environment_suffix = {
    dev  = "-dev"
    qa   = "-qa"
    prod = "-prod"
  }[var.tags.Environment]
}
