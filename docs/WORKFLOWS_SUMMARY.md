# GitHub Actions Workflows Summary

## Complete Pipeline Overview

Your repository now has a comprehensive GitHub Actions CI/CD pipeline with 6 workflows that automate building, testing, and deploying your infrastructure and applications.

---

## 🎯 Quick Start

### For Pull Requests
When you create a PR to `main` or `develop`:
1. **pr-validation.yml** - Validates formatting and structure
2. **terraform-plan.yml** - Plans infrastructure for dev, qa, prod
3. **iac-scan.yml** - Security scans Terraform code
4. → Results appear as PR comments

### For Pushing to Develop
When you push to `develop`:
1. **build-and-deploy.yml** - Complete CI/CD pipeline
   - Builds Docker image
   - Runs tests
   - Auto-deploys to dev environment (using terraform-build-deploy.yml)

### For Pushing to Main
When you merge/push to `main`:
1. **build-and-deploy.yml** - Complete CI/CD pipeline
   - Builds Docker image
   - Runs tests
   - ⏸️ Waits for approval → Deploys to QA
   - ⏸️ Waits for approval → Deploys to Production

---

## 📋 All Workflows

### 1. **pr-validation.yml** - PR Validation
**When:** On pull requests to main/develop  
**What it does:**
- ✅ Terraform format check
- ✅ Terraform validation
- ✅ Module structure verification
- ✅ Environment files check
- ✅ Sensitive data scan
**Time:** ~2 minutes  
**Integration:** Standalone

### 2. **terraform-plan.yml** - Terraform Plan
**When:** On pull requests to main/develop  
**What it does:**
- Plans infrastructure for **dev**, **qa**, and **prod** environments
- Uses `environments/{env}.tfvars` files
- Shows resource additions/modifications/deletions
- Comments plan details on PR
**Time:** ~4 minutes (3 environments in parallel)  
**Integration:** Standalone

### 3. **iac-scan.yml** - IaC Security Scan
**When:** On pull requests to main/develop  
**What it does:**
- TFLint security checks
- Encryption verification
- IAM policy analysis
- Security group review
- Module complexity analysis
**Time:** ~2 minutes  
**Integration:** Standalone

### 4. **build-and-deploy.yml** - CI/CD Pipeline (NEW)
**When:** On push to main/develop/feature branches  
**Stages:**
1. **Build** - Docker image creation and push to GHCR
2. **Dev Test** - Unit tests, integration tests, code coverage
3. **Dev Deploy** - Auto-deploy to dev (if develop branch)
4. **QA Deploy** - Approval required, deploys to qa.tfvars
5. **Prod Deploy** - Approval required, deploys to prod.tfvars
6. **Pipeline Summary** - Final status report
**Time:** ~10-15 minutes + approval time  
**Integration:** References terraform-build-deploy.yml

### 5. **terraform-build-deploy.yml** - Terraform Build & Deploy
**When:** Manual trigger OR called by build-and-deploy.yml  
**What it does:**
- Complete Terraform pipeline: init → validate → plan → apply/destroy
- Select environment (dev/qa/prod)
- Select action (plan/apply/destroy)
- Uses selected environment's tfvars
**Time:** ~5-10 minutes depending on infrastructure size  
**Integration:** Called by build-and-deploy.yml

### 6. **terraform-apply.yml** - DEPRECATED
**Status:** ⚠️ No longer used (replaced by terraform-build-deploy.yml)  
**Action:** Can be deleted from repository

---

## 🔄 Workflow Dependencies

```
Pull Request (PR)
├─ pr-validation.yml ─────────────────┐
├─ terraform-plan.yml ────────────────┤→ Comment on PR with results
└─ iac-scan.yml ──────────────────────┘

Push to develop branch
├─ build-and-deploy.yml
│  ├─ Stage 1: Build Docker image
│  ├─ Stage 2: Dev Test
│  ├─ Stage 3: Dev Deploy
│  │   └─ Calls: terraform-build-deploy.yml (dev)
│  └─ Pipeline Summary

Push to main branch
├─ build-and-deploy.yml
│  ├─ Stage 1: Build Docker image
│  ├─ Stage 2: Dev Test
│  ├─ Stage 4: QA Deploy (⏸️ Approval Required)
│  │   └─ Calls: terraform-build-deploy.yml (qa)
│  ├─ Stage 5: Prod Deploy (⏸️ Approval Required)
│  │   └─ Calls: terraform-build-deploy.yml (prod)
│  └─ Pipeline Summary

Manual Trigger
└─ terraform-build-deploy.yml
   (Select env + action manually)
```

