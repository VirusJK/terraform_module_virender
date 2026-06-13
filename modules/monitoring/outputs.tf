# ============================================================================
# Monitoring Module - Outputs
# ============================================================================

output "sns_alarm_topic_arn" {
  description = "ARN of SNS topic for critical alarms"
  value       = aws_sns_topic.alarms.arn
}

output "sns_warning_topic_arn" {
  description = "ARN of SNS topic for warnings"
  value       = aws_sns_topic.warnings.arn
}

output "log_group_application_name" {
  description = "Name of the application CloudWatch log group"
  value       = aws_cloudwatch_log_group.application.name
}

output "log_group_alb_name" {
  description = "Name of the ALB CloudWatch log group"
  value       = aws_cloudwatch_log_group.alb.name
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = var.enable_dashboard ? aws_cloudwatch_dashboard.main[0].dashboard_name : null
}
