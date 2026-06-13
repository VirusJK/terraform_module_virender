# CI/CD Build and Deploy Pipeline Guide

## Overview

The complete CI/CD pipeline automates the entire software delivery process from code commit to production deployment. It integrates Docker image building, testing, and infrastructure deployment through Terraform.

---

## Pipeline Architecture

### Five Main Stages

```
Code Push/PR
    ↓
Stage 1: Build (Docker Image)
    ↓
Stage 2: Dev Test (Unit + Integration)
    ↓
Stage 3: Dev Deploy (Auto)
    ↓
Stage 4: QA Deploy (Requires Approval)
    ↓
Stage 5: Prod Deploy (Requires Approval)
    ↓
Pipeline Summary & Notifications
```

---

## Stage Details

### Stage 1: Build 🔨

**Purpose:** Build Docker image and push to registry

**Trigger:** 
- On push to `main`, `develop`, or `feature/*` branches
- On pull requests to `main` or `develop`

**Steps:**
1. Checkout repository code
2. Setup Docker Buildx for building
3. Login to GitHub Container Registry (GHCR)
4. Extract metadata (tags, versions)
5. Build Docker image with cache optimization
6. Push image to registry
7. Verify image build status

**Output:**
- Docker image: `ghcr.io/{owner}/{repo}:{tag}`
- Image digest for tracking
- Build artifacts stored for 7 days

**Configuration:**
```yaml
Docker Registry: ghcr.io
Image Name: ${{ github.repository }}
Tags:
  - Branch name
  - Semantic version (if tagged)
  - Git SHA
  - 'latest' (if main branch)
```

---

### Stage 2: Dev Test 🧪

**Purpose:** Run comprehensive tests on built application

**Trigger:** 
- After Build stage succeeds
- Runs on all branches

**Tests Performed:**

1. **Linting**
   - ESLint (Node.js)
   - Pylint/Flake8 (Python)
   - Code quality checks

2. **Unit Tests**
   - `npm test` for Node.js projects
   - `pytest` for Python projects
   - Coverage reports

3. **Integration Tests**
   - Docker Compose setup
   - End-to-end service tests
   - Database integration tests

4. **Code Coverage**
   - Coverage reports generation
   - Coverage artifacts upload

**Output:**
- Test reports
- Coverage reports
- Test artifacts (30 day retention)
- Workflow summary

**Supported Frameworks:**
- **Node.js:** npm, Jest, Mocha, ESLint
- **Python:** pytest, coverage, Pylint, Flake8
- **Docker:** docker-compose for integration tests

---

### Stage 3: Dev Deploy 🚀

**Purpose:** Deploy to development environment

**Trigger:**
- Automatic after Dev Test passes
- Only on `develop` branch pushes
- Not on pull requests

**Steps:**
1. Checkout repository
2. Configure AWS credentials (OIDC)
3. Setup Terraform
4. **Trigger Terraform Build & Deploy workflow:**
   ```yaml
   Environment: dev
   Action: apply
   TFVARS File: environments/dev.tfvars
   ```
5. Create GitHub deployment record
6. Monitor Terraform workflow execution

**Configuration Used:**
- `environments/dev.tfvars`
- Instance type: t3.micro (cost-optimized)
- Instance count: 2
- Alarm threshold: 80%
- Log retention: 3 days

**Deployment Record:**
- Created in GitHub Actions
- Status: in_progress
- Links to AWS Console

---

### Stage 4: QA Deploy ✅ (Approval Required)

**Purpose:** Deploy to QA environment with approval gate

**Trigger:**
- After Dev Deploy completes successfully
- Only on `main` branch pushes
- **Requires manual approval** in GitHub Environments

**Approval Process:**
1. Workflow waits at QA environment step
2. GitHub sends notification for approval
3. Reviewer approves/rejects in GitHub UI
4. If approved: Deploy proceeds
5. If rejected: Deployment stops

**Steps:**
1. Display approval waiting message
2. Configure AWS credentials (OIDC)
3. Setup Terraform
4. **Trigger Terraform Build & Deploy workflow:**
   ```yaml
   Environment: qa
   Action: apply
   TFVARS File: environments/qa.tfvars
   ```
5. Create GitHub deployment record
6. Monitor execution

**Configuration Used:**
- `environments/qa.tfvars`
- Instance type: t3.small (realistic testing)
- Instance count: 2
- Alarm threshold: 75%
- Log retention: 7 days

---

### Stage 5: Prod Deploy 🚨 (Manual Approval)

**Purpose:** Deploy to production environment (most controlled)

**Trigger:**
- After QA Deploy completes successfully
- Only on `main` branch pushes
- **Requires manual approval** in GitHub Environments

**Safety Features:**
1. Explicit approval gate
2. Pre-deployment verification
3. Deletion protection enabled in prod.tfvars
4. Comprehensive logging

**Approval Process:**
1. Workflow waits at Production environment step
2. GitHub sends urgent notification
3. Reviewer reviews all previous stages
4. Reviewer approves in GitHub UI
5. If approved: Production deployment proceeds
6. If rejected: No changes to production

