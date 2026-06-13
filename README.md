## 📚 Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Repository Structure](#repository-structure)
4. [Quick Start](#quick-start)
5. [Terraform Commands](#terraform-commands)

---

## Overview

This is a **production-grade Terraform AWS infrastructure** project. It demonstrates:

✅ **Infrastructure as Code (IaC)** best practices  
✅ **Modular Terraform design** for reusability  
✅ **Multi-environment deployments** (dev, qa, prod)  
✅ **GitHub Actions CI/CD** pipelines  
✅ **AWS networking, load balancing, EC2, CloudWatch**

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet (0.0.0.0/0)                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              Application Load Balancer (ALB)                     │
│         (Multi-AZ, Health Checks, Stickiness)                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
                ▼                           ▼
    ┌─────────────────────┐    ┌─────────────────────┐
    │  Public Subnet AZ1  │    │  Public Subnet AZ2  │
    │   (10.0.1.0/24)     │    │   (10.0.2.0/24)     │
    │  ┌───────────────┐  │    │  ┌───────────────┐  │
    │  │  EC2 Instance │  │    │  │  EC2 Instance │  │
    │  │   t3.micro    │  │    │  │   t3.micro    │  │
    │  └───────────────┘  │    │  └───────────────┘  │
    └─────────────────────┘    └─────────────────────┘
            │                           │
            └─────────────┬─────────────┘
                          │
                    ┌─────┴─────┐
                    │           │
                    ▼           ▼
            ┌──────────────┐  ┌──────────────┐
            │ CloudWatch   │  │ SNS Topics   │
            │ - Metrics    │  │ - Alarms     │
            │ - Logs       │  │ - Alerts     │
            │ - Alarms     │  │              │
            └──────────────┘  └──────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                          VPC (10.0.0.0/16)                      │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │        Internet Gateway (IGW)                           │   │
│  │        Route: 0.0.0.0/0 → IGW                          │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │        Security Groups                                  │   │
│  │        - ALB-SG: 80, 443 from anywhere                 │   │
│  │        - EC2-SG: 80, 8080 from ALB-SG                 │   │
│  │        - EC2-SG: 22 from admin CIDR                   │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Repository Structure

```
terraform-interview-demo/
├── .github/workflows/
│   ├── terraform-plan.yml
│   └── terraform-apply.yml
├── modules/
│   ├── vpc/
│   ├── security-group/
│   ├── ec2/
│   ├── alb/
│   └── monitoring/
├── environments/
│   ├── dev.tfvars
│   ├── qa.tfvars
│   └── prod.tfvars
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── backend/backend.tf
```

---

## Quick Start

```bash
# 1. Clone repository
git clone <repo-url>
cd terraform-interview-demo

# 2. Configure AWS credentials
aws configure

# 3. Copy example variables
cp terraform.tfvars.example terraform.tfvars

# 4. Initialize Terraform
terraform init

# 5. Validate
terraform validate

# 6. Plan
terraform plan -var-file="environments/dev.tfvars" -out=tfplan

# 7. Apply
terraform apply tfplan

# 8. Get outputs
terraform output alb_dns_name

# 9. Clean up
terraform destroy -var-file="environments/dev.tfvars"
```

---

## Terraform Commands Quick Reference

```bash
terraform init              # Initialize
terraform validate          # Validate
terraform fmt               # Format
terraform plan -out=tfplan  # Plan
terraform apply tfplan      # Apply
terraform destroy           # Destroy
terraform state list        # List state
terraform output            # Show outputs
```

---

## Key Features

- **Modular Design**: Reusable modules for VPC, EC2, ALB, Security Groups, Monitoring
- **Multi-Environment**: dev, qa, prod with environment-specific tfvars
- **Production-Ready**: Encryption, security groups, IAM roles, CloudWatch alarms
- **CI/CD Ready**: GitHub Actions workflows for plan and apply
- **State Management**: S3 backend configuration with DynamoDB locking
- **Best Practices**: Variable validation, locals, count/for_each usage, comprehensive documentation

---

## Deployment Scenarios

### Development Environment
```bash
terraform plan -var-file="environments/dev.tfvars" -out=tfplan.dev
terraform apply tfplan.dev
```

### QA Environment
```bash
terraform plan -var-file="environments/qa.tfvars" -out=tfplan.qa
terraform apply tfplan.qa
```

### Production Environment
```bash
terraform plan -var-file="environments/prod.tfvars" -out=tfplan.prod
terraform apply tfplan.prod
```

---

## Interview Preparation

For comprehensive interview questions and answers, see [docs/interview-guide.md](docs/interview-guide.md)

Topics covered:
- Terraform state management
- Module design principles
- Multi-environment deployments
- GitHub Actions CI/CD
- AWS infrastructure best practices
- Troubleshooting scenarios

---

## Documentation

- [Complete README](docs/README.md) - Full documentation with troubleshooting
- [Interview Guide](docs/interview-guide.md) - Interview Q&A and preparation
- [AWS CLI Examples](docs/aws-cli-examples.md) - Practical AWS CLI commands

---

## AWS Resources Created

- VPC with public subnets (multi-AZ)
- Internet Gateway
- Route Tables
- 2-3 EC2 instances (configurable per environment)
- Application Load Balancer
- Target Groups and Listeners
- Security Groups (ALB & EC2)
- CloudWatch Alarms and Dashboards
- SNS Topics for notifications
- IAM Roles and Policies
- CloudWatch Logs

---

## GitHub Actions Workflows

### terraform-plan.yml
- Triggers on PR and push
- Validates, formats, and plans changes
- Posts summary to PR

### terraform-apply.yml
- Manual deployment trigger
- Requires approval for production
- Applies infrastructure changes
- Performs health checks
- Updates deployment status

---

## Requirements

- Terraform >= 1.0
- AWS CLI v2
- AWS Account with appropriate permissions
- Git

---

## Next Steps

1. Read [Complete Documentation](docs/README.md)
2. Review [Interview Guide](docs/interview-guide.md)
3. Explore module structure in `modules/` directory
4. Try local deployment with `dev.tfvars`
5. Set up GitHub Actions workflows
6. Practice explaining infrastructure during mock interview

---

**🚀 Ready to ace your DevOps interview! This project demonstrates production-grade infrastructure-as-code practices.**
