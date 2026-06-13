# DevOps & Terraform Senior Interview Guide

## Table of Contents
1. [Load Balancer Comparisons](#load-balancer-comparisons)
2. [Terraform State Management](#terraform-state-management)
3. [Modules & Reusability](#modules--reusability)
4. [Multi-Environment Architecture](#multi-environment-architecture)
5. [GitHub Actions CI/CD](#github-actions-cicd)
6. [Common Interview Questions](#common-interview-questions)
7. [Troubleshooting Scenarios](#troubleshooting-scenarios)
8. [Project Explanation](#project-explanation)

---

## Load Balancer Comparisons

### ALB vs NLB vs CLB

| Feature | ALB | NLB | CLB |
|---------|-----|-----|-----|
| **Full Name** | Application Load Balancer | Network Load Balancer | Classic Load Balancer |
| **Layer** | Layer 7 (Application) | Layer 4 (Transport) | Layer 4/7 (Mixed) |
| **Performance** | ~10K requests/sec | ~1M requests/sec | ~20K requests/sec |
| **Use Case** | Web apps, microservices | Gaming, IoT, extreme throughput | Legacy applications |
| **Path-based routing** | ✅ Yes | ❌ No | ❌ No |
| **Host-based routing** | ✅ Yes | ❌ No | ❌ No |
| **SSL/TLS offloading** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Sticky sessions** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Cost** | Moderate | High | Low |
| **Latency** | ~100ms | ~10-50ms | ~100ms |

### ALB vs NLB - When to Use

**Use ALB when:**
- Web applications (HTTP/HTTPS)
- Microservices with path-based routing
- Content-based routing needed
- WebSocket support needed
- Moderate throughput requirement
- Cost-conscious deployment

**Use NLB when:**
- Ultra-high throughput (millions of req/sec)
- Extreme low latency required
- Gaming applications
- IoT platforms
- Real-time data processing
- Non-HTTP protocols (TCP, UDP)

**Use CLB when:**
- Legacy applications
- Simple TCP/SSL load balancing
- Need backwards compatibility

---

### ALB vs CLB Detailed

| Aspect | ALB | CLB |
|--------|-----|-----|
| **Routing** | Layer 7 (hostname, path, headers) | Layer 4/7 (basic) |
| **SSL/TLS** | Full offloading | Full offloading |
| **WebSocket** | ✅ Supported | ⚠️ Limited |
| **IPv6** | ✅ Yes | ❌ No |
| **Monitoring** | Rich metrics | Basic metrics |
| **Configuration** | Target Groups | Instances directly |
| **Deployment** | Modern, recommended | Deprecated (legacy) |

### Interview Answer Example

**Q: "When would you choose ALB over NLB?"**

**A:** 
```
"ALB is ideal for web applications where we need intelligent 
routing based on hostname, path, or headers. For example, with 
a microservices architecture, I can route:

- api.example.com/users → User service
- api.example.com/orders → Order service  
- web.example.com → Web frontend

This is Layer 7 (Application) routing. 

NLB is better when I need extreme performance - millions of 
requests per second with ultra-low latency. It operates at 
Layer 4 (Transport) and is protocol-agnostic.

In this project, we chose ALB because:
1. It's cost-effective for web applications
2. Provides good performance (~10k req/s)
3. Supports sticky sessions for session affinity
4. Rich CloudWatch metrics
5. Modern AWS recommendation
"
```

---

## Terraform State Management

### What is the State File?

The `.tfstate` file is Terraform's **database** of resource reality:

```hcl
{
  "version": 4,
  "terraform_version": "1.6.0",
  "serial": 42,
  "lineage": "abc123",
  "outputs": {
    "alb_dns_name": {
      "value": "alb-123456.us-east-1.elb.amazonaws.com"
    }
  },
  "resources": [
    {
      "type": "aws_instance",
      "name": "app",
      "instances": [
        {
          "attributes": {
            "id": "i-0123456789abcdef0",
            "instance_type": "t3.micro",
            "private_ip": "10.0.1.100"
          }
        }
      ]
    }
  ]
}
```

### Local vs Remote State

| Aspect | Local State | Remote State (S3) |
|--------|------------|------------------|
| **Storage** | `.tfstate` file | S3 bucket |
| **Locking** | ❌ Manual | ✅ DynamoDB |
| **Concurrency** | ⚠️ Risky | ✅ Safe |
| **Disaster Recovery** | ❌ No backups | ✅ Versioning |
| **Team Collaboration** | ❌ Difficult | ✅ Easy |
| **Audit Trail** | ❌ None | ✅ CloudTrail |
| **Security** | ⚠️ On disk | ✅ Encrypted |

### State File Contains

```
✅ Safe:
- Resource IDs
- Resource names
- Configuration

⚠️ Sensitive (MUST PROTECT):
- Database passwords
- API keys
- Security credentials
- Private data from resources
```

### State Locking Explanation

```bash
# When you run terraform apply:

1. Terraform acquires lock in DynamoDB
   {
     "LockID": "prod/terraform.tfstate",
     "Digest": "abc123",
     "Operator": "john@example.com",
     "Reason": "Apply in progress",
     "CreatedDate": "2024-01-15T10:30:00Z"
   }

2. Terraform makes infrastructure changes

3. If another apply tries to run:
   ERROR: Error acquiring the state lock
   Lock Info:
     ID: abc123
     Path: prod/terraform.tfstate
     Operation: OperationTypeApply
     Who: john@example.com
     Version: 1.6.0
     Created: 2024-01-15 10:30:00 +0000 UTC

4. After apply completes, lock is released
```

### Disaster Recovery

```bash
# Scenario 1: State file corrupted

# Step 1: Check versioning
aws s3api list-object-versions \
  --bucket terraform-state \
  --prefix prod/

# Step 2: Restore previous version
aws s3api get-object \
  --bucket terraform-state \
  --key prod/terraform.tfstate \
  --version-id abc123 \
  terraform.tfstate

# Step 3: Verify and sync
terraform state push terraform.tfstate

# Scenario 2: State file lost completely

# Step 1: Reinitialize from scratch
terraform refresh

# Step 2: Terraform queries AWS for current state
# AWS resources still exist, terraform rebuilds state
```

### Interview Answer

**Q: "Why is state file management critical?"**

**A:**
```
"The state file is Terraform's source of truth. It maps 
what's defined in code to actual AWS resources.

Critical for several reasons:

1. **Team Collaboration**: Without remote state, team members 
   overwrite each other's changes

2. **Safety**: Locking prevents concurrent applies that could 
   corrupt infrastructure

3. **Disaster Recovery**: Versioning allows recovery if state 
   is corrupted

4. **Audit Trail**: CloudTrail logs who made what changes

In production, I always:
- Store state in S3 with versioning enabled
- Use DynamoDB for locking
- Encrypt state at rest and in transit
- Never commit .tfstate to git
- Restrict IAM access to state bucket
- Use separate state files per environment
"
```

---

## Modules & Reusability

### Module Design Principles

```hcl
# ✅ GOOD: Self-contained module
module "vpc" {
  source = "./modules/vpc"
  
  # Clear, minimal inputs
  vpc_cidr = var.vpc_cidr
  project_name = var.project_name
  
  # No hidden dependencies
  # Only depends on variables and data sources
}

# ❌ BAD: Tightly coupled
module "everything" {
  source = "./modules/everything"
  
  # Depends on other modules
  vpc_id = module.vpc.id           # Circular?
  security_group_id = module.sg.id  # Hidden dependency
  alb_arn = module.alb.arn          # Hard to test
}
```

### Why Modules?

```hcl
# Without modules (hard to reuse):
resource "aws_vpc" "prod" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_vpc" "staging" {
  cidr_block = "10.1.0.0/16"
}

resource "aws_vpc" "dev" {
  cidr_block = "10.2.0.0/16"
}
# Duplicated code!

# With modules (reusable):
module "vpc_prod" {
  source = "./modules/vpc"
  vpc_cidr = "10.0.0.0/16"
}

module "vpc_staging" {
  source = "./modules/vpc"
  vpc_cidr = "10.1.0.0/16"
}

module "vpc_dev" {
  source = "./modules/vpc"
  vpc_cidr = "10.2.0.0/16"
}
# Single source of truth for VPC logic
```

### Module Interface

```hcl
# modules/vpc/variables.tf
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be valid CIDR"
  }
}

# modules/vpc/outputs.tf
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

# Root configuration
module "vpc" {
  source = "./modules/vpc"
  vpc_cidr = "10.0.0.0/16"
}

output "network_info" {
  value = {
    vpc_id = module.vpc.vpc_id
  }
}
```

### Benefits

```
1. Code Reuse
   - DRY (Don't Repeat Yourself)
   - Single source of truth
   - Consistent across environments

2. Maintainability
   - Changes in one place affect all
   - Easier to test
   - Cleaner root configuration

3. Scalability
   - Easy to provision multiple similar resources
   - Can handle complex infrastructure
   - Team collaboration simplified

4. Testing
   - Can test modules independently
   - Mock inputs/outputs
   - Catch errors early

5. Best Practices
   - Enforces good design
   - Encapsulates complexity
   - Promotes standardization
```

---

## Multi-Environment Architecture

### Problem We're Solving

```
Without multi-env support:
- Same config for dev and prod ❌ Risky
- Manual environment switching ❌ Error-prone
- Hard to maintain differences ❌ Difficult

With multi-env support:
- Separate configs per environment ✅ Safe
- Automated environment selection ✅ Reliable
- Easy to manage differences ✅ Maintainable
```

### Implementation Approach

```hcl
# Root main.tf - Single codebase
module "vpc" {
  source = "./modules/vpc"
  vpc_cidr = var.vpc_cidr                    # From tfvars
  project_name = local.project_name
  tags = local.common_tags
}

module "ec2" {
  source = "./modules/ec2"
  instance_type = var.instance_type          # Different per env
  instance_count = var.instance_count        # Different per env
  cpu_alarm_threshold = var.cpu_alarm_threshold
}

# environments/dev.tfvars
aws_region = "us-east-1"
instance_type = "t3.micro"        # Cost-effective
instance_count = 2
cpu_alarm_threshold = 80          # Lenient

# environments/prod.tfvars
aws_region = "us-east-1"
instance_type = "t3.medium"       # Production-grade
instance_count = 3                 # High availability
cpu_alarm_threshold = 70          # Strict
```

### Deployment Process

```bash
# Develop in dev
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"

# Test in qa
terraform plan -var-file="environments/qa.tfvars"
terraform apply -var-file="environments/qa.tfvars"

# Deploy to prod
terraform plan -var-file="environments/prod.tfvars"
terraform apply -var-file="environments/prod.tfvars"

# Key benefits:
# - Same code, different configurations
# - Easy to promote changes through pipeline
# - Consistent infrastructure across environments
# - Isolated resources (VPC CIDR ranges differ)
```

---

## GitHub Actions CI/CD

### Workflow Trigger Strategy

```yaml
# terraform-plan.yml
on:
  pull_request:
    branches: [main, develop]  # On PR creation
  push:
    branches: [main, develop]  # On every push

# Validation happens automatically
# Results posted to PR
```

### terraform-plan Workflow

```
PR Created
    ↓
GitHub Actions triggered
    ↓
1. Checkout code
    ↓
2. Format check (terraform fmt)
    ↓
3. Validation (terraform validate)
    ↓
4. Security scan (tflint)
    ↓
5. Plan (terraform plan)
    ↓
6. Post summary to PR
    ↓
Engineer reviews results
```

### terraform-apply Workflow

```
Merge to main
    ↓
GitHub Actions triggered
    ↓
1. Require manual approval
    ↓
2. Safety checks (branch protection)
    ↓
3. Configure AWS credentials (OIDC)
    ↓
4. Initialize & Validate
    ↓
5. Plan infrastructure
    ↓
6. Apply changes
    ↓
7. Health check
    ↓
8. Update deployment status
    ↓
Infrastructure deployed!
```

### Security: OIDC Authentication

```yaml
# ✅ RECOMMENDED: OIDC (No stored credentials)
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789:role/GitHubActionsRole
    aws-region: us-east-1

# ❌ NOT RECOMMENDED: Static credentials
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: us-east-1
```

**OIDC Advantages:**
- No long-lived credentials stored
- Automatic credential rotation
- Audit trail in CloudTrail
- Works across multiple repos
- Follows AWS best practices

---

## Common Interview Questions

### Q1: "Explain your Terraform project structure"

**A:** 
```
"This project uses a modular approach with clear separation 
of concerns:

Root level (main.tf, variables.tf, outputs.tf):
- Orchestrates module instantiation
- Defines root-level inputs/outputs
- Uses locals for computed values

Modules (vpc/, ec2/, alb/, security-group/, monitoring/):
- VPC: Network infrastructure
- EC2: Compute instances with IAM roles
- ALB: Load balancing and health checks
- Security Groups: Network access control
- Monitoring: CloudWatch alarms and logs

Environments (dev.tfvars, qa.tfvars, prod.tfvars):
- Environment-specific variables
- Different instance types, counts, thresholds
- Separate state files per environment

This approach:
✅ Promotes code reuse
✅ Makes configuration management easy
✅ Enables multi-environment deployments
✅ Improves maintainability
✅ Follows Terraform best practices
"
```

### Q2: "How do you handle Terraform state in a team?"

**A:**
```
"State management is critical for team collaboration:

Remote State (S3):
- Store .tfstate in S3 bucket
- Enable versioning for disaster recovery
- Encrypt at rest (AES-256)
- Block public access

State Locking (DynamoDB):
- DynamoDB table with LockID as primary key
- Prevents concurrent applies
- Avoids state corruption
- Lock contains operator info and timestamp

Best Practices:
1. Never commit .tfstate to git
2. Use separate S3 buckets per environment
3. Restrict IAM access to state bucket
4. Enable MFA delete for production
5. Monitor state changes via CloudTrail
6. Backup state regularly

In CI/CD:
- GitHub Actions authenticate via OIDC
- No credentials stored in secrets
- Automatic state locking during apply
- Deploy from single pipeline
"
```

### Q3: "What's the difference between count and for_each?"

**A:**
```
"Both are used for dynamic resource creation, but differ in use cases:

count - Use for simple numbering:
resource "aws_instance" "app" {
  count = var.instance_count  # Simple number
  
  # Access via: aws_instance.app[0], app[1], etc.
  # Fragile: changing count causes indices to shift
}

Problems with count:
- Scaling from 2 to 3 instances shifts indices
- Terraform destroys old instances, creates new ones
- Entire state gets reorganized

for_each - Use for keyed resources:
resource "aws_subnet" "public" {
  for_each = {
    az1 = { cidr = "10.0.1.0/24", az = "us-east-1a" }
    az2 = { cidr = "10.0.2.0/24", az = "us-east-1b" }
  }
  
  # Access via: aws_subnet.public[\"az1\"]
  # Stable: keys remain consistent even if map changes
}

Benefits of for_each:
- Stable resource naming
- Adding/removing elements is safe
- Better for maps or complex collections
- More predictable state changes

Recommendation:
- Use count for: Simple repetition (3 instances)
- Use for_each for: Named resources (az1, az2, az3)
"
```

### Q4: "How do you ensure infrastructure changes are safe?"

**A:**
```
"Safety is multi-layered:

1. Code Review (Pull Requests)
   - terraform fmt -check verifies formatting
   - terraform validate catches syntax errors
   - tflint finds security/best practice issues
   - PR requires approval before merge

2. Plan Review
   - terraform plan shows exact changes
   - Added, modified, or deleted resources are visible
   - Engineers review before applying
   - CI posts summary to PR

3. State Management
   - State locking prevents concurrent changes
   - Versioning allows rollback
   - Separate state per environment

4. Environment Separation
   - Dev changes don't affect QA or Prod
   - Different security groups, instance types
   - Graduated rollout: dev → qa → prod

5. Approval Gates
   - Manual approval in GitHub required for production
   - Branch protection on main
   - Only certain people can trigger applies

6. Testing
   - terraform validate
   - tflint security checks
   - Pre-apply health checks
   - Post-apply health verification

7. Monitoring & Alerts
   - CloudWatch alarms on resource health
   - SNS notifications on failures
   - Application health endpoints
"
```

### Q5: "What happens when terraform apply fails halfway?"

**A:**
```
"State becomes inconsistent with actual infrastructure. Here's 
how to recover:

During apply, if something fails:

1. State is partially updated
   - Some resources created
   - Some resources failed
   - State file reflects what succeeded

2. Terraform locks the state
   - Prevents other applies from running
   - Lock contains error information

3. Recovery steps:

   Step 1: Understand what failed
   terraform state list  # See what was created
   
   Step 2: Fix the root cause
   - Check error logs
   - Verify IAM permissions
   - Check AWS service limits
   - Fix configuration
   
   Step 3: Retry apply
   terraform plan -var-file=... -out=tfplan
   terraform apply tfplan
   # Terraform detects existing resources
   # Only creates/modifies what's missing
   
   Step 4: If stuck in lock
   terraform force-unlock <LOCK_ID>  # Last resort
   
   Step 5: Verify final state
   terraform plan should show no changes

Pro tip: 
- Use -out flag to save plans
- Review plan before applying
- Apply during maintenance windows
- Keep state backups
"
```

---

## Troubleshooting Scenarios

### Scenario 1: ALB Health Check Failing

```
Problem:
- ALB showing unhealthy targets
- Instances are running but failing health checks

Root causes (in order of likelihood):
1. Security group not allowing traffic
2. Application not listening on health check port
3. Health check endpoint doesn't exist
4. Wrong health check path configured

Diagnosis:

# Check ALB target health
aws elbv2 describe-target-health \
  --target-group-arn arn:... \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Reason]'

# Check security groups
aws ec2 describe-security-groups --group-ids sg-...

# SSH to instance
ssh -i key.pem ec2-user@10.0.1.x
# Verify application is running
curl http://localhost:80/health

# Check ALB logs
aws logs tail /aws/terraform-interview-demo/alb

Solution:
1. Fix security group ingress rule
2. Start/restart application
3. Update health check path
4. Increase health check timeout if needed
```

### Scenario 2: State Lock Held by Another Process

```
Error:
Error: Error acquiring the state lock
Lock ID: abc123
Operator: jenkins@ci.internal
Reason: Apply in progress
Version: 1.6.0

Problem:
- Another terraform apply is running
- Or process crashed while holding lock

Solution:

# Option 1: Wait for other process to complete
aws dynamodb get-item \
  --table-name terraform-locks \
  --key '{"LockID": {"S": "prod/terraform.tfstate"}}'

# Option 2: If process crashed
terraform force-unlock abc123

# Verify lock is released
aws dynamodb scan --table-name terraform-locks

# Retry your apply
terraform apply tfplan
```

### Scenario 3: AWS Credentials Not Configured

```
Error:
Error: error configuring Terraform AWS Provider: 
no valid credential sources for Terraform AWS Provider found.

Solutions:

# Option 1: AWS CLI configure
aws configure
# Prompts for access key, secret key, region

# Option 2: Environment variables
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_REGION="us-east-1"

# Option 3: AWS CLI profile
export AWS_PROFILE="my-profile"

# Verify
aws sts get-caller-identity
{
  "UserId": "AIDAI...",
  "Account": "123456789",
  "Arn": "arn:aws:iam::123456789:user/terraform"
}
```

---

## Project Explanation (Interview Walkthrough)

### How to Explain During Interview

**Opening Statement (2 minutes):**
```
"I built this Terraform project to demonstrate production-grade 
infrastructure-as-code practices for AWS.

The project deploys a complete web application infrastructure 
across multiple environments (dev, qa, prod) using a modular, 
reusable Terraform codebase.

Key highlights:
- Modular design with 5 specialized modules
- Multi-environment support with tfvars
- CI/CD pipelines using GitHub Actions
- Production security best practices
- Complete CloudWatch monitoring
- State management with S3 and DynamoDB
"
```

**Architecture Walkthrough (2 minutes):**
```
"The architecture follows AWS best practices:

1. VPC (Virtual Private Cloud)
   - Single VPC with configurable CIDR
   - Two public subnets across AZs for HA
   - Internet Gateway for external access

2. Compute (EC2 Instances)
   - 2-3 instances depending on environment
   - IAM roles for AWS API access
   - CloudWatch agent for monitoring
   - Configurable instance type per environment

3. Load Balancing (ALB)
   - Application Load Balancer
   - Target group with health checks
   - Sticky sessions for session affinity
   - CloudWatch metrics for performance tracking

4. Security
   - Security groups with least privilege
   - ALB accepts public HTTP/HTTPS
   - Instances only accept from ALB or admin SSH
   - IMDSv2 only (prevents metadata attacks)

5. Monitoring
   - CloudWatch dashboards
   - CPU, network, health check alarms
   - SNS topics for notifications
   - Application logs in CloudWatch
"
```

**Module Deep Dive (3 minutes - focus on one):**
```
"Let me walk through the VPC module, which is foundational.

The VPC module has three files:

1. main.tf - Resource creation:
   - aws_vpc: Creates the VPC with specified CIDR
   - aws_internet_gateway: Public internet access
   - aws_subnet: Public subnets using for_each for AZs
   - aws_route_table: Routing rules
   - aws_route: 0.0.0.0/0 points to IGW

2. variables.tf - Input interface:
   - vpc_cidr: CIDR block with validation
   - public_subnet_cidrs: List of subnet ranges
   - project_name: For consistent naming
   - tags: Standard AWS tags

3. outputs.tf - Output interface:
   - vpc_id: Returned to root config
   - public_subnet_ids: Used by EC2 module
   - availability_zones: Zone information

Key design decisions:
- for_each for subnets makes it maintainable
- Data source for AZs keeps it dynamic
- Validation ensures correct CIDR format
- Clear inputs/outputs promote reusability
"
```

**Multi-Environment Explanation (2 minutes):**
```
"The project supports three environments with single codebase:

Dev Environment (dev.tfvars):
- t3.micro instances (cost-effective)
- 2 instances
- 80% CPU alarm threshold (lenient)
- 3-day log retention
- No deletion protection

QA Environment (qa.tfvars):
- t3.small instances
- 2 instances (HA testing)
- 75% CPU threshold
- 7-day logs
- Can test scaling

Production (prod.tfvars):
- t3.medium instances (better performance)
- 3 instances (high availability)
- 70% CPU threshold (strict)
- 30-day logs (compliance)
- Deletion protection enabled

Deployment:
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars

Same code, different configurations, different state files.
Reduces errors and ensures consistency.
"
```

**GitHub Actions CI/CD (2 minutes):**
```
"CI/CD is automated via two GitHub Actions workflows:

terraform-plan.yml:
- Triggers on PR and push
- Checks formatting with terraform fmt
- Validates syntax with terraform validate
- Security scan with tflint
- Plans infrastructure changes
- Posts summary to PR
- Artifacts saved for 7 days

terraform-apply.yml:
- Manual trigger for environment selection
- Auto-triggers on merge to main
- Requires manual approval environment gate
- Safety checks (branch protection)
- OIDC authentication (no stored credentials)
- Applies approved changes
- Health check of infrastructure
- Updates deployment status
- Slack notification (optional)

Benefits:
- No manual terraform commands needed
- Consistent validation every time
- Audit trail of all changes
- Approval gates for production
- Automated rollout through pipeline
"
```

**Security Story (2 minutes):**
```
"Security is built in at every layer:

1. Network:
   - Public subnets only, no private subnets in this demo
   - ALB faces internet, instances behind ALB
   - Security groups enforce least privilege

2. Compute:
   - IAM roles instead of access keys
   - CloudWatch agent via IAM role
   - IMDSv2 only (prevents SSRF attacks)
   - EBS volumes encrypted

3. Credentials:
   - GitHub Actions uses OIDC (no stored keys)
   - AWS credentials rotated automatically
   - No credentials in terraform files
   - .tfstate never committed to git

4. State:
   - S3 backend encrypted AES-256
   - Versioning enabled for recovery
   - DynamoDB locking prevents conflicts
   - Restricted IAM access to state bucket

5. Compliance:
   - All resources tagged with compliance info
   - CloudTrail logs all API calls
   - CloudWatch monitors for anomalies
   - Audit trail of infrastructure changes
"
```

### Common Follow-Up Questions

**Q: "How would you scale this to 100 instances?"**

A: Use Auto Scaling Groups
```hcl
module "asg" {
  source = "./modules/asg"
  
  min_size = 20
  max_size = 100
  desired_capacity = 50
  
  target_group_arn = module.alb.target_group_arn
  launch_template_id = aws_launch_template.app.id
  
  scaling_policies = [
    {
      metric = "CPUUtilization"
      threshold = 70
      scale_up = 10
      scale_down = 5
    }
  ]
}
```

**Q: "How would you handle database?"**

A: Add RDS module
```hcl
module "rds" {
  source = "./modules/rds"
  
  db_engine = "postgres"
  instance_class = "db.t3.small"
  allocated_storage = 100
  
  vpc_id = module.vpc.vpc_id
  db_subnet_group = [
    module.vpc.private_subnet_ids[0],
    module.vpc.private_subnet_ids[1]
  ]
  
  security_group_ids = [aws_security_group.rds.id]
}
```

**Q: "How would you implement blue-green deployment?"**

A: Use ALB weighted target groups
```hcl
# Blue environment
resource "aws_lb_target_group" "blue" {
  name = "app-blue"
  port = 80
}

# Green environment  
resource "aws_lb_target_group" "green" {
  name = "app-green"
  port = 80
}

# Listener with weighted routing
resource "aws_lb_listener_rule" "weighted" {
  forward_config {
    target_group {
      arn    = aws_lb_target_group.blue.arn
      weight = 90  # 90% traffic
    }
    target_group {
      arn    = aws_lb_target_group.green.arn
      weight = 10  # 10% traffic (gradual rollout)
    }
  }
}
```

---

## Final Tips

✅ **Do:**
- Explain your thought process
- Show code understanding
- Discuss trade-offs
- Talk about security
- Mention AWS best practices
- Ask clarifying questions

❌ **Don't:**
- Memorize code verbatim
- Claim expertise you don't have
- Deploy to production during interview
- Show hardcoded credentials
- Get defensive about criticism

🎯 **Interview Mindset:**
```
"I approached this project by researching Terraform and AWS 
best practices, then implementing a production-ready example.

When asked questions I don't know, I'll say 'That's a great 
question - I haven't worked with that specifically, but I'd 
approach it by...' then apply general principles.

I'm most proud of the modular design and multi-environment 
support - it shows I understand code reuse and scalability.

I'm still learning about advanced topics like Terraform 
modules in private registries and complex state management 
across multiple AWS accounts.
"
```

---

**Best of luck! 🚀**

Remember: The goal is to show you understand infrastructure-as-code principles, AWS architecture, and DevOps practices. This project is your proof of that.