---

## 🚀 Docker Image Tags

Images are stored in GitHub Container Registry (GHCR) with automatic tags:

```
Branch name:      ghcr.io/owner/repo:develop
Git SHA:          ghcr.io/owner/repo:abc123def
Semantic version: ghcr.io/owner/repo:1.0.0
Latest (main):    ghcr.io/owner/repo:latest
```

---

## 🌍 Environment Configuration

Each environment uses a dedicated TFVARS file:

| Environment | File | Instance Type | Count | Alarm Threshold | Logs | Delete Protection |
|-------------|------|---|---|---|---|---|
| **Dev** | `environments/dev.tfvars` | t3.micro | 2 | 80% | 3 days | No |
| **QA** | `environments/qa.tfvars` | t3.small | 2 | 75% | 7 days | No |
| **Prod** | `environments/prod.tfvars` | t3.medium | 3 | 70% | 30 days | **Yes** |

---

## ✅ Test Coverage

**Dev Test Stage** runs:

1. **Linting**
   - ESLint (Node.js)
   - Pylint/Flake8 (Python)

2. **Unit Tests**
   - npm test
   - pytest

3. **Integration Tests**
   - docker-compose based
   - Service-to-service testing

4. **Code Coverage**
   - Coverage reports generation
   - Artifacts stored 30 days

---

## 🔐 Security Features

### Authentication
- OIDC (no stored credentials)
- GitHub Secrets for sensitive values
- Least privilege AWS permissions

### Approvals
- QA: Requires 1 reviewer
- Production: Requires 2 reviewers (recommended)
- Configurable in GitHub Environments

### Terraform Security
- State encryption (S3)
- State locking (DynamoDB)
- Deletion protection (prod only)
- Sensitive outputs masked

### Code Security
- TFLint scanning
- Encryption verification
- IAM policy analysis
- Sensitive data scanning

---

## 📊 Artifacts & Storage

| Artifact | Generated By | Storage | Retention |
|----------|---|---|---|
| Docker images | build-and-deploy | GHCR | 90 days |
| Test reports | build-and-deploy | GitHub Artifacts | 30 days |
| Terraform plans | terraform-plan.yml | GitHub Artifacts | 7 days |
| Deploy plans | terraform-build-deploy | GitHub Artifacts | 30 days |
| Deployment records | build-and-deploy | GitHub Deployments | Permanent |

---

## 🎯 Branch Strategy

### Feature Branches (`feature/*`)
```
Push to feature/my-feature
  ↓
build-and-deploy.yml
  ├─ Build: ✅ Docker image
  ├─ Dev Test: ✅ Tests run
  ├─ Deploy: ⏭️ Skipped
  └─ Result: Ready for PR
```

### Develop Branch
```
Push to develop
  ↓
build-and-deploy.yml
  ├─ Build: ✅ Docker image
  ├─ Dev Test: ✅ Tests run
  ├─ Dev Deploy: ✅ Auto (no approval)
  └─ Result: Live in dev environment
```

### Main Branch
```
Push/Merge to main
  ↓
build-and-deploy.yml
  ├─ Build: ✅ Docker image
  ├─ Dev Test: ✅ Tests run
  ├─ QA Deploy: ⏸️ Waiting for approval
  ├─ Prod Deploy: ⏸️ Waiting for approval
  └─ Result: Live in prod after approvals
```

---

## 🛠️ How to Use

### For Developers

**Make changes:**
```bash
git checkout -b feature/my-feature
# Make changes
git push origin feature/my-feature
```

**Create PR:**
- Go to GitHub
- Create PR to `develop`
- Watch pr-validation, terraform-plan, iac-scan run
- Review results in PR comments
- Get approval and merge

**Test changes:**
```bash
git push origin develop
# Watch build-and-deploy pipeline
# Changes auto-deploy to dev environment
```

### For DevOps/Release Manager

**Deploy to QA:**
1. Merge PR to `main`
2. Watch build-and-deploy pipeline
3. When QA Deploy step shows approval waiting:
   - Go to Actions → Run Details
   - Click "Review deployments"
   - Approve for QA environment
4. Infrastructure updates with qa.tfvars

