# Complete GitHub Actions Workflow Integration Map

## All Workflows at a Glance

```
Repository Events
    ↓
┌───────────────────────────────────────────────────────────────┐
│                                                               │
│  On Pull Request                 On Push                      │
│  (main/develop)                  (main/develop)              │
│  ↓                               ↓                           │
│  ├─→ pr-validation.yml           ├─→ build-and-deploy.yml    │
│      ├─ Format check             │   ├─ Stage 1: Build        │
│      ├─ Validation               │   ├─ Stage 2: Dev Test    │
│      ├─ Module check             │   ├─ Stage 3: Dev Deploy  │
│      └─ Sensitive data scan      │   │   └─→ terraform-build-deploy.yml
│                                  │       (env=dev)           │
│  ├─→ terraform-plan.yml          │                           │
│  │   ├─ Plan dev env             │   ├─ Stage 4: QA Deploy   │
│  │   ├─ Plan qa env              │   │   └─→ terraform-build-deploy.yml
│  │   └─ Plan prod env            │       (env=qa, approval)  │
│  │       (using tfvars)          │                           │
│  │       (using tfvars)          │   ├─ Stage 5: Prod Deploy │
│  │       (using tfvars)          │   │   └─→ terraform-build-deploy.yml
│  │                               │       (env=prod, approval) │
│  └─→ iac-scan.yml                │                           │
│      ├─ TFLint checks            │   └─ Pipeline Summary    │
│      ├─ Security checks          │                           │
│      └─ Module analysis          │                           │
│                                  │                           │
│  Results → PR Comments           │   Results → Deployments  │
│                                  │                           │
└───────────────────────────────────────────────────────────────┘
```

---

## Detailed Workflow Interaction Diagram

### PR Validation & Planning Flow
```
Pull Request Created
    ↓
    ├─ pr-validation.yml (parallel)
    │   • Format check (terraform fmt)
    │   • Terraform validate
    │   • Module structure check
    │   • Environment files check
    │   • Sensitive data scan
    │   ↓
    │   Comments: ✅ PR Validation Passed
    │
    ├─ terraform-plan.yml (parallel)  ← Strategy Matrix [dev, qa, prod]
    │   For each environment:
    │   • Verify tfvars file exists
    │   • Terraform init (backend=false)
    │   • Terraform validate
    │   • Terraform plan -var-file=environments/{env}.tfvars
    │   • Generate plan summary
    │   ↓
    │   Comments: 
    │   • Plan for dev environment
    │   • Plan for qa environment  
    │   • Plan for prod environment
    │   (Shows additions/modifications/deletions for each)
    │
    └─ iac-scan.yml (parallel)
        • TFLint security checks
        • Encryption verification
        • IAM policy analysis
        • Security group review
        ↓
        Comments: 🛡️ IaC Security Scan Results
```

