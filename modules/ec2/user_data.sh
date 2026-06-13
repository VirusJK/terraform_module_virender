#!/bin/bash
# ============================================================================
# EC2 Instance User Data Script
# ============================================================================
# This script runs when an EC2 instance is launched
# Install web server and application
# ============================================================================

set -e

# Update system packages
yum update -y
yum install -y httpd php php-json php-gd

# Create a simple PHP application
cat > /var/www/html/index.php <<'EOF'
<?php
$environment = getenv('ENVIRONMENT') ?? 'unknown';
$hostname = gethostname();
$instance_id = file_get_contents('http://169.254.169.254/latest/meta-data/instance-id');
$az = file_get_contents('http://169.254.169.254/latest/meta-data/placement/availability-zone');
$private_ip = file_get_contents('http://169.254.169.254/latest/meta-data/local-ipv4');

echo "<!DOCTYPE html>";
echo "<html>";
echo "<head><title>DevOps Interview Demo - AWS Infrastructure</title>";
echo "<style>";
echo "body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }";
echo ".container { background-color: white; padding: 20px; border-radius: 5px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); max-width: 600px; }";
echo "h1 { color: #FF9900; }";
echo ".info { background-color: #f9f9f9; padding: 10px; margin: 10px 0; border-left: 4px solid #FF9900; }";
echo "code { background-color: #f0f0f0; padding: 2px 5px; border-radius: 3px; }";
echo "</style>";
echo "</head>";
echo "<body>";
echo "<div class='container'>";
echo "<h1>🚀 Terraform AWS Interview Demo</h1>";
echo "<p>This instance is running the production-grade Terraform infrastructure.</p>";
echo "<div class='info'>";
echo "<strong>Environment:</strong> " . htmlspecialchars($environment) . "<br>";
echo "<strong>Hostname:</strong> " . htmlspecialchars($hostname) . "<br>";
echo "<strong>Instance ID:</strong> <code>" . htmlspecialchars($instance_id) . "</code><br>";
echo "<strong>Private IP:</strong> <code>" . htmlspecialchars($private_ip) . "</code><br>";
echo "<strong>Availability Zone:</strong> <code>" . htmlspecialchars($az) . "</code><br>";
echo "</div>";
echo "<p><strong>Application Status:</strong> ✅ Healthy</p>";
echo "<p><em>This instance is behind an Application Load Balancer with health checks and CloudWatch monitoring.</em></p>";
echo "</div>";
echo "</body>";
echo "</html>";
?>
EOF

# Set environment variable for the application
echo "export ENVIRONMENT='${environment}'" >> /etc/environment

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create a simple health check endpoint
cat > /var/www/html/health <<'EOF'
OK
EOF

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Output completion message to system log
echo "EC2 instance initialization complete" > /var/log/user-data.log
