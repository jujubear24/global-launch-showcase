# GitHub Actions CI/CD Documentation

This project uses two separate GitHub Actions workflows to manage infrastructure and application deployments independently. This separation ensures fast, safe deployments while protecting your cloud infrastructure.

**Quick Links:**

- 🏗️ [Infrastructure Workflow](#workflow-1-infrastructure-management)
- 🚀 [Application Workflow](#workflow-2-application-deployment)
- 🔧 [Setup Instructions](#setup-instructions)
- ⚠️ [Troubleshooting](#troubleshooting)
- 📖 [Back to Main Docs](../README.md)


## Workflow Overview

### 🏗️ Workflow 1: Deploy Infrastructure (`deploy-infra.yml`)

**Purpose:** Manage AWS resources with Terraform
**Trigger:** Manual (GitHub Actions UI only)
**Duration:** 3-5 minutes
**Changes:** Creates/modifies/destroys AWS resources

### 🚀 Workflow 2: Deploy Application (`deploy-app.yml`)

**Purpose:** Build and deploy frontend to S3/CloudFront
**Trigger:** Automatic on push to `main` (or manual)
**Duration:** 1-2 minutes
**Changes:** Updates website content only

---

## Setup Instructions

### Step 1: Create GitHub Secrets

These credentials allow workflows to access your AWS account. Go to:
**Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Create these secrets:

| Secret | Value | How to Get |
|--------|-------|-----------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | AWS IAM → Your user → Security credentials |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | AWS IAM → Your user → Security credentials |
| `GH_PAT` | GitHub Personal Access Token | GitHub → Settings → Developer settings → Personal access tokens |

**Creating a Personal Access Token (GH_PAT):**

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Select scopes: `repo` (all), `workflow`, `admin:repo_hook`
4. Click "Generate token"
5. **Copy immediately** (you won't see it again!)
6. Paste as `GH_PAT` secret in your repository

### Step 2: Verify Repository Variables

These variables are set automatically by the infrastructure workflow, but you can view them:
**Settings** → **Secrets and variables** → **Actions** → **Variables**

Expected variables after first infrastructure deployment:

- `S3_BUCKET_NAME` - Name of your S3 bucket
- `CLOUDFRONT_DISTRIBUTION_ID` - CloudFront distribution ID
- `CLOUDFRONT_DOMAIN` - Your CloudFront URL
- `API_GATEWAY_URL` - API Gateway endpoint

---

## Workflow 1: Infrastructure Management

### What It Does

The infrastructure workflow manages your AWS resources using Terraform:

- **Apply:** Creates or updates infrastructure
- **Destroy:** Tears down all AWS resources (releases budget)

### Manual Trigger Steps

1. Go to your GitHub repository
2. Click **Actions** tab
3. Select **"Manage Infrastructure"** workflow (left sidebar)
4. Click **"Run workflow"** button
5. Choose action:
   - **apply** - Deploy infrastructure
   - **destroy** - Remove all resources
6. Enter confirmation (type the action name again)
7. Click **"Run workflow"**

### Workflow Stages Explained

#### Stage 1: Validation

```yaml
- Validate Confirmation
```

Ensures you typed the action name correctly (prevents accidental destruction)

#### Stage 2: AWS Configuration

```yaml
- Configure AWS Credentials
- Setup Terraform
```

Sets up AWS CLI and Terraform on the runner

#### Stage 3: Quality Checks

```yaml
- Terraform Format Check
- Terraform Validate
```

Verifies Terraform files are properly formatted and valid

#### Stage 4: Planning

```yaml
- Terraform Plan
```

Shows what resources will be created/modified/destroyed
**Example output:**

```
Plan: 25 to add, 0 to change, 0 to destroy.
```

#### Stage 5: Apply/Destroy

```yaml
- Terraform Apply (if apply action)
- Terraform Destroy (if destroy action)
```

Actually creates or removes resources on AWS

#### Stage 6: Output Management

```yaml
- Get Terraform Outputs
- Update Repository Variables
```

Saves important values (bucket name, distribution ID) as repository variables

### Example: First Infrastructure Deployment

1. **Trigger workflow:**
   - Action: `apply`
   - Confirmation: `apply`

2. **Workflow runs and shows:**

```
✅ Confirmation verified
✅ Infrastructure variables found
Plan: 25 to add, 0 to change, 0 to destroy.
Apply complete! Resources: 25 added, 0 changed, 0 destroyed.
```

3. **GitHub step summary shows:**
| Resource | Value |
|----------|-------|
| CloudFront URL | <https://d1a2b3c4e5f6g7h8.cloudfront.net> |
| S3 Bucket | aether-drone-bucket-x1y2z3a4 |
| Distribution ID | E1A2B3C4D5E6F7G8 |
| API Gateway | <https://abc123.execute-api.us-east-1.amazonaws.com> |

4. **Repository variables automatically updated** with these values

### Example: Destroying Infrastructure

1. **Trigger workflow:**
   - Action: `destroy`
   - Confirmation: `destroy`

2. **Workflow asks for confirmation** to ensure you meant it

3. **All AWS resources deleted:**
   - S3 bucket and files
   - CloudFront distribution
   - Lambda functions
   - API Gateway
   - WAF rules
   - CloudWatch logs
   - IAM roles

4. **Repository variables cleared** to prevent broken deployments

⚠️ **WARNING:** This is irreversible! Deletes all data.

---

## Workflow 2: Application Deployment

### What It Does

The application workflow automatically deploys your frontend every time you push to `main`:

1. ✅ Checks out your code
2. ✅ Installs Node.js dependencies
3. ✅ Builds Next.js application
4. ✅ Uploads files to S3
5. ✅ Invalidates CloudFront cache
6. ✅ Site goes live (~1-2 minutes)

### Automatic Triggers

The workflow runs automatically when:

- **✅ You push code to `main` branch**
- **✅ You modify `app/`, `public/`, `package.json`, etc.**

The workflow **skips** (doesn't run) when you only change:

- `terraform/` files
- `.github/workflows/deploy-infra.yml`
- README files
- `.gitignore`

### Manual Trigger Steps

To deploy without pushing code:

1. Go to **Actions** tab
2. Select **"Deploy Application"** workflow
3. Click **"Run workflow"** button
4. Choose branch: `main`
5. Click **"Run workflow"**

### Workflow Stages Explained

#### Stage 1: Prepare Environment

```yaml
- Checkout code
- Setup Node.js
```

Gets your code and installs Node.js 20

#### Stage 2: Build

```yaml
- Install dependencies
- Build application
```

Runs:

```bash
npm ci              # Install exact versions from lock file
npm run build       # Build Next.js (outputs to ./out)
```

**Build output in `./out/`:**

```
out/
├── index.html           # Main page
├── _next/
│   ├── static/
│   │   ├── css/
│   │   ├── js/
│   │   └── chunks/
│   └── data/
├── aether_drone.png     # Images
└── sitemap.xml
```

#### Stage 3: AWS Configuration

```yaml
- Configure AWS Credentials
- Verify Infrastructure Variables
```

Checks that bucket and distribution ID are set
**Fails if infrastructure not deployed yet**

#### Stage 4: Upload to S3

```yaml
- Deploy to S3 (2-part sync)
```

**Part 1: Static Assets (cache 1 year)**

```bash
aws s3 sync ./out s3://bucket \
  --cache-control "public, max-age=31536000, immutable" \
  --exclude "*.html" \
  --exclude "*.json"
```

Assets like `/styles.css`, `/logo.png` are cached for 1 year because they have hashed filenames that change on every build.

**Part 2: HTML & JSON (no cache)**

```bash
aws s3 sync ./out s3://bucket \
  --cache-control "public, max-age=0, must-revalidate" \
  --include "*.html" \
  --include "*.json"
```

HTML files are never cached so users always get the latest version.

#### Stage 5: Invalidate Cache

```yaml
- Invalidate CloudFront Cache
```

Tells CloudFront to clear its cache:

```bash
aws cloudfront create-invalidation \
  --distribution-id E1A2B3C4D5E6F7G8 \
  --paths "/*"
```

**Timeline:**

- 0-1 minute: Files syncing to S3
- 1-2 minutes: CloudFront cache invalidating
- 2-5 minutes: New version visible worldwide

---

## Common Scenarios

### Scenario 1: First Deployment

**Goal:** Get your site live for the first time

```bash
# Step 1: Push code to main
git add -A
git commit -m "Initial commit"
git push origin main

# Step 2: Go to GitHub Actions
# Step 3: Verify "Deploy Application" workflow runs

# Step 4: When it completes, run infrastructure workflow
# (Manual: Actions → Manage Infrastructure → Run workflow)
# Action: apply, Confirmation: apply

# Step 5: Wait 3-5 minutes for infrastructure
# Step 6: Application automatically redeployed to new infrastructure
```

### Scenario 2: Update Website Content

**Goal:** Fix a typo and redeploy

```bash
# Make your change
vim app/page.tsx           # Edit the file

# Deploy (automatic on push)
git add -A
git commit -m "Fix typo in hero text"
git push origin main

# Workflow runs automatically
# Site updated in ~1-2 minutes
```

### Scenario 3: Update Infrastructure

**Goal:** Increase Lambda memory or add WAF rule

```bash
# Make infrastructure change
vim terraform/main.tf      # Edit the file

# Commit (but don't push yet, or push to different branch)
git add terraform/main.tf
git commit -m "Increase Lambda memory to 256MB"

# Manually trigger infrastructure workflow
# (Actions → Manage Infrastructure → Run workflow)
# Action: apply, Confirmation: apply

# Wait 3-5 minutes for infrastructure update
```

### Scenario 4: Scale Down / Save Money

**Goal:** Remove infrastructure to stop charges

```bash
# Go to GitHub Actions
# → Manage Infrastructure workflow
# → Run workflow

# Action: destroy
# Confirmation: destroy

# Wait ~2 minutes
# All AWS resources deleted
# Monthly charges stopped
```

### Scenario 5: Fix Deployment Secrets

**Goal:** Application workflow keeps failing with "credentials error"

```bash
# Check secrets are set correctly:
# Settings → Secrets and variables → Actions

# Verify:
# ✅ AWS_ACCESS_KEY_ID is set
# ✅ AWS_SECRET_ACCESS_KEY is set
# ✅ GH_PAT is set (if using variable updates)

# If GH_PAT is wrong:
# - Generate new token: GitHub → Settings → Developer settings → Personal access tokens
# - Update GH_PAT in repository secrets

# Re-run workflow:
# Actions → Deploy Application → Run workflow
```

---

## Troubleshooting

### Issue: "Infrastructure variables not found"

**Error message:**

```
❌ Error: Infrastructure variables not found!
Please run the 'Deploy Infrastructure' workflow first.
```

**Cause:** You're trying to deploy application before infrastructure exists.

**Fix:**

1. Go to Actions → Manage Infrastructure
2. Click "Run workflow"
3. Action: `apply`
4. Confirmation: `apply`
5. Wait 3-5 minutes
6. Then run Deploy Application workflow again

### Issue: "Confirmation does not match action"

**Error message:**

```
❌ Error: Confirmation does not match action
Action: apply
Confirmation: deployment
```

**Cause:** You typed different words for action and confirmation.

**Fix:**

1. Go to Actions → Manage Infrastructure
2. Click "Run workflow"
3. For action, select `apply` or `destroy`
4. For confirmation, type **exactly** the same word
5. Submit

### Issue: S3 Sync Shows "Access Denied"

**Error message:**

```
An error occurred (AccessDenied) when calling the PutObject operation
```

**Cause:** AWS credentials don't have S3 permissions.

**Fix:**

```bash
# Verify credentials
aws s3 ls

# Should list your buckets
# If error, credentials are wrong or missing
```

1. Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are correct
2. Check IAM user has `AmazonS3FullAccess` policy
3. Check IAM user has `CloudFrontFullAccess` policy

### Issue: Workflow Stuck on "Terraform Plan"

**Cause:** Terraform lock file or long-running operation.

**Fix:**

```bash
# Local terminal
cd terraform
terraform force-unlock LOCK_ID

# Or in GitHub:
# Cancel the workflow (Actions → workflow run → Cancel)
# Re-run workflow
```

### Issue: "No space left on device" during build

**Cause:** Node modules or build artifacts too large.

**Fix:**
The GitHub runner has 14GB of space. If you hit this limit:

1. Clean node_modules:

```bash
npm ci --prefer-offline --no-audit
```

2. Or optimize build:

```bash
# Remove unnecessary dependencies
npm uninstall unused-package
```

### Issue: CloudFront Still Showing Old Version

**Cause:** Cache invalidation in progress or browser cache.

**Fix:**

1. Wait 5 minutes (invalidation takes time)
2. Hard refresh browser: `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)
3. Check different browser or incognito window
4. Check CloudFront distribution status in AWS Console

---

## Best Practices

### 1. Never Commit Secrets

❌ **DON'T:**

```hcl
# terraform/main.tf
api_key = "sk_live_abc123..."  # Never!
```

✅ **DO:**

```hcl
# Use environment variables or AWS Secrets Manager
api_key = var.api_key_secret
```

### 2. Branch Protection for Main

Prevent accidental merges to main:

1. Go to **Settings** → **Branches**
2. Add rule for `main`
3. Enable:
   - ✅ Require a pull request before merging
   - ✅ Require status checks to pass (verify builds pass)
   - ✅ Dismiss stale reviews

### 3. Test Locally Before Pushing

```bash
# Build locally to catch errors early
npm run build

# Check for TypeScript errors
npm run type-check

# Format code
npm run format

# Then push
git push origin main
```

### 4. Use Meaningful Commit Messages

❌ **DON'T:**

```
git commit -m "fix"
```

✅ **DO:**

```
git commit -m "fix: handle missing geolocation headers gracefully

- Add error boundary for location component
- Display fallback text when CloudFront headers missing
- Add debugging logs to Lambda handler"
```

### 5. Review Workflow Logs

When something fails:

1. Go to **Actions** tab
2. Click the failed workflow run
3. Click the failed step
4. Read the full log to understand error
5. Fix locally, then push

### 6. Keep Workflows Simple

If workflows become complex, break them into smaller steps:

```yaml
- name: Step with clear purpose
  run: command_that_does_one_thing
```

### 7. Use Workflow Status Badge

Add to your README:

```markdown
![Deploy Infrastructure](https://github.com/USERNAME/REPO/actions/workflows/deploy-infra.yml/badge.svg)
![Deploy Application](https://github.com/USERNAME/REPO/actions/workflows/deploy-app.yml/badge.svg)
```

---

## Advanced Configuration

### Custom Build Steps

Edit `.github/workflows/deploy-app.yml`:

```yaml
- name: Run custom tests
  run: npm run test

- name: Generate sitemap
  run: npm run generate-sitemap

- name: Build application
  run: npm run build
```

### Slack Notifications

Notify your team on deployment:

```yaml
- name: Notify Slack
  if: always()  # Run even if previous steps failed
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
    payload: |
      {
        "text": "Deployment ${{ job.status }}",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*Deployment ${{ job.status }}*\n${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
            }
          }
        ]
      }
```

### Conditional Steps

Only run on certain conditions:

```yaml
- name: Deploy to production
  if: github.ref == 'refs/heads/main' && github.event_name == 'push'
  run: npm run deploy
```

---

## Monitoring Workflows

### View Workflow History

**Actions** tab shows:

- ✅ All workflow runs
- 🕐 Duration of each run
- ❌ Failed workflows (with error reason)
- 👤 Who triggered it

### Workflow Usage

GitHub provides free minutes for public repositories:

- **Public repos:** Unlimited minutes
- **Private repos:** 2000 minutes/month free

View usage: **Settings** → **Billing and plans** → **Actions**

### Performance Optimization

If workflows are slow:

1. **Cache dependencies:**

```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: "20"
    cache: "npm"  # Caches node_modules
```

2. **Parallel jobs:**

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
  test:
    runs-on: ubuntu-latest
  deploy:
    needs: [build, test]  # Waits for both
```

3. **Use smaller base images:**

```yaml
runs-on: ubuntu-latest  # ✅ Fastest
# vs
runs-on: macos-latest   # Slower
runs-on: windows-latest # Slowest
```

---

## Disaster Recovery

### Lost Repository Variables

If variables get deleted, regenerate them:

```bash
cd terraform
terraform init
terraform output
```

This shows all values needed to recreate variables.

### Corrupted GitHub Secrets

If secrets are compromised:

1. Regenerate AWS keys:
   - AWS Console → IAM → Your user → Security credentials
   - Delete old access key
   - Create new access key

2. Update GitHub secret:
   - Settings → Secrets → `AWS_ACCESS_KEY_ID`
   - Update with new key

3. All future workflows use new credentials

### Infrastructure Out of Sync

If AWS was modified outside of Terraform:

```bash
cd terraform
terraform refresh    # Sync state with AWS
terraform plan       # See differences
terraform apply      # Sync infrastructure
```

---

## Quick Reference

| Task | Steps |
|------|-------|
| Deploy app | Push to `main` (automatic) |
| Deploy infrastructure | Actions → Manage Infrastructure → apply |
| Destroy infrastructure | Actions → Manage Infrastructure → destroy |
| View deployment logs | Actions → workflow name → job name → step |
| Update AWS credentials | Settings → Secrets → Update |
| Check variables | Settings → Variables |

---

## Next Steps

1. ✅ Create repository secrets (AWS credentials, GH_PAT)
2. ✅ Verify workflows exist in `.github/workflows/`
3. ✅ Run infrastructure workflow (manual trigger)
4. ✅ Push code to `main` (triggers app deployment)
5. ✅ Visit CloudFront URL to see live site
6. ✅ Set up branch protection on `main`
7. ✅ Monitor Actions tab for deployments

---

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS GitHub Actions](https://github.com/aws-actions)
- [Terraform GitHub Actions](https://github.com/hashicorp/setup-terraform)
- [GitHub Secrets Management](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