### Build and Deploy Flow (Main Branch)
```
Code Pushed to main/develop
    ↓
build-and-deploy.yml
    │
    ├─ Stage 1: Build (always runs)
    │   • Docker Buildx setup
    │   • Login to GHCR
    │   • Extract metadata (tags)
    │   • Build Docker image
    │   • Push to ghcr.io
    │   ✅ Output: Docker image (e.g., ghcr.io/owner/repo:develop)
    │
    ├─ Stage 2: Dev Test (after build)
    │   • Setup Node.js/Python environments
    │   • Install dependencies
    │   • Run linting (ESLint, Pylint)
    │   • Run unit tests
    │   • Run integration tests (docker-compose)
    │   • Generate code coverage
    │   ✅ Output: Test reports, coverage reports
    │
    ├─ Branch-Specific Routes:
    │   │
    │   ├─ If develop branch:
    │   │   └─ Stage 3: Dev Deploy
    │   │       • Auto-triggers (no approval needed)
    │   │       • Calls terraform-build-deploy.yml
    │   │       │   Inputs:
    │   │       │   • environment = dev
    │   │       │   • action = apply
    │   │       │   • TFVARS = environments/dev.tfvars
    │   │       └─ terraform-build-deploy.yml
    │   │           • Init, Validate, Plan, Apply
    │   │           • Deploys to dev infrastructure
    │   │
    │   └─ If main branch:
    │       ├─ Stage 4: QA Deploy
    │       │   • ⏸️ Waiting for Approval (GitHub Environment)
    │       │   • If Approved:
    │       │       └─ Calls terraform-build-deploy.yml
    │       │           Inputs:
    │       │           • environment = qa
    │       │           • action = apply
    │       │           • TFVARS = environments/qa.tfvars
    │       │
    │       └─ Stage 5: Prod Deploy
    │           • ⏸️ Waiting for Approval (GitHub Environment)
    │           • If Approved:
    │               └─ Calls terraform-build-deploy.yml
    │                   Inputs:
    │                   • environment = prod
    │                   • action = apply
    │                   • TFVARS = environments/prod.tfvars
    │
    └─ Pipeline Summary
        • Aggregate all stage results
        • Send notifications
```

---

## Terraform Build & Deploy Workflow (Referenced)

The `terraform-build-deploy.yml` is triggered by other workflows and provides:

```
terraform-build-deploy.yml Triggered
    ↓
    ├─ Manual Input Selection:
    │   • Environment: dev, qa, or prod
    │   • Action: plan, apply, or destroy
    │   • Confirm destructive: true/false
    │
    ├─ OR Automatic from CI/CD Pipeline:
    │   • environment = dev/qa/prod
    │   • terraform_action = apply
    │   • confirm_destructive = false
    │
    ├─ Execution Steps:
    │   1. Validate inputs
    │   2. AWS OIDC authentication
    │   3. Terraform init
    │   4. Terraform validate
    │   5. Terraform format check
    │   6. Terraform plan
    │   7. If action=apply: terraform apply
    │   8. If action=destroy: terraform destroy
    │   9. Get outputs
    │   10. Create deployment record
    │
    └─ Uses Configuration:
        • TFVARS file: environments/{environment}.tfvars
        • State backend: S3 with DynamoDB locking
        • AWS region: Configurable
```

---

## Branch-Based Workflow Routes

### Feature Branch (feature/*)
```
Code pushed to feature/myfeature
    ↓
build-and-deploy.yml triggers
    ├─ Build: ✅ Docker image created (tagged as feature-myfeature)
    ├─ Dev Test: ✅ Tests run
    ├─ Dev/QA/Prod Deploy: ⏭️ SKIPPED (feature branch)
    └─ Summary: Provided
```

### Develop Branch
```
Code pushed to develop
    ↓
build-and-deploy.yml triggers
    ├─ Build: ✅ Docker image (tagged as develop)
    ├─ Dev Test: ✅ Tests run
    ├─ Dev Deploy: ✅ AUTO - Calls terraform-build-deploy.yml (dev)
    ├─ QA Deploy: ⏭️ SKIPPED (not main branch)
    ├─ Prod Deploy: ⏭️ SKIPPED (not main branch)
    └─ Summary: Provided
```

### Main Branch
```
Code pushed to main
    ↓
build-and-deploy.yml triggers
    ├─ Build: ✅ Docker image (tagged as latest, main, sha)
    ├─ Dev Test: ✅ Tests run
    ├─ Dev Deploy: ⏭️ SKIPPED (main branch only)
    ├─ QA Deploy: ⏸️ WAITING FOR APPROVAL
    │   If Approved:
    │   ✅ Calls terraform-build-deploy.yml (qa)
    │
    ├─ Prod Deploy: ⏸️ WAITING FOR APPROVAL (after QA)
    │   If Approved:
    │   ✅ Calls terraform-build-deploy.yml (prod)
    │
    └─ Summary: Provided
```

