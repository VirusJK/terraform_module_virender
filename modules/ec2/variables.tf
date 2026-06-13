# ============================================================================
# EC2 Module - Input Variables
# ============================================================================

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
  validation {
    condition     = can(regex("^t[23]\\.[a-z]+$|^m[56][a-z]\\.[a-z]+$", var.instance_type))
    error_message = "instance_type must be a valid EC2 instance type (e.g., t3.micro, t3.small)."
  }
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 2
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "instance_count must be between 1 and 10."
  }
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 30
  validation {
    condition     = var.root_volume_size >= 20 && var.root_volume_size <= 1000
    error_message = "root_volume_size must be between 20 and 1000 GB."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs where instances will be deployed"
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "At least one subnet ID must be provided."
  }
}

variable "security_group_id" {
  description = "Security group ID for EC2 instances"
  type        = string
}

variable "project_name" {
  description = "Project name for naming resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment must be one of: dev, qa, prod."
  }
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization threshold for CloudWatch alarm (percent)"
  type        = number
  default     = 70
  validation {
    condition     = var.cpu_alarm_threshold > 0 && var.cpu_alarm_threshold <= 100
    error_message = "cpu_alarm_threshold must be between 1 and 100."
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
