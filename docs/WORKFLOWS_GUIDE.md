# GitHub Actions Workflows Documentation

## Overview

The workflow architecture has been restructured to provide clear separation of concerns and a modular approach to Terraform validation and deployment.

## New Workflow Structure

### 1. **PR Validation Workflow** (`pr-validation.yml`)
**Purpose:** Initial validation checks for pull requests

**Triggers:** 
- On pull requests to `main` or `develop` branches
- Runs first before other workflows

**Steps:**
- ✅ Terraform format check
- ✅ Terraform initialization (backend disabled)
- ✅ Terraform validation
- ✅ Module structure verification
- ✅ Environment files verification
- ✅ Sensitive data scan

**When to use:** Every pull request

---

### 2. **Terraform Plan Workflow** (`terraform-plan.yml`)
**Purpose:** Generate Terraform plans for all environments using tfvars files

**Triggers:**
- On pull requests to `main` or `develop` branches
- Runs after PR validation passes
- Uses matrix strategy to plan for dev, qa, and prod environments

**Steps:**
- ✅ Checkout code
- ✅ AWS OIDC authentication
- ✅ Setup Terraform
- ✅ Verify environment tfvars file exists
- ✅ Terraform init (backend disabled)
- ✅ Terraform validate
- ✅ Terraform plan using tfvars
- ✅ Generate plan summary
- ✅ Upload plan artifacts
- ✅ Comment on PR with results

**Configuration from TFVARS:**
```hcl
# Uses environments/dev.tfvars, environments/qa.tfvars, environments/prod.tfvars
# All infrastructure settings come from these files
- instance_type
- instance_count
- alarm_thresholds
- log_retention
- tags
- root_volume_size
- etc.
```

**Outputs:**
- Plan files for each environment
- Plan summary in PR comments
- Artifacts retained for 7 days

---

### 3. **IaC Scan Workflow** (`iac-scan.yml`)
**Purpose:** Security scanning for Terraform code

**Triggers:**
- On pull requests to `main` or `develop` branches
- Runs in parallel with terraform-plan workflow

**Steps:**
- ✅ Setup TFLint
- ✅ Run TFLint security checks
- ✅ Verify security best practices
- ✅ Check encryption settings
- ✅ Analyze IAM policies
- ✅ Review security groups
- ✅ Analyze module complexity
- ✅ Upload scan reports
- ✅ Comment on PR with security results

**Checks Performed:**
- TFLint rules and best practices
- Encryption verification
- IAM policy analysis
- Security group configuration review
- Module complexity analysis

---

### 4. **Terraform Build and Deploy Workflow** (`terraform-build-deploy.yml`)
**Purpose:** Complete build and deploy workflow with init, validate, plan, and apply

**Triggers:**
- Manual `workflow_dispatch` only
- Requires explicit human trigger

**Inputs:**
```yaml
environment: [dev, qa, prod]      # Target environment
terraform_action: [plan, apply, destroy]  # Action to perform
confirm_destructive: [true, false]  # Confirmation for destroy/deletions
```

**Steps (Complete Pipeline):**

1. **Validation**
   - ✅ Validate input parameters
   - ✅ Confirm destructive operations if needed

2. **Setup**
   - ✅ Checkout code
   - ✅ AWS OIDC authentication
   - ✅ Setup Terraform

3. **Build**
   - ✅ Verify tfvars file exists
   - ✅ Terraform init (with backend)
   - ✅ Terraform format check
   - ✅ Terraform validate

4. **Plan**
   - ✅ Terraform plan using tfvars
   - ✅ Generate plan summary
   - ✅ Upload plan artifacts

5. **Deploy** (if action is 'apply')
   - ✅ Terraform apply with auto-approve
   - ✅ Get terraform outputs
   - ✅ Create deployment record

6. **Destroy** (if action is 'destroy')
   - ✅ Terraform destroy with auto-approve
   - ✅ Requires confirmation

**TFVARS Usage:**
```bash
# Everything is configured via tfvars files
terraform plan -var-file="environments/prod.tfvars"
terraform apply -var-file="environments/prod.tfvars"
terraform destroy -var-file="environments/prod.tfvars"
```

---

## Workflow Flow Diagram

### For Pull Requests:
```
PR Created
   ↓
PR Validation Workflow
  ├─ Format check
  ├─ Validate
  ├─ Module structure
  ├─ Environment files
  └─ Sensitive data scan
   ↓
Terraform Plan Workflow (Parallel)  |  IaC Scan Workflow (Parallel)
├─ Plan dev                          ├─ TFLint checks
├─ Plan qa                           ├─ Security best practices
└─ Plan prod                         └─ Module analysis
   ↓
Comment on PR with results
   ↓
Code Review
   ↓
Manual Trigger (Build & Deploy)
```

### For Deployments:
```
Manual Trigger: Terraform Build & Deploy
   ↓
Select Environment (dev, qa, prod)
Select Action (plan, apply, destroy)
Confirm destructive changes
   ↓
Terraform Init ✅
Terraform Validate ✅
Terraform Format Check ✅
Terraform Plan ✅
   ↓
   ├─ If action=plan: Stop here, show plan
   ├─ If action=apply: Continue to apply
   └─ If action=destroy: Destroy infrastructure
   ↓
Terraform Apply (or Destroy) ✅
   ↓
Get Outputs ✅
Create Deployment Record ✅
```

