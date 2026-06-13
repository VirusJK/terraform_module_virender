# AWS CLI Examples - Complete Reference

## Table of Contents

1. [S3 Operations](#s3-operations)
2. [EC2 Operations](#ec2-operations)
3. [ALB/ELB Operations](#albelb-operations)
4. [CloudWatch Operations](#cloudwatch-operations)
5. [IAM Operations](#iam-operations)
6. [Networking Operations](#networking-operations)
7. [Common Workflows](#common-workflows)
8. [Interview Q&A](#interview-qa)

---

## S3 Operations

### Copy Commands

#### Copy Single File

```bash
# Local to S3
aws s3 cp ./terraform.tfstate s3://terraform-state-bucket/dev/

# Output:
# upload: ./terraform.tfstate to s3://terraform-state-bucket/dev/terraform.tfstate

# S3 to Local
aws s3 cp s3://terraform-state-bucket/dev/terraform.tfstate ./terraform.tfstate.backup

# With metadata
aws s3 cp ./terraform.tfstate s3://terraform-state-bucket/dev/ \
  --metadata "environment=dev,version=1.0"

# With storage class
aws s3 cp ./terraform.tfstate s3://terraform-state-bucket/dev/ \
  --storage-class STANDARD_IA  # For cost savings
```

#### Copy Directory (Recursive)

```bash
# Local folder to S3 (uploads all files)
aws s3 cp ./modules s3://terraform-state-bucket/modules/ --recursive

# Output shows progress:
# upload: modules/vpc/main.tf to s3://terraform-state-bucket/modules/vpc/main.tf
# upload: modules/vpc/variables.tf to s3://terraform-state-bucket/modules/vpc/variables.tf
# ...

# With exclude pattern (skip certain files)
aws s3 cp ./modules s3://terraform-state-bucket/modules/ \
  --recursive \
  --exclude "*.tfstate"       # Don't upload state files
  --exclude ".terraform/*"     # Don't upload terraform cache
  --exclude ".git/*"           # Don't upload git

# S3 to Local (downloads)
aws s3 cp s3://terraform-state-bucket/modules ./local-modules/ --recursive

# Show progress
aws s3 cp ./modules s3://terraform-state-bucket/modules/ \
  --recursive \
  --quiet  # Suppress output
```

### Sync Commands

#### Upload (Local → S3)

```bash
# Basic sync
aws s3 sync ./modules s3://terraform-state-bucket/modules/

# Only uploads files that changed (checks timestamp, size, ETag)
# Files in S3 that don't exist locally are NOT deleted

# With delete (dangerous!)
aws s3 sync ./modules s3://terraform-state-bucket/modules/ --delete

# Use with caution - deletes S3 files not in local directory

# Exclude patterns
aws s3 sync ./modules s3://terraform-state-bucket/modules/ \
  --exclude "*.tfstate" \
  --exclude ".terraform/*" \
  --exclude "*.backup"

# Dry-run (see what would be synced without actually doing it)
aws s3 sync ./modules s3://terraform-state-bucket/modules/ \
  --exclude "*.tfstate" \
  --dryrun
```

#### Download (S3 → Local)

```bash
# Download from S3 (S3 → Local)
aws s3 sync s3://terraform-state-bucket/modules ./local-modules/

# Only downloads files that have changed

# Ensure local is pristine before sync
rm -rf ./local-modules
aws s3 sync s3://terraform-state-bucket/modules ./local-modules/

# Exclude patterns (what NOT to download)
aws s3 sync s3://terraform-state-bucket/ ./backup/ \
  --exclude "*.log" \
  --exclude "*.tmp"
```

### cp vs sync Comparison

| Feature | cp | cp --recursive | sync |
|---------|----|----|------|
| **Single file** | ✅ | ❌ | ❌ |
| **Directory** | ❌ | ✅ | ✅ |
| **Smart copy** | ❌ | ❌ | ✅ |
| **Only changed files** | ❌ | ❌ | ✅ |
| **Compare ETag** | ❌ | ❌ | ✅ |
| **Parallel** | ✅ | ✅ | ✅ |
| **Delete destination** | ❌ | ❌ | ✅ (with --delete) |

```bash
# Use cp for:
- Uploading a single file (simple, direct)
- One-time operations
- When you want full control

# Use sync for:
- Keeping directories in sync
- Production backups
- Regular data synchronization
- Continuous integration workflows
```

### Practical Examples

```bash
# Production workflow: Backup Terraform state
aws s3 sync ./terraform-states s3://terraform-backup/ \
  --delete \
  --exclude ".git/*"

# Restore from backup
aws s3 sync s3://terraform-backup/ ./terraform-states/

# Archive old logs
aws s3 sync ./logs/ s3://app-logs/archive/ \
  --exclude "*.log.gz"

# List what would be synced
aws s3 sync ./modules s3://bucket/modules/ --dryrun

# Transfer between buckets
aws s3 sync s3://source-bucket s3://dest-bucket

# Copy with specific permissions
aws s3 cp ./terraform.tfstate s3://bucket/dev/ \
  --sse AES256 \
  --acl private
```

---

## EC2 Operations

### Instance Management

```bash
# List all instances
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name]' \
  --output table

# Output:
# |----------|------------|--------|
# |  i-1234   |  t3.micro  | running|
# |  i-5678   |  t3.micro  | running|
# |----------|------------|--------|

# List instances by environment
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=prod" \
  --query 'Reservations[*].Instances[*].{ID:InstanceId,Type:InstanceType,Name:Tags[?Key==`Name`].Value|[0]}' \
  --output table

# Get detailed instance info
aws ec2 describe-instances \
  --instance-ids i-0123456789abcdef0 \
  --query 'Reservations[0].Instances[0]' \
  --output json
```

### Instance Control

```bash
# Start instance
aws ec2 start-instances --instance-ids i-0123456789abcdef0

# Stop instance
aws ec2 stop-instances --instance-ids i-0123456789abcdef0

# Terminate instance
aws ec2 terminate-instances --instance-ids i-0123456789abcdef0

# Reboot instance
aws ec2 reboot-instances --instance-ids i-0123456789abcdef0

# Get instance status
aws ec2 describe-instance-status \
  --instance-ids i-0123456789abcdef0 \
  --query 'InstanceStatuses[0].{Status:InstanceStatus.Status,SystemStatus:SystemStatus.Status}'

# Get console output
aws ec2 get-console-output --instance-id i-0123456789abcdef0
```

### Security Group Management

```bash
# List security groups
aws ec2 describe-security-groups \
  --query 'SecurityGroups[*].[GroupId,GroupName,VpcId]' \
  --output table

# Get specific security group
aws ec2 describe-security-groups --group-ids sg-0123456789abcdef0

# Add inbound rule
aws ec2 authorize-security-group-ingress \
  --group-id sg-0123456789abcdef0 \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

# Add SSH from specific IP
aws ec2 authorize-security-group-ingress \
  --group-id sg-0123456789abcdef0 \
  --protocol tcp \
  --port 22 \
  --cidr 203.0.113.0/32

# Remove rule
aws ec2 revoke-security-group-ingress \
  --group-id sg-0123456789abcdef0 \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0
```

### Key Pair Management

```bash
# Create key pair
aws ec2 create-key-pair --key-name my-key \
  --query 'KeyMaterial' \
  --output text > my-key.pem

chmod 400 my-key.pem

# List key pairs
aws ec2 describe-key-pairs \
  --query 'KeyPairs[*].[KeyName,KeyFingerprint]' \
  --output table

# Delete key pair
aws ec2 delete-key-pair --key-name my-key

# Import existing key
aws ec2 import-key-pair \
  --key-name my-key \
  --public-key-material file://~/.ssh/id_rsa.pub
```

---

## ALB/ELB Operations

### List Load Balancers

```bash
# List all ALBs
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].[LoadBalancerName,DNSName,State.Code]' \
  --output table

# Get specific ALB
aws elbv2 describe-load-balancers \
  --names terraform-interview-demo-alb

# Get ALB with full details
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].{Name:LoadBalancerName,DNS:DNSName,AZs:AvailabilityZones,State:State.Code}' \
  --output table
```

### Target Group Management

```bash
# List target groups
aws elbv2 describe-target-groups \
  --query 'TargetGroups[*].[TargetGroupName,TargetType,Port,Protocol]' \
  --output table

# Get target group health
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:... \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Reason]' \
  --output table

# Deregister target (remove from load balancer)
aws elbv2 deregister-targets \
  --target-group-arn arn:... \
  --targets Id=i-0123456789abcdef0

# Register target
aws elbv2 register-targets \
  --target-group-arn arn:... \
  --targets Id=i-0123456789abcdef0
```

### Listener Management

```bash
# List listeners
aws elbv2 describe-listeners \
  --load-balancer-arn arn:aws:elasticloadbalancing:... \
  --query 'Listeners[*].[Port,Protocol,DefaultActions[0].Type]' \
  --output table

# Describe listener rules
aws elbv2 describe-rules \
  --listener-arn arn:aws:elasticloadbalancing:...
```

---

## CloudWatch Operations

### Alarms

```bash
# List all alarms
aws cloudwatch describe-alarms \
  --query 'MetricAlarms[*].[AlarmName,StateValue,MetricName]' \
  --output table

# List triggered alarms
aws cloudwatch describe-alarms \
  --state-value ALARM \
  --query 'MetricAlarms[*].[AlarmName,StateReason]' \
  --output table

# Get specific alarm
aws cloudwatch describe-alarms \
  --alarm-names "terraform-interview-demo-high-cpu-alarm-1" \
  --output json

# Set alarm state (for testing)
aws cloudwatch set-alarm-state \
  --alarm-name "terraform-interview-demo-high-cpu-alarm-1" \
  --state-value ALARM \
  --state-reason "Testing alarm"

# Disable alarm
aws cloudwatch disable-alarm-actions \
  --alarm-names "terraform-interview-demo-high-cpu-alarm-1"

# Enable alarm
aws cloudwatch enable-alarm-actions \
  --alarm-names "terraform-interview-demo-high-cpu-alarm-1"
```

### Metrics

```bash
# List available metrics
aws cloudwatch list-metrics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --output table

# Get metric statistics (CPU usage over time)
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-0123456789abcdef0 \
  --start-time 2024-01-15T00:00:00Z \
  --end-time 2024-01-16T00:00:00Z \
  --period 300 \
  --statistics Average,Maximum,Minimum \
  --output table

# Custom metric (push custom data)
aws cloudwatch put-metric-data \
  --namespace MyApp \
  --metric-name ProcessedRequests \
  --value 123 \
  --unit Count \
  --timestamp 2024-01-15T12:00:00Z
```

### Logs

```bash
# List log groups
aws logs describe-log-groups \
  --query 'logGroups[*].[logGroupName,storedBytes,retentionInDays]' \
  --output table

# Get log group details
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/terraform-interview-demo"

# List log streams in group
aws logs describe-log-streams \
  --log-group-name "/aws/terraform-interview-demo/application" \
  --query 'logStreams[*].[logStreamName,lastEventTimestamp]'

# Get log events (tail logs)
aws logs get-log-events \
  --log-group-name "/aws/terraform-interview-demo/application" \
  --log-stream-name "instance-1" \
  --start-from-head

# Tail logs (real-time - requires aws-cli-plugins)
aws logs tail /aws/terraform-interview-demo/application --follow
```

### Dashboards

```bash
# List dashboards
aws cloudwatch list-dashboards \
  --query 'DashboardEntries[*].[DashboardName,LastModified,Size]'

# Get dashboard body
aws cloudwatch get-dashboard \
  --dashboard-name "terraform-interview-demo-dashboard" \
  --output json

# Create dashboard
aws cloudwatch put-dashboard \
  --dashboard-name my-dashboard \
  --dashboard-body file://dashboard.json

# Delete dashboard
aws cloudwatch delete-dashboards \
  --dashboard-names "terraform-interview-demo-dashboard"
```

---

## IAM Operations

### Users & Roles

```bash
# List users
aws iam list-users \
  --query 'Users[*].[UserName,UserId,CreateDate]' \
  --output table

# List roles
aws iam list-roles \
  --query 'Roles[*].[RoleName,Arn,CreateDate]' \
  --output table

# Get role details
aws iam get-role --role-name terraform-interview-demo-ec2-role

# List role policies
aws iam list-role-policies --role-name terraform-interview-demo-ec2-role
```

### Policies

```bash
# List inline policies
aws iam list-user-policies --user-name terraform-user

# Get policy document
aws iam get-role-policy \
  --role-name terraform-interview-demo-ec2-role \
  --policy-name terraform-interview-demo-ec2-cloudwatch-policy

# Attach policy to role
aws iam attach-role-policy \
  --role-name my-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

# Detach policy
aws iam detach-role-policy \
  --role-name my-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess
```

---

## Networking Operations

### VPC Management

```bash
# List VPCs
aws ec2 describe-vpcs \
  --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Get VPC details
aws ec2 describe-vpcs --vpc-ids vpc-0123456789abcdef0

# List subnets
aws ec2 describe-subnets \
  --query 'Subnets[*].[SubnetId,VpcId,CidrBlock,AvailabilityZone]' \
  --output table

# List route tables
aws ec2 describe-route-tables \
  --query 'RouteTables[*].[RouteTableId,VpcId,Routes[*].DestinationCidrBlock]' \
  --output table
```

---

## Common Workflows

### Workflow 1: Deploy Terraform + Backup State

```bash
#!/bin/bash

# Backup existing state
aws s3 sync ./terraform-states s3://terraform-backup/

# Deploy changes
terraform apply -var-file="environments/prod.tfvars"

# Verify deployment
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=prod" \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text

# Check ALB health
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output target_group_arn) \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' \
  --output table
```

### Workflow 2: Monitor Application Health

```bash
#!/bin/bash

# Get ALB endpoint
ALB_DNS=$(terraform output -raw alb_dns_name)

# Health check
echo "Checking application health at: $ALB_DNS"

# Test endpoint
for i in {1..5}; do
  curl -s http://$ALB_DNS/health && echo " ✓" || echo " ✗"
  sleep 2
done

# Check CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HealthyHostCount \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average
```

### Workflow 3: Disaster Recovery

```bash
#!/bin/bash

# Backup current state
aws s3 cp terraform.tfstate s3://terraform-backup/prod_$(date +%s).tfstate

# List previous versions
echo "Available state versions:"
aws s3api list-object-versions \
  --bucket terraform-backup \
  --prefix prod/ \
  --query 'Versions[*].[Key,VersionId,LastModified]' \
  --output table

# To restore a specific version
VERSION_ID="abc123"
aws s3api get-object \
  --bucket terraform-backup \
  --key prod/terraform.tfstate \
  --version-id $VERSION_ID \
  terraform.tfstate.restored

# Verify restored state
terraform plan -var-file="environments/prod.tfvars"
```

---

## Interview Q&A

### Q: "Explain cp vs sync commands"

**A:**
```
Both copy files to S3, but differ in approach:

cp (copy):
- Simple file-by-file transfer
- Good for: Single files or one-time bulk uploads
- Always overwrites destination
- No comparison of existing files
- Useful for: Quick manual uploads

Example:
aws s3 cp ./file.txt s3://bucket/
aws s3 cp ./folder s3://bucket/ --recursive

sync:
- Intelligent synchronization
- Compares files by: modification time, size, ETag
- Only transfers changed files
- Can delete destination files not in source
- Useful for: Regular backups, continuous sync

Example:
aws s3 sync ./folder s3://bucket/

Production use:
I'd use sync for automated backups because it's 
efficient - only uploading changed files. This saves:
- Bandwidth
- API calls (fewer charges)
- Time

For one-time operations or when I need full control,
I'd use cp with --recursive.
```

### Q: "How do you troubleshoot ALB health check failures?"

**A:**
```
Systematic approach:

1. Check target group health:
   aws elbv2 describe-target-health --target-group-arn ...
   
   Tells me:
   - Target ID (instance ID)
   - Health status (healthy/unhealthy)
   - Reason for status
   
2. Check security group rules:
   aws ec2 describe-security-groups --group-ids sg-...
   
   Verify:
   - Inbound rule allows health check port
   - Source is ALB security group
   - Port matches health check configuration

3. SSH to instance and test:
   ssh -i key.pem ec2-user@10.0.1.x
   curl http://localhost:80/health
   
   Verify:
   - Application is running
   - Endpoint returns 200 status
   - Port is listening

4. Check ALB logs:
   aws logs get-log-events \
   --log-group-name /aws/terraform-interview-demo/alb
   
   Look for: 4XX/5XX errors, connection timeouts

5. Check CloudWatch metrics:
   aws cloudwatch get-metric-statistics \
   --metric-name HealthyHostCount
   
   Should see: Healthy count > 0

Most common causes:
1. Security group blocking traffic (70%)
2. Application not running (15%)
3. Wrong health check path (10%)
4. Timeout too short (5%)
```

### Q: "How would you automate backup of Terraform state?"

**A:**
```bash
#!/bin/bash

# Automated backup script

BUCKET="terraform-backup"
ENVIRONMENT=$1  # dev, qa, prod

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: backup.sh [dev|qa|prod]"
  exit 1
fi

# Backup state
aws s3 cp terraform.tfstate \
  s3://$BUCKET/$ENVIRONMENT/terraform_$(date +%s).tfstate

# List backup copies
echo "Backups created:"
aws s3 ls s3://$BUCKET/$ENVIRONMENT/ \
  --recursive \
  --human-readable

# Clean old backups (keep last 30 days)
aws s3 rm s3://$BUCKET/$ENVIRONMENT/ \
  --recursive \
  --exclude "*" \
  --include "terraform_*" \
  # Find files older than 30 days and delete

# Cron job to run daily:
# 0 2 * * * /path/to/backup.sh prod

In production, I'd also:
- Enable S3 versioning
- Enable MFA Delete
- Set lifecycle policies
- Monitor backup success with CloudWatch
```

---

## Summary Table

| Operation | Command | Use When |
|-----------|---------|----------|
| Copy file | `s3 cp` | Single file transfer |
| Copy folder | `s3 cp --recursive` | Entire directory, one-time |
| Sync folder | `s3 sync` | Regular backups, automated |
| List EC2 | `ec2 describe-instances` | Inventory instances |
| Check health | `elbv2 describe-target-health` | Troubleshoot ALB |
| Get metrics | `cloudwatch get-metric-statistics` | Performance analysis |
| Tail logs | `logs tail` | Debugging issues |
| Backup state | `s3 sync` + automation | Disaster recovery |

---

**💡 Key Takeaway:** Always prefer `sync` for production automation because it's idempotent (safe to run multiple times) and efficient.