### Pull Request
```
PR created on main or develop
    ↓
build-and-deploy.yml: ⏭️ SKIPPED
    ├─ pr-validation.yml: ✅ RUN
    │   ├─ Format check
    │   ├─ Validation
    │   └─ Structure check
    │
    ├─ terraform-plan.yml: ✅ RUN (strategy matrix)
    │   ├─ Plan for dev
    │   ├─ Plan for qa
    │   └─ Plan for prod
    │
    └─ iac-scan.yml: ✅ RUN
        └─ Security scan
```

---

## Workflow Execution Timeline

### Scenario 1: Feature Branch Merge to Develop

```
Timeline:
T+0:  Commit pushed to feature/auth-module
T+1:  ✅ build-and-deploy.yml starts
T+2:  ✅ Build (Docker) completes
T+4:  ✅ Dev Test completes
T+5:  ✅ Pipeline Summary
      Total: ~5 minutes

Result: Docker image built and tested
        No infrastructure changes
        Ready for PR review
```

### Scenario 2: PR to Main Branch

```
Timeline:
T+0:  PR created on main
T+1:  ✅ pr-validation.yml starts
T+2:  ✅ terraform-plan.yml starts (strategy: 3 jobs)
T+3:  ✅ iac-scan.yml starts
T+4:  ✅ All workflows complete
      Artifacts:
      • Validation results → PR comment
      • Plans (dev, qa, prod) → PR comments
      • Security scan → PR comment

      Total: ~4 minutes
      
Result: Comprehensive PR review ready
        All 3 environments planned
        Security assessed
        Ready for code review
```

### Scenario 3: Merge to Main → Production Deploy

```
Timeline:
T+0:  PR merged to main
T+1:  build-and-deploy.yml starts
T+2:  ✅ Build (Docker)
T+4:  ✅ Dev Test
T+5:  ⏸️ QA Deploy waits for approval
      (GitHub sends notification)

T+X:  Approver reviews & clicks "Approve"
T+X+1: 🚀 QA Deploy starts
       ├─ terraform-build-deploy.yml (env=qa)
       └─ Infrastructure updated for qa.tfvars

T+X+5: ⏸️ Prod Deploy waits for approval
      (GitHub sends notification)

T+Y:  Approver reviews & clicks "Approve"
T+Y+1: 🚀 Prod Deploy starts
       ├─ terraform-build-deploy.yml (env=prod)
       └─ Infrastructure updated for prod.tfvars

T+Y+5: ✅ Pipeline complete
       
Total: ~5 min auto + wait time + 5 min terraform x2
```

---

## Artifact Flow and Storage

### Docker Images
```
Built in: build-and-deploy.yml (Build stage)
Stored in: GitHub Container Registry (ghcr.io)
Tags: develop, main, sha, v1.0.0, latest
Retention: Configured in GHCR settings (usually 90 days)
Accessible: All deployment stages
```

### Test Reports
```
Generated in: build-and-deploy.yml (Dev Test stage)
Stored in: GitHub Actions Artifacts
Artifacts: test-reports (30 days)
Contents:
  • Coverage reports
  • Test results
  • Test logs
```

### Terraform Plans
```
Generated in: terraform-plan.yml (all 3 envs)
Generated in: terraform-build-deploy.yml
Stored in: GitHub Actions Artifacts
Artifacts: terraform-plans (7 days for PR, 30 days for deploy)
Contents:
  • tfplan-{env} (binary plan files)
  • plan-{env}.txt (human-readable output)
```

### Deployment Records
```
Created in: build-and-deploy.yml (Dev/QA/Prod Deploy stages)
Stored in: GitHub Deployments
Visible in: Repository → Deployments tab
Info:
  • Environment name
  • Commit SHA
  • Timestamp
  • Status (in_progress, success, failure)
  • Links to AWS resources
```

---

## Error Handling and Retries