**Pre-Deployment Checks:**
- Verify AWS credentials
- Verify Terraform version
- Confirm environment is production
- Ready status confirmation

**Steps:**
1. Display production deployment warning
2. Wait for approval
3. Configure AWS credentials (OIDC)
4. Setup Terraform
5. Run pre-deployment verification
6. **Trigger Terraform Build & Deploy workflow:**
   ```yaml
   Environment: prod
   Action: apply
   TFVARS File: environments/prod.tfvars
   Deletion Protection: Enabled
   ```
7. Create GitHub deployment record
8. Monitor execution

**Configuration Used:**
- `environments/prod.tfvars`
- Instance type: t3.medium (production grade)
- Instance count: 3 (HA)
- Alarm threshold: 70% (strict)
- Log retention: 30 days (compliance)
- Deletion protection: Enabled

---

### Final: Pipeline Summary 📊

**Purpose:** Summarize entire pipeline execution

**Output:**
- Stage-by-stage status
- Pipeline commit information
- Links to related workflows
- Optional: Slack notification

---

## Integration with Terraform Workflows

### How It Works

The CI/CD pipeline **references and triggers** the Terraform workflows:

```
build-and-deploy.yml
    ↓
    └─→ Dev Deploy Stage
            ↓
            └─→ Triggers: terraform-build-deploy.yml
                    ↓
                    ├─ Input: environment=dev, action=apply
                    ├─ Uses: environments/dev.tfvars
                    └─ Deploys infrastructure
    ↓
    └─→ QA Deploy Stage (with approval)
            ↓
            └─→ Triggers: terraform-build-deploy.yml
                    ↓
                    ├─ Input: environment=qa, action=apply
                    ├─ Uses: environments/qa.tfvars
                    └─ Deploys infrastructure
    ↓
    └─→ Prod Deploy Stage (with approval)
            ↓
            └─→ Triggers: terraform-build-deploy.yml
                    ↓
                    ├─ Input: environment=prod, action=apply
                    ├─ Uses: environments/prod.tfvars
                    └─ Deploys infrastructure
```

### Workflow Integration Code

```yaml
- name: 🚀 Trigger Terraform Build & Deploy for Dev
  uses: actions/github-script@v7
  with:
    script: |
      const workflow = await github.rest.actions.createWorkflowDispatch({
        owner: context.repo.owner,
        repo: context.repo.repo,
        workflow_id: 'terraform-build-deploy.yml',
        ref: context.ref,
        inputs: {
          environment: 'dev',
          terraform_action: 'apply',
          confirm_destructive: 'false'
        }
      });
```

This triggers the `terraform-build-deploy.yml` workflow with:
- **Environment:** dev/qa/prod
- **Action:** apply (or plan/destroy)
- **TFVARS File:** `environments/{env}.tfvars`

---

## Trigger Conditions