**Deploy to Production:**
1. After QA deployment succeeds
2. When Prod Deploy step shows approval waiting:
   - Go to Actions → Run Details
   - Click "Review deployments"
   - Approve for Production environment
3. Infrastructure updates with prod.tfvars

### For Manual Terraform Deployments

**Plan changes:**
1. Go to Actions
2. Select "Terraform Build and Deploy"
3. Click "Run workflow"
4. Select:
   - Environment: dev, qa, or prod
   - Action: plan
5. View plan output

**Apply changes:**
1. Go to Actions
2. Select "Terraform Build and Deploy"
3. Click "Run workflow"
4. Select:
   - Environment: dev, qa, or prod
   - Action: apply
5. Monitor execution

**Destroy infrastructure:**
1. Go to Actions
2. Select "Terraform Build and Deploy"
3. Click "Run workflow"
4. Select:
   - Environment: dev, qa, or prod
   - Action: destroy
   - Confirm destructive: true
5. Infrastructure destroyed

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| `WORKFLOWS_GUIDE.md` | Detailed explanation of all workflows |
| `CI_CD_PIPELINE_GUIDE.md` | CI/CD pipeline stages and configuration |
| `WORKFLOW_INTEGRATION_MAP.md` | Visual workflow integration and flows |
| `README.md` | Main project documentation |
| `interview-guide.md` | Interview preparation materials |
| `aws-cli-examples.md` | AWS CLI reference with examples |

---

## 🔍 Monitoring

### GitHub Actions Tab
- View all workflow runs
- Click specific run to see details
- Check individual job logs
- Download artifacts

### PR Comments
- Validation results
- Plans for all environments
- Security scan findings

### Deployments Tab
- View all deployments
- Status (in_progress, success, failure)
- Environment (dev, qa, prod)
- Commit deployed

### Email Notifications
- Build failures
- Approval required notifications
- Deployment status updates

---

## ⚠️ Common Issues & Solutions

### Build fails
- Check Docker image build errors
- Verify Dockerfile syntax
- Check required files exist

### Tests fail
- Run tests locally: `npm test` or `pytest tests/`
- Fix issues and push again
- Pipeline will auto-retry

### Approval stuck
- Verify GitHub Environments are configured
- Check reviewer permissions
- Ensure required approvers count is met

### Terraform plan shows many changes
- Run `terraform refresh` locally
- Verify TFVARS file matches actual config
- Check for backend state issues

### Workflow won't trigger
- Verify file path matches trigger conditions
- Check branch name (main/develop)
- Verify GitHub Actions are enabled

---

## 🔗 Related Commands

### View Workflow Status
```bash
# Check workflow runs
gh run list --workflow=build-and-deploy.yml

# View specific run
gh run view <run-id>

# View job logs
gh run view <run-id> --log
```

### Manual Workflow Trigger
```bash
# Trigger build-and-deploy
gh workflow run build-and-deploy.yml

# Trigger terraform-build-deploy
gh workflow run terraform-build-deploy.yml \
  -f environment=dev \
  -f terraform_action=plan
```

### Download Artifacts
```bash
# List artifacts
gh run download <run-id>

# Download specific artifact
gh run download <run-id> -n terraform-plans
```

---

## 📋 Pre-Deployment Checklist

Before going live with this pipeline:

- [ ] GitHub Environments configured (dev, qa, production)
- [ ] AWS OIDC role created and trust policy set
- [ ] AWS_ACCOUNT_ID secret added to GitHub
- [ ] Dockerfile present in repository root
- [ ] tests/ directory with test files
- [ ] environments/*.tfvars files created
- [ ] modules/ directory structure correct
- [ ] .github/workflows/ files updated

---

## 🎓 Next Steps

1. **Test locally**
   ```bash
   docker build -t myapp .
   npm test  # or pytest tests/
   ```

2. **Push feature branch**
   - Pipeline will build and test
   - Results show in PR

3. **Merge to develop**
   - Pipeline auto-deploys to dev
   - Monitor dev environment

4. **Create release PR**
   - Merge develop → main
   - Trigger QA deployment with approval

5. **Approve production**
   - After QA passes
   - Approve production deployment

---

## 📞 Support

For issues or questions:
1. Check documentation files
2. Review GitHub Actions logs
3. Check AWS CloudFormation/CloudWatch
4. Review Terraform state

---

**🚀 Your CI/CD pipeline is ready to go!**

**Start by pushing code and watching the workflows run.**