### Build Fails
```
❌ Build stage fails
  ↓
Pipeline stops
  ↓
Dev Test: Skipped
QA/Prod Deploy: Skipped
  ↓
Notification: Build failed
Action: Fix Dockerfile, push again
```

### Tests Fail
```
✅ Build succeeds
❌ Dev Test fails
  ↓
Pipeline stops
  ↓
QA/Prod Deploy: Skipped
  ↓
Notification: Tests failed
Action: Fix tests, push again
```

### Terraform Plan Fails
```
✅ Build & Tests succeed
❌ terraform-plan fails (in PR or deploy)
  ↓
PR: Plan workflow fails, comment shows error
Deploy: Terraform workflow fails, error logged
  ↓
Action: Review Terraform code, fix and retry
```

### Approval Timeout
```
⏸️ Waiting for approval (no timeout)
  ↓
If never approved:
  • Workflow stays in waiting state
  • Can be cancelled manually
  • Next push to branch restarts pipeline
  ↓
Action: Manually approve or cancel
```

---

## Security Considerations

### Authentication
- **OIDC:** No stored AWS credentials
- **GitHub Secrets:** GITHUB_TOKEN (auto) + AWS_ACCOUNT_ID
- **Permissions:** Limited by OIDC role

### Approval Gates
- **QA Environment:** Requires 1 approver
- **Production:** Requires 2 approvers (recommended)
- **Enforce:** GitHub Settings → Environments

### Terraform State
- **Storage:** S3 with versioning
- **Locking:** DynamoDB prevents concurrent applies
- **Encryption:** Enabled at rest

### Docker Registry
- **Registry:** GitHub Container Registry (GHCR)
- **Privacy:** Private by default
- **Access:** Only GitHub actors with permissions

---

## Monitoring and Observability

### Check Pipeline Status
1. GitHub Repository → Actions tab
2. Select workflow (build-and-deploy, terraform-plan, etc.)
3. View run details
4. Check specific job logs

### PR Comments Show
- ✅ Validation status
- 📋 Plans for all 3 environments
- 🛡️ Security scan results
- 🔗 Links to artifacts

### Deployment Records Show
- Environment name
- Commit deployed
- Deployment status
- Timestamp
- Links to workflows

### Alerts/Notifications
- Build failures → Email + GitHub
- Approval needed → Email + GitHub
- Deployment status → Email + GitHub
- Optional: Slack notifications

---

## Common Workflows Reference

| Workflow | Trigger | Purpose | Integration |
|----------|---------|---------|-------------|
| **pr-validation.yml** | PR to main/develop | Initial validation | Standalone |
| **terraform-plan.yml** | PR to main/develop | Plan all 3 envs | Standalone |
| **iac-scan.yml** | PR to main/develop | Security scan | Standalone |
| **build-and-deploy.yml** | Push to main/develop/feature | Complete CI/CD | Calls terraform-build-deploy |
| **terraform-build-deploy.yml** | Manual OR called by build-and-deploy | Full Terraform pipeline | Referenced by build-and-deploy |

---

## Next Steps

1. **Setup GitHub Environments**
   - Settings → Environments → Create "qa" & "production"
   - Set approval requirements

2. **Configure AWS OIDC**
   - Create GitHub OIDC role in AWS
   - Set trust policy for GitHub

3. **Prepare Repository**
   - Ensure Dockerfile present
   - Add tests in tests/ directory
   - Verify tfvars files

4. **Test Pipeline**
   - Push to feature branch → Build & Test
   - Push to develop → Dev Deploy
   - Merge to main → QA Deploy (approve) → Prod Deploy (approve)

5. **Monitor**
   - Watch Actions tab
   - Review PR comments
   - Check deployments

---

**For detailed stage information, see `CI_CD_PIPELINE_GUIDE.md`**

**For Terraform workflows, see `WORKFLOWS_GUIDE.md`**

**For infrastructure config, see module documentation**
