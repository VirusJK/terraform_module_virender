# ============================================================================
# Security Group Module - Input Variables
# ============================================================================

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "project_name" {
  description = "Project name for naming resources"
  type        = string
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access (restrict to your IP/VPN)"
  type        = list(string)
  default     = ["10.0.0.0/8"]  # Restrict this in production to your IP/VPN
  validation {
    condition = alltrue([
      for cidr in var.admin_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "admin_cidr_blocks must contain valid CIDR blocks."
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
