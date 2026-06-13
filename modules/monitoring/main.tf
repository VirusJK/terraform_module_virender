# ============================================================================
# Monitoring Module - Main Configuration
# ============================================================================
# This module creates CloudWatch resources for monitoring and alerting:
# - SNS Topics for notifications
# - CloudWatch Log Groups
# - Dashboard (optional)
# ============================================================================

# SNS Topic for critical alarms
resource "aws_sns_topic" "alarms" {
  name = "${var.project_name}-alarms"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-alarms"
    }
  )
}

# SNS Topic for warnings
resource "aws_sns_topic" "warnings" {
  name = "${var.project_name}-warnings"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-warnings"
    }
  )
}

# SNS Topic Subscription for critical alarms (email)
resource "aws_sns_topic_subscription" "alarms_email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# CloudWatch Log Group for application logs
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/${var.project_name}/application"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-app-logs"
    }
  )
}

# CloudWatch Log Group for ALB logs
resource "aws_cloudwatch_log_group" "alb" {
  name              = "/aws/${var.project_name}/alb"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-alb-logs"
    }
  )
}

# CloudWatch Dashboard for monitoring overview
resource "aws_cloudwatch_dashboard" "main" {
  count          = var.enable_dashboard ? 1 : 0
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average" }],
            [".", "RequestCount", { stat = "Sum" }],
            [".", "HealthyHostCount", { stat = "Average" }],
            [".", "UnHealthyHostCount", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ALB Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average" }],
            [".", "NetworkIn", { stat = "Sum" }],
            [".", "NetworkOut", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 Metrics"
        }
      }
    ]
  })
}

# CloudWatch Log Metric Filter for errors
resource "aws_cloudwatch_log_group_metric_filter" "errors" {
  count          = var.enable_error_logging ? 1 : 0
  name           = "${var.project_name}-error-filter"
  log_group_name = aws_cloudwatch_log_group.application.name
  filter_pattern = "[ERROR]"
  metric_transformation {
    name          = "${var.project_name}-error-count"
    namespace     = "${var.project_name}/Application"
    value         = "1"
    default_value = "0"
  }
}

# CloudWatch Alarm for application errors
resource "aws_cloudwatch_metric_alarm" "application_errors" {
  count               = var.enable_error_logging ? 1 : 0
  alarm_name          = "${var.project_name}-application-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "${var.project_name}-error-count"
  namespace           = "${var.project_name}/Application"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Alert when application errors are detected"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-app-errors"
    }
  )
}
