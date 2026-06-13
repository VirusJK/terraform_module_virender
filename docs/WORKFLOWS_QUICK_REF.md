# GitHub Actions Workflows - Quick Reference Card

## Print This! 📋

---

## Workflow Quick Reference

### 🔍 **pr-validation.yml**
**Runs on:** Pull requests to main/develop  
**Time:** ~2 min  
**Does:** Format check, validation, module check  
**Output:** PR comment with validation status  
**Manual trigger:** No  

### 📊 **terraform-plan.yml**
**Runs on:** Pull requests to main/develop  
**Time:** ~4 min  
**Does:** Plans infrastructure for dev, qa, prod (all 3)  
**Output:** PR comments with plans for each env  
**Manual trigger:** No  

### 🛡️ **iac-scan.yml**
**Runs on:** Pull requests to main/develop  
**Time:** ~2 min  
**Does:** TFLint scan, security checks  
**Output:** PR comment with security findings  
**Manual trigger:** No  

### 🚀 **build-and-deploy.yml** (NEW)
**Runs on:** Push to main/develop/feature  
**Time:** ~10-15 min + approvals  
**Does:** Build → Test → Deploy (dev auto, qa/prod need approval)  
**Output:** Docker image + deployments  
**Manual trigger:** No (automatic on push)  

### 🏗️ **terraform-build-deploy.yml**
**Runs on:** Manual OR called by build-and-deploy  
**Time:** ~5-10 min  
**Does:** Full terraform pipeline (init → validate → plan → apply/destroy)  
**Output:** Infrastructure deployed + logs  
**Manual trigger:** Yes (select env + action)  

---

## Branch Behavior

| Branch | build-and-deploy | Deploy To | Approval? |
|--------|---|---|---|
| `feature/*` | ✅ Build & Test | None | N/A |
| `develop` | ✅ Build & Test | Dev Auto | No |
| `main` | ✅ Build & Test | QA then Prod | ✅ Yes |

---

## Environment TFVARS

```
Dev:   environments/dev.tfvars      (t3.micro, 2 instances, auto)
QA:    environments/qa.tfvars       (t3.small, 2 instances, approval)
Prod:  environments/prod.tfvars     (t3.medium, 3 instances, approval)
```

---

## PR Checks (3 workflows run in parallel)

```
PR Created
  ├─ pr-validation ✅ (Format, validate, structure)
  ├─ terraform-plan ✅ (Plans dev, qa, prod)
  └─ iac-scan ✅ (Security scan)
  
Results → 3 PR Comments
```

---

## Approval Flow

```
Push to main
  ↓
Build & Test ✅
  ↓
QA Deploy ⏸️ Waiting
  → Reviewer Approves
  → terraform-build-deploy (qa) runs
  ↓
Prod Deploy ⏸️ Waiting
  → Reviewer Approves
  → terraform-build-deploy (prod) runs
  ↓
Done ✅
```

---

## Manual Terraform Deployment

1. Go to Actions
2. Click "Terraform Build and Deploy"
3. Click "Run workflow"
4. Select:
   - **Environment:** dev / qa / prod
   - **Action:** plan / apply / destroy
   - **Confirm destructive:** true (only for destroy)
5. Click "Run workflow"

---

## View Results

| What | Where |
|------|-------|
| PR validation | PR Comments |
| Plans | PR Comments (all 3 envs) |
| Security scan | PR Comments |
| Build logs | Actions → build-and-deploy → Build stage |
| Test logs | Actions → build-and-deploy → Dev Test stage |
| Deployments | Repository → Deployments tab |
| Docker images | Settings → Packages and Pages → Packages |

---

## Docker Images Location

**Registry:** GitHub Container Registry (GHCR)  
**Images:** `ghcr.io/owner/repo:tag`

**Tags:**
- `develop` (from develop branch)
- `main` (from main branch)
- `feature-myname` (from feature branch)
- `abc123def` (git SHA)
- `latest` (main branch only)

---

## AWS Requirements

- **AWS Account ID:** In GitHub Secrets (AWS_ACCOUNT_ID)
- **OIDC Role:** GitHubActionsRole in AWS IAM
- **S3 Backend:** For Terraform state (optional but recommended)
- **Region:** us-east-1 (configurable in workflows)

---

## Common Commands

```bash
# View all workflow runs
gh run list

# View specific workflow
gh run view <run-id>

# Trigger workflow manually
gh workflow run terraform-build-deploy.yml -f environment=dev -f terraform_action=plan

# Download artifacts
gh run download <run-id>

# Cancel workflow
gh run cancel <run-id>
```

---

## Troubleshooting Checklist