---

## Configuration from TFVARS

All infrastructure settings are defined in environment-specific tfvars files:

### Development Environment (`environments/dev.tfvars`)
```hcl
aws_region              = "us-east-1"
vpc_cidr               = "10.0.0.0/16"
instance_type          = "t3.micro"      # Cost-optimized
instance_count         = 2
cpu_threshold          = 80              # Relaxed alarm
log_retention_days     = 3               # Short retention
enable_deletion_protection = false
```

### QA Environment (`environments/qa.tfvars`)
```hcl
aws_region              = "us-east-1"
vpc_cidr               = "10.1.0.0/16"
instance_type          = "t3.small"      # Realistic testing
instance_count         = 2
cpu_threshold          = 75              # Moderate alarm
log_retention_days     = 7
enable_deletion_protection = false
```

### Production Environment (`environments/prod.tfvars`)
```hcl
aws_region              = "us-east-1"
vpc_cidr               = "10.2.0.0/16"
instance_type          = "t3.medium"     # Production grade
instance_count         = 3               # High availability
cpu_threshold          = 70              # Strict alarm
log_retention_days     = 30              # Compliance
enable_deletion_protection = true        # Safety
```

---

## Usage Examples

### Example 1: Plan for Production
```bash
1. Go to GitHub Repository
2. Actions → Terraform Build and Deploy
3. Run workflow
4. Select:
   - Environment: prod
   - Action: plan
   - Confirm destructive: false (not needed for plan)
5. Review plan output in workflow summary
```

### Example 2: Deploy to QA
```bash
1. Go to GitHub Repository
2. Actions → Terraform Build and Deploy
3. Run workflow
4. Select:
   - Environment: qa
   - Action: apply
   - Confirm destructive: false
5. Workflow applies infrastructure from qa.tfvars
```

### Example 3: Destroy Development Environment
```bash
1. Go to GitHub Repository
2. Actions → Terraform Build and Deploy
3. Run workflow
4. Select:
   - Environment: dev
   - Action: destroy
   - Confirm destructive: true (REQUIRED for destroy)
5. Workflow destroys all infrastructure in dev environment
```

---

## Key Features

### 1. **Separated Concerns**
- Validation separate from planning
- Planning separate from deployment
- Scanning integrated in validation

### 2. **TFVARS-Driven Configuration**
- All settings in environment files
- Consistent deployment across environments
- Easy to modify configurations

### 3. **Security**
- OIDC authentication (no stored credentials)
- TFLint security scanning
- Manual approval for deployments
- Confirmation for destructive operations

### 4. **Multi-Environment Support**
- Single codebase, different configs
- dev, qa, prod environments
- Independent state management

### 5. **Transparency**
- PR comments with plan details
- Workflow summaries
- Detailed logs and artifacts

### 6. **Safety Mechanisms**
- Dry-run capability (plan only)
- Confirmation required for destroy
- Artifacts retained for 30 days
- Deployment records created

---

## Artifact Retention

| Workflow | Artifact | Retention |
|----------|----------|-----------|
| PR Validation | - | N/A |
| Terraform Plan | Plans, summaries | 7 days |
| IaC Scan | Reports | 7 days |
| Build & Deploy | Plans, outputs | 30 days |

---

## AWS Permissions Required

The OIDC role (`GitHubActionsRole`) needs permissions for:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "elasticloadbalancing:*",
        "cloudwatch:*",
        "logs:*",
        "sns:*",
        "iam:*",
        "s3:*",
        "dynamodb:*"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## Troubleshooting

### Plan Workflow Fails
1. Check TFVARS file exists: `environments/{env}.tfvars`
2. Verify TFVARS syntax is valid
3. Check AWS credentials in OIDC role

### Deploy Workflow Fails
1. Review plan output first
2. Check for destructive changes
3. Verify AWS permissions
4. Check for resource conflicts

### IaC Scan Warnings
1. Review TFLint warnings
2. Fix formatting with `terraform fmt`
3. Update code to follow best practices

---

## Migration Notes

### Old Workflow (Removed)
- `terraform-apply.yml` - No longer used
- Replaced by `terraform-build-deploy.yml`

### Key Differences
| Feature | Old | New |
|---------|-----|-----|
| Approval | Automatic on merge | Manual trigger |
| Environments | Auto-detected | Manual selection |
| Actions | Apply only | Plan/Apply/Destroy |
| Control | Limited | Full |
| Safety | Medium | High |

---

## Best Practices

1. **Always review PR comments** before merging
2. **Test in dev first** before deploying to prod
3. **Use plan action** to verify changes before applying
4. **Keep tfvars files** in sync with actual deployments
5. **Archive artifacts** for compliance
6. **Monitor deployment records** for audit trails

---

**Questions?** Check the documentation files or GitHub Actions logs for detailed error messages.