### Build Stage
- ✅ Push to main, develop, feature/* branches
- ✅ Pull requests to main or develop
- ✅ Paths: src/, tests/, Dockerfile, package.json, requirements.txt

### Dev Test
- ✅ After Build succeeds
- ✅ All branches

### Dev Deploy
- ✅ After Dev Test succeeds
- ✅ Push to develop branch ONLY
- ✅ NOT on pull requests
- ✅ NOT on main branch

### QA Deploy
- ✅ After Dev Deploy succeeds
- ✅ Push to main branch ONLY
- ✅ **Requires GitHub Environment Approval**
- ✅ NOT on develop branch
- ✅ NOT on pull requests

### Prod Deploy
- ✅ After QA Deploy succeeds
- ✅ Push to main branch ONLY
- ✅ **Requires GitHub Environment Approval**
- ✅ NOT on develop branch
- ✅ NOT on pull requests

---

## Repository Structure Requirements

For the pipeline to work, ensure your repository has:

```
repository/
├── src/                          # Application source code
│   ├── index.js (or main.py)
│   └── ...
├── tests/                        # Test files
│   ├── unit/
│   ├── integration/
│   └── ...
├── Dockerfile                    # Docker image definition
├── docker-compose.yml            # For integration tests (optional)
├── package.json                  # Node.js (if applicable)
├── requirements.txt              # Python (if applicable)
├── pytest.ini                    # Python tests (if applicable)
├── .github/
│   └── workflows/
│       ├── build-and-deploy.yml  # ← CI/CD Pipeline
│       ├── terraform-plan.yml    # ← Referenced
│       ├── terraform-build-deploy.yml  # ← Referenced
│       └── ...
├── environments/
│   ├── dev.tfvars
│   ├── qa.tfvars
│   └── prod.tfvars
└── modules/
    ├── vpc/
    ├── ec2/
    └── ...
```

---

## Docker Image Configuration

### Supported Base Images

```dockerfile
FROM node:18-alpine         # Node.js
FROM python:3.11-slim       # Python
FROM rust:latest            # Rust
FROM golang:1.21-alpine     # Go
```

### Docker Metadata Tags

Images are automatically tagged with:
- **Branch name:** `feature-branch`
- **Git SHA:** `abc123def456`
- **Semantic version:** `1.0.0`, `1.0`, `1`
- **Latest:** `latest` (only on main branch)

### Example Image Names

```
ghcr.io/myorg/myrepo:develop
ghcr.io/myorg/myrepo:abc123def456
ghcr.io/myorg/myrepo:1.0.0
ghcr.io/myorg/myrepo:latest
```

---

## Environment Setup

### GitHub Environment Configuration

Set up approval requirements in GitHub:

**Settings → Environments → Development**
- Deployment branches: develop

**Settings → Environments → QA**
- Deployment branches: main
- **Required reviewers:** at least 1

**Settings → Environments → Production**
- Deployment branches: main
- **Required reviewers:** at least 2
- **Restrict deployments to:** production
- **Prevent self-review:** enabled

---

## Secrets Required

### GitHub Secrets
```yaml
AWS_ACCOUNT_ID              # AWS account number
GITHUB_TOKEN                # Auto-provided
SLACK_WEBHOOK              # Optional, for notifications
```

### AWS OIDC Role
```yaml
Role Name: GitHubActionsRole
Trust Policy: Allow GitHub Actions OIDC
Permissions: EC2, ALB, CloudWatch, CloudFormation, etc.
```

---

## Deployment Process Flow

### For Develop Branch (Auto Deploy to Dev)
```
1. Code pushed to develop
2. Build: ✅ Docker image built
3. Dev Test: ✅ Tests run
4. Dev Deploy: ✅ Auto-deploys to dev.tfvars
5. Infrastructure updated in development
```

### For Main Branch (Approval Required for QA/Prod)
```
1. Code pushed to main (typically via PR merge)
2. Build: ✅ Docker image built
3. Dev Test: ✅ Tests run
4. Dev Deploy: ⏸️ Skipped (main branch only)
5. QA Deploy: ⏸️ Waiting for approval
   → Reviewer approves
   → ✅ Infrastructure updated for qa.tfvars
6. Prod Deploy: ⏸️ Waiting for approval
   → Reviewer approves (requires 2 if configured)
   → ✅ Infrastructure updated for prod.tfvars
```

---

## Monitoring and Debugging

### View Pipeline Status
1. Go to GitHub Repository
2. Actions tab
3. Select "CI/CD Build and Deploy Pipeline"
4. Click on specific run
5. View stage-by-stage logs

### Common Issues

| Issue | Solution |
|-------|----------|
| Build fails | Check Dockerfile syntax |
| Tests fail | Review test logs in Dev Test stage |
| Deploy fails | Check AWS credentials and permissions |
| Approval stuck | Verify GitHub Environment setup |
| Docker image not pushed | Check registry login credentials |

### Logs Available

- Docker build logs
- Test output (unit + integration)
- Test coverage reports
- Terraform plan output
- AWS deployment logs

---

## Optional Enhancements

### Slack Notifications

Uncomment in pipeline-summary step:
```yaml
- name: 📢 Send Slack Notification
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
```

### Email Notifications

GitHub automatically sends:
- Approval notifications
- Deployment status updates
- Failure alerts

### Custom Approvers

Set in GitHub Environments:
- Required reviewers
- Deployment branches
- Environment secrets

---

## Best Practices

1. **Always test locally first**
   ```bash
   npm test
   docker build -t myapp .
   docker-compose up
   ```

2. **Use semantic versioning**
   - Tag releases: v1.0.0, v1.1.0
   - Pipeline auto-tags Docker images

3. **Review before merging to main**
   - All tests must pass
   - Code review required
   - Automated checks enabled

4. **Approve production deployments carefully**
   - Review all changes
   - Check deployment history
   - Monitor after deployment

5. **Keep TFVARS files updated**
   - Match actual environment configs
   - Document changes
   - Version control TFVARS

---

## Troubleshooting

### Pipeline won't trigger
- Check branch name (main/develop)
- Verify file paths in trigger conditions
- Check GitHub Actions are enabled

### Tests failing
- Run tests locally: `npm test` or `pytest tests/`
- Check Docker container: `docker run -it myimage`
- Review test logs in GitHub Actions

### Deploy not triggering Terraform
- Verify terraform-build-deploy.yml exists
- Check workflow file permissions
- Verify GitHub token has access

### Approval stuck
- Check GitHub Environments configuration
- Verify reviewer permissions
- Check required reviewers count

---

## Pipeline Variables and Outputs

### Available Variables
```yaml
github.repository          # repo name
github.ref                 # branch/tag
github.sha                 # commit SHA
github.actor               # who triggered
github.run_id              # workflow run ID
env.AWS_REGION             # AWS region
```

### Outputs Passed Between Jobs
```yaml
Build Job Output:
  - image-tag: ghcr.io/.../tag
  - image-digest: sha256:abc...
  - build-status: success/failure

Dev Deploy Output:
  - deployment-status: success/failure
  - terraform-run-id: GitHub Workflow Run ID
```

---

**For questions about specific stages, check the inline comments in `build-and-deploy.yml`**

**For Terraform details, see `WORKFLOWS_GUIDE.md`**

**For infrastructure configuration, see `docs/` folder**
