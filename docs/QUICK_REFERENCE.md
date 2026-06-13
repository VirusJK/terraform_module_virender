# Quick Reference Card - Terraform AWS Interview Prep

## Essential Terraform Commands

```bash
terraform init              # Initialize working directory
terraform validate          # Check configuration for errors
terraform fmt               # Format code
terraform plan -out=plan    # Plan infrastructure
terraform apply plan        # Apply infrastructure
terraform destroy           # Destroy infrastructure
terraform state list        # List resources in state
terraform output            # Show outputs
```

## Environment-Specific Deployments

```bash
# Dev Environment
terraform plan -var-file="environments/dev.tfvars" -out=tfplan.dev
terraform apply tfplan.dev

# QA Environment
terraform plan -var-file="environments/qa.tfvars" -out=tfplan.qa
terraform apply tfplan.qa

# Production Environment
terraform plan -var-file="environments/prod.tfvars" -out=tfplan.prod
terraform apply tfplan.prod
```

## AWS CLI - Commonly Used

```bash
# EC2 Instances
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name]' --output table
aws ec2 start-instances --instance-ids i-0123456789abcdef0
aws ec2 stop-instances --instance-ids i-0123456789abcdef0

# Load Balancer
aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerName,DNSName]' --output table
aws elbv2 describe-target-health --target-group-arn arn:...

# CloudWatch
aws cloudwatch describe-alarms --state-value ALARM
aws logs tail /aws/terraform-interview-demo/application --follow

# S3 (State Backup)
aws s3 sync ./terraform-states s3://terraform-backup/ --delete
aws s3 ls s3://terraform-backup/ --recursive --human-readable
```

## Key Interview Concepts

### Load Balancers

| Type | Layer | Throughput | Use Case |
|------|-------|-----------|----------|
| **ALB** | 7 (Application) | 10K req/s | Web apps, microservices |
| **NLB** | 4 (Transport) | 1M req/s | Gaming, IoT, ultra-low latency |
| **CLB** | 4/7 (Mixed) | 20K req/s | Legacy applications |

**When to use ALB:** Path-based routing, host-based routing, WebSocket support needed

**When to use NLB:** Ultra-high throughput, gaming, extreme low latency, non-HTTP protocols

### Terraform State

**Local State:**
- ❌ Not suitable for teams
- ❌ No locking mechanism
- ❌ Risk of accidental deletion

**Remote State (S3 + DynamoDB):**
- ✅ Team collaboration
- ✅ Automatic locking
- ✅ Versioning & disaster recovery
- ✅ Encrypted storage

### Modules vs Count

**Use Count:** Simple numbering
```hcl
resource "aws_instance" "app" {
  count = var.instance_count
  # Creates: app[0], app[1], app[2], ...
}
```

**Use for_each:** Named resources
```hcl
resource "aws_subnet" "public" {
  for_each = {
    az1 = { cidr = "10.0.1.0/24" }
    az2 = { cidr = "10.0.2.0/24" }
  }
  # Creates: public["az1"], public["az2"]
}
```

### Multi-Environment Strategy

```
Same Code, Different Variables:

terraform apply -var-file="environments/dev.tfvars"   # 2 x t3.micro
terraform apply -var-file="environments/qa.tfvars"    # 2 x t3.small
terraform apply -var-file="environments/prod.tfvars"  # 3 x t3.medium

Benefits:
✅ Single source of truth for infrastructure code
✅ Consistency across environments
✅ Easy to promote changes through pipeline
✅ Reduced maintenance burden
```

## Architecture Quick Reference

```
Internet
   ↓ (HTTP/HTTPS)
Application Load Balancer (port 80)
   ↓
Target Group (health checks)
   ↓
EC2 Instances (2-3 depending on env)
   ↓
CloudWatch Alarms
   ↓
SNS Topics
   ↓
Email/Slack Notifications
```

## Security Best Practices

| Layer | Practice |
|-------|----------|
| **Network** | Security groups with least privilege, restricted SSH |
| **Compute** | IAM roles, IMDSv2 only, EBS encryption |
| **State** | S3 encryption, versioning, DynamoDB locking |
| **CI/CD** | OIDC authentication, GitHub Secrets, approval gates |
| **Monitoring** | CloudWatch alarms, logs, CloudTrail audit |

## Common Troubleshooting

| Issue | Solution |
|-------|----------|
| **No credentials** | `aws configure` or set environment variables |
| **State locked** | Check DynamoDB, use `force-unlock` if needed |
| **Health check fails** | Check security groups, test endpoint manually |
| **Plan shows many changes** | Run `terraform refresh` to sync state |
| **Module not found** | Run `terraform get -update` |

## GitHub Actions CI/CD Flow

```
PR Created
   ↓
terraform-plan.yml
  - Format check ✅
  - Validate ✅
  - Plan ✅
  - Comment on PR ✅
   ↓
Code Review
   ↓
Merge to Main
   ↓
terraform-apply.yml
  - Manual approval ✅
  - Safety checks ✅
  - Apply ✅
  - Health check ✅
   ↓
Infrastructure Updated 🚀
```

## Interview Talking Points

### Opening (90 seconds)
"This is a production-grade infrastructure project demonstrating Terraform best practices across multiple AWS services. It supports dev, qa, and prod environments with a single codebase using modular design."

### Architecture (120 seconds)
"The infrastructure includes a VPC with public subnets across multiple AZs, EC2 instances behind an Application Load Balancer, security groups with least privilege, and comprehensive CloudWatch monitoring with SNS notifications."

### Key Design Decision (120 seconds)
"I chose ALB over NLB because for web applications, ALB provides intelligent Layer 7 routing with good performance at a reasonable cost. NLB would be overkill unless we needed millions of requests per second."

### State Management (90 seconds)
"State files are stored in S3 with versioning enabled for disaster recovery. DynamoDB provides locking to prevent concurrent applies that could corrupt infrastructure. This enables team collaboration safely."

### Multi-Environment (90 seconds)
"Same Terraform code with different tfvars files for each environment. Dev uses t3.micro for cost efficiency, qa uses t3.small for realistic testing, and prod uses t3.medium with strict alarms and deletion protection."

## Quick Decision Matrix

| Scenario | Action |
|----------|--------|
| New infrastructure | `terraform apply` |
| Change infrastructure | `terraform plan` → review → `terraform apply` |
| Debug issue | `terraform state show resource_name` |
| Backup state | `aws s3 sync ./terraform-states s3://backup/` |
| Rollback changes | Restore previous state from S3, apply |
| Team collaboration | Use S3 backend with DynamoDB locking |
| Multiple environments | Use `.tfvars` files |
| Prevent mistakes | Enable `deletion_protection`, approval gates |

## After the Interview

- ✅ Send thank you email
- ✅ Mention specific technologies you discussed
- ✅ Reference the project in follow-up
- ✅ Ask timeline for next steps
- ✅ Follow up after 1 week if no response

---

**Print this card and practice the talking points!** 🎯

Your 10-minute project explanation:
1. **Opening** (90 sec) - What is this?
2. **Architecture** (120 sec) - How is it structured?
3. **Key Decision** (120 sec) - Why ALB?
4. **State Management** (90 sec) - How do you manage state?
5. **Multi-Environment** (90 sec) - How do you handle dev/qa/prod?
6. **Q&A** (remaining time) - Answer interviewer questions

**Total: 10 minutes** ✅
