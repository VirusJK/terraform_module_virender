# ============================================================================
# EC2 Module - Main Configuration
# ============================================================================
# This module creates EC2 instances with:
# - Instance profiles and IAM roles
# - User data scripts for basic application setup
# - CloudWatch monitoring
# - Multi-AZ deployment
# - Flexible instance count and sizing
# ============================================================================

# Data source to get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for EC2 instances to access AWS services
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-ec2-role"
    }
  )
}

# IAM Policy for EC2 instances to access CloudWatch
resource "aws_iam_role_policy" "ec2_cloudwatch_policy" {
  name = "${var.project_name}-ec2-cloudwatch-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role Policy for SSM (Systems Manager) access
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile for EC2 role
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# ============================================================================
# EC2 Instances - Using count for multiple instances
# ============================================================================
resource "aws_instance" "app" {
  count                    = var.instance_count
  ami                      = data.aws_ami.amazon_linux_2.id
  instance_type            = var.instance_type
  iam_instance_profile     = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids   = [var.security_group_id]
  subnet_id                = var.subnet_ids[count.index % length(var.subnet_ids)]
  associate_public_ip_address = true

  # User data script to install and start a simple web server
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment = var.environment
    port        = 8080
  }))

  monitoring = true  # Enable detailed CloudWatch monitoring

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = merge(
      var.tags,
      {
        Name = "${var.project_name}-root-volume-${count.index + 1}"
      }
    )
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2 only
    http_put_response_hop_limit = 1
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-instance-${count.index + 1}"
    }
  )

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_iam_instance_profile.ec2_profile]
}

# ============================================================================
# CloudWatch Alarms for EC2 Instances
# ============================================================================

# Alarm for High CPU Usage
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count               = var.instance_count
  alarm_name          = "${var.project_name}-high-cpu-alarm-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_description   = "Alarm when CPU exceeds ${var.cpu_alarm_threshold}%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.app[count.index].id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-high-cpu-${count.index + 1}"
    }
  )
}

# Alarm for Instance Status Check
resource "aws_cloudwatch_metric_alarm" "instance_status_check_failed" {
  count               = var.instance_count
  alarm_name          = "${var.project_name}-status-check-failed-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Alert when EC2 instance fails status check"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.app[count.index].id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-status-check-${count.index + 1}"
    }
  )
}