| Problem | Check |
|---------|-------|
| Workflow won't trigger | Branch name, file paths, GH Actions enabled |
| Build fails | Dockerfile syntax, required files exist |
| Tests fail | Run tests locally first, fix and retry |
| Approval stuck | GitHub Environments configured, approver permissions |
| Deploy fails | AWS credentials, permissions, Terraform errors |
| Docker image not found | Check GHCR, verify push succeeded |
| Plan shows many changes | Run terraform refresh, check state |

---

## Architecture Diagram

```
Developer Push
    ↓
┌─────────────────────────────────┐
│ build-and-deploy.yml Pipeline   │
├─────────────────────────────────┤
│ Stage 1: Build Docker Image     │
│ Stage 2: Run Tests (Dev Test)   │
│ Stage 3: Dev Deploy (auto)      │
│ Stage 4: QA Deploy (approval)   │
│ Stage 5: Prod Deploy (approval) │
│ Stage 6: Summary                │
└─────────────────────────────────┘
    ├─ Calls terraform-build-deploy.yml
    │  └─ Full Terraform pipeline
    └─ Creates deployments
```

---

## Approval Gate Quick Steps

### Approve QA:
1. Actions → build-and-deploy → Find your run
2. Scroll down to "QA Deploy" step
3. Click "Review deployments"
4. Select QA and click "Approve"

### Approve Production:
1. Actions → build-and-deploy → Find your run
2. Scroll down to "Prod Deploy" step
3. Click "Review deployments"
4. Select production and click "Approve"

---

## Workflow Status Indicators

| Status | Meaning |
|--------|---------|
| ✅ **Green checkmark** | Workflow passed |
| ❌ **Red X** | Workflow failed |
| ⏸️ **Waiting icon** | Awaiting approval |
| ⏳ **Yellow spinner** | Running |
| ⊘ **Skipped** | Didn't run (conditions not met) |

---

## Key Files

```
.github/workflows/
├── pr-validation.yml              ← Runs on PRs
├── terraform-plan.yml              ← Runs on PRs
├── iac-scan.yml                    ← Runs on PRs
├── build-and-deploy.yml            ← Complete CI/CD (NEW)
├── terraform-build-deploy.yml      ← Infrastructure (Referenced)
└── terraform-apply.yml             ← DEPRECATED

environments/
├── dev.tfvars                      ← Dev config
├── qa.tfvars                       ← QA config
└── prod.tfvars                     ← Prod config

docs/
├── WORKFLOWS_GUIDE.md              ← Detailed workflow docs
├── CI_CD_PIPELINE_GUIDE.md         ← CI/CD pipeline stages
├── WORKFLOW_INTEGRATION_MAP.md     ← Integration diagrams
└── WORKFLOWS_SUMMARY.md            ← This summary
```

---

## Timeline Example: Feature to Production

```
Day 1: 
  10:00 - Developer creates feature branch
  10:05 - Push code
  10:06 - ✅ Build & Test pass
  10:10 - Create PR
  10:11 - ✅ PR Validation, Plans, Scan pass
  10:15 - Code review ✅
  10:30 - Merge to develop
  10:31 - ✅ build-and-deploy starts
  10:40 - ✅ Auto-deploys to dev

Day 2:
  14:00 - Release manager merges to main
  14:01 - ✅ build-and-deploy starts
  14:10 - ⏸️ Waiting for QA approval
  14:15 - Reviewer approves QA
  14:16 - ✅ Deploys to QA
  14:25 - ⏸️ Waiting for Prod approval
  14:30 - Reviewer approves Prod
  14:31 - ✅ Deploys to Production
  14:40 - ✅ Complete!

Total automated time: ~10 minutes
Total with approvals: ~40 minutes
```

---

## Debugging Commands

```bash
# Check workflow syntax
terraform fmt -check -recursive .
terraform validate

# List recent workflow runs
gh run list --workflow=build-and-deploy.yml --limit=5

# Get full workflow output
gh run view <run-id> --log > workflow.log

# Check deployment status
gh deployment list --repo owner/repo

# View specific deployment
gh deployment view <deployment-id>

# Cancel stuck workflow
gh run cancel <run-id>
```

---

## Quick Links

- **Actions Tab:** `github.com/owner/repo/actions`
- **Workflows:** `github.com/owner/repo/tree/main/.github/workflows`
- **Deployments:** `github.com/owner/repo/deployments`
- **Container Registry:** `github.com/owner?tab=packages`
- **TFVARS Files:** `github.com/owner/repo/tree/main/environments`

---

## Notes

- All workflows use GitHub Container Registry (GHCR) for Docker images
- Terraform uses S3 backend with DynamoDB locking (if configured)
- OIDC authentication prevents storing AWS credentials
- All secrets stored in GitHub Secrets (not committed to repo)
- Logs retained for 90 days in GitHub Actions

---

**Keep this card handy for quick reference! 📌**

**For detailed information, see WORKFLOWS_SUMMARY.md or specific workflow guides.**
