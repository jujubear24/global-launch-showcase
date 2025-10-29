# Deployment Guide

**Quick Links:** [Prerequisites](#prerequisites) | [Infrastructure](#deploy-infrastructure) | [Application](#deploy-application) | [Verify](#verify-deployment) | [Troubleshooting](#troubleshooting) | [Back to Main Docs](../README.md)

**Table of Contents**

- [Prerequisites](#prerequisites)
  - [Software Requirements](#software-requirements)
  - [AWS Account & Credentials](#aws-account--credentials)
  - [GitHub Account & Repository](#github-account--repository)
- [Configure AWS Credentials Locally](#configure-aws-credentials-locally)
- [GitHub Secrets Setup](#github-secrets-setup)
- [Deploy Infrastructure](#deploy-infrastructure)
- [Deploy Application](#deploy-application)
- [Verify Deployment](#verify-deployment)
- [Performance Baseline](#performance-baseline)
- [Next Steps](#next-steps)
- [Common Deployment Patterns](#common-deployment-patterns)
- [Cost Optimization](#cost-optimization)
- [Troubleshooting](#troubleshooting)
- [Getting Help](#getting-help)
  - [Where to Look](#where-to-look)
  - [Resources](#resources)
- [Summary](#summary)

This guide provides step-by-step instructions to deploy Aether Drone to AWS using Terraform and GitHub Actions.

---

## Prerequisites

### Software Requirements

Before deploying, ensure you have:

- **Terraform** (v1.0+)
  - [Install Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
  - Verify: `terraform version`

- **AWS CLI** (v2.0+)
  - [Install Guide](https://aws.amazon.com/cli/)
  - Verify: `aws --version`

- **Git**
  - [Install Guide](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - Verify: `git --version`

- **Node.js** (18+)
  - [Install Guide](https://nodejs.org/)
  - Verify: `node --version`

### AWS Account & Credentials

1. **Create AWS Account** at [aws.amazon.com](https://aws.amazon.com)
   - Use your email address
   - Set up payment method
   - Verify email

2. **Create IAM User** for programmatic access
   - Go to AWS Console → IAM → Users
   - Click "Create user"
   - Attach policies:
     - `AmazonS3FullAccess`
     - `CloudFrontFullAccess`
     - `AWSLambda_FullAccess`
     - `APIGatewayAdministrator`
     - `WAFFullAccess`
     - `CloudWatchLogsFullAccess`
     - `IAMFullAccess`

3. **Generate Access Keys**
   - In IAM → Your user → Security credentials
   - Click "Create access key"
   - Select "Application running outside AWS"
   - Save: Access Key ID and Secret Access Key
   - **Keep these safe!** You'll need them shortly

### GitHub Account & Repository

1. **Fork or Clone Repository**

   ```bash
   # Clone the repository
   git clone https://github.com/yourusername/aether-drone.git
   cd aether-drone
   ```

2. **Create GitHub Personal Access Token (for CI/CD)**
   - Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Click "Generate new token (classic)"
   - Name: `terraform-automation` (or similar)
   - Select scopes:
     - ✅ `repo` (all)
     - ✅ `workflow`
     - ✅ `admin:repo_hook`
   - Click "Generate token"
   - **Copy immediately** - you won't see it again!
   - Save as `GH_PAT` secret (next step)

---

## Configure AWS Credentials Locally

### Option 1: AWS CLI Configuration (Recommended)

```bash
# Interactive setup
aws configure

# You'll be prompted for:
# AWS Access Key ID: [paste your access key]
# AWS Secret Access Key: [paste your secret key]
# Default region name: us-east-1
# Default output format: json
```

### Option 2: Environment Variables

```bash
# Set credentials as environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Verify credentials work
aws sts get-caller-identity
```

### Verify Credentials Work

```bash
# Should display your AWS account info
aws sts get-caller-identity

# Output should show:
# {
#   "UserId": "AIDXXXXXXXXXXXXXXXX",
#   "Account": "123456789012",
#   "Arn": "arn:aws:iam::123456789012:user/your-username"
# }
```

---

## GitHub Secrets Setup

These secrets allow GitHub Actions to access your AWS account and update repository variables.

### Step 1: Navigate to GitHub Secrets

1. Go to your GitHub repository
2. Click **Settings** tab
3. In left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**

### Step 2: Add AWS Credentials

Create these secrets:

#### Secret 1: AWS_ACCESS_KEY_ID

- **Name:** `AWS_ACCESS_KEY_ID`
- **Value:** Your AWS access key from IAM
- Click **Add secret**

#### Secret 2: AWS_SECRET_ACCESS_KEY

- **Name:** `AWS_SECRET_ACCESS_KEY`
- **Value:** Your AWS secret key from IAM
- Click **Add secret**

#### Secret 3: GH_PAT (GitHub Personal Access Token)

- **Name:** `GH_PAT`
- **Value:** Your GitHub Personal Access Token created earlier
- Click **Add secret**

### Verify Secrets Added

After adding secrets, you should see:

```
AWS_ACCESS_KEY_ID        Added
AWS_SECRET_ACCESS_KEY    Added
GH_PAT                   Added
```

---

## Deploy Infrastructure

The infrastructure deployment creates all AWS resources (S3, CloudFront, Lambda, API Gateway, WAF, etc.).

### Prerequisites Checklist

Before proceeding, verify:

- ✅ Terraform installed
- ✅ AWS CLI configured with credentials
- ✅ GitHub repository created with secrets
- ✅ You have the `GH_PAT` token

### Step 1: Trigger Infrastructure Workflow

1. Go to your GitHub repository
2. Click **Actions** tab (top menu)
3. In left sidebar, click **Manage Infrastructure** workflow
4. Click **Run workflow** button (right side)

### Step 2: Select Action

A popup appears asking for inputs:

**Dropdown 1: Action**

- Select: `apply`

**Text Field: Confirmation**

- Type: `apply` (must match exactly)

Click **Run workflow**

### Step 3: Monitor Deployment

The workflow will run and show:

1. **Validation** (~10 seconds)

   ```
   ✅ Confirmation verified
   ```

2. **AWS Setup** (~30 seconds)

   ```
   ✅ Configured AWS Credentials
   ✅ Setup Terraform
   ```

3. **Quality Checks** (~1 minute)

   ```
   ✅ Terraform Format Check
   ✅ Terraform Validate
   ```

4. **Planning** (~2 minutes)

   ```
   Terraform will perform the following actions:
   + aws_s3_bucket.site_bucket
   + aws_cloudfront_distribution.s3_distribution
   [... 23 more resources ...]
   
   Plan: 25 to add, 0 to change, 0 to destroy.
   ```

5. **Application** (~3-5 minutes)

   ```
   ✅ Terraform Apply
   Apply complete! Resources: 25 added, 0 changed, 0 destroyed.
   ```

6. **Output & Variables** (~1 minute)

   ```
   ✅ Get Terraform Outputs
   ✅ Update Repository Variables
   
   Variables updated:
   - S3_BUCKET_NAME
   - CLOUDFRONT_DISTRIBUTION_ID
   - CLOUDFRONT_DOMAIN
   - API_GATEWAY_URL
   ```

### Step 4: Review Summary

When complete, the workflow shows a summary with:

```
## 🏗️ Infrastructure Deployment Complete

| Resource | Value |
|----------|-------|
| CloudFront URL | https://d1a2b3c4e5f6g7h8.cloudfront.net |
| S3 Bucket | aether-drone-bucket-a1b2c3d4 |
| Distribution ID | E1A2B3C4D5E6F7G8 |
| API Gateway | https://abc123.execute-api.us-east-1.amazonaws.com |

✅ Repository variables have been updated automatically.

### Next Steps
You can now deploy your application using the 'Deploy Application' workflow.
```

**Save these values** - you'll reference them later.

### Step 5: Verify Infrastructure Deployment

Check GitHub repository variables were set:

1. Go to **Settings** → **Secrets and variables** → **Variables**
2. Verify these variables exist:
   - `S3_BUCKET_NAME` - ✅ Set
   - `CLOUDFRONT_DISTRIBUTION_ID` - ✅ Set
   - `CLOUDFRONT_DOMAIN` - ✅ Set
   - `API_GATEWAY_URL` - ✅ Set

If all variables are set, **infrastructure deployment is complete!** ✅

---

## Deploy Application

The application deployment builds your Next.js frontend and uploads it to S3/CloudFront.

### Method 1: Automatic Deployment (Recommended)

Every time you push code to `main`, the application automatically deploys.

```bash
# Make changes to your site
nano app/page.tsx

# Commit changes
git add -A
git commit -m "Update hero text"

# Push to GitHub
git push origin main

# GitHub Actions automatically:
# 1. Builds your Next.js app
# 2. Uploads to S3
# 3. Invalidates CloudFront cache
# 4. Site goes live in 1-2 minutes
```

### Method 2: Manual Deployment

To deploy without making code changes:

1. Go to GitHub repository
2. Click **Actions** tab
3. Click **Deploy Application** workflow (left sidebar)
4. Click **Run workflow** button
5. Select branch: `main`
6. Click **Run workflow**

### Monitor Application Deployment

Go to **Actions** → **Deploy Application** and watch the steps:

1. **Prepare** (~30 seconds)

   ```
   ✅ Checkout code
   ✅ Setup Node.js 20
   ```

2. **Build** (~1 minute)

   ```
   ✅ Install dependencies
   ✅ Build application
   
   > next build
   ✓ Creating an optimized production build
   ✓ Compiled successfully
   ```

3. **Upload** (~1 minute)

   ```
   ✅ Configure AWS Credentials
   ✅ Deploy to S3
   
   upload: ./out/index.html to s3://bucket/index.html
   upload: ./out/_next/static/... [2000+ files]
   ```

4. **Invalidate Cache** (~30 seconds)

   ```
   ✅ Invalidate CloudFront Cache
   
   Invalidation created: I1A2B3C4D5E6F7G8H
   ```

### Step Completed

When done, you see:

```
## ✅ Application Deployed Successfully

🌐 **Live URL**: https://d1a2b3c4e5f6g7h8.cloudfront.net

⏱️ CloudFront cache invalidation in progress...
Changes will be visible in 1-2 minutes.
```

---

## Verify Deployment

### Check 1: Access Your Website

1. Get your CloudFront URL from the infrastructure deployment
   - Format: `https://d1a2b3c4e5f6g7h8.cloudfront.net`

2. Open in browser:

   ```
   https://your-cloudfront-url
   ```

3. You should see:
   - ✅ Aether Drone marketing page
   - ✅ Hero section with product image
   - ✅ Features section
   - ✅ Live Technical Insights dashboard

### Check 2: Verify Live Dashboard

The "Live Technical Insights" section should show:

1. **Your Location** - Shows your city/region/country
   - Example: "Montreal, QC (CA)"
   - ✅ If showing real location: **Working!**
   - ❌ If showing "Unknown": See [Troubleshooting](#troubleshooting)

2. **Serving Edge Location** - Shows CloudFront POP code
   - Example: "YYZ50"
   - ✅ If showing edge location code: **Working!**

3. **Threats Blocked** - Shows WAF statistics
   - Example: "47"
   - ✅ If showing number: **Working!**

### Check 3: Test Security Features

Click the **"Test Security"** button:

1. A modal appears with warning
2. Click "Proceed"
3. Browser attempts XSS attack
4. WAF blocks it → Shows "403 Forbidden"
5. Threat counter increments
6. ✅ **Security working!**

### Check 4: Verify API Endpoints

Test API calls in terminal:

```bash
# Test location endpoint
curl "https://your-cloudfront-url/default/getVisitorLocation?action=location"

# Should return:
# {
#   "city": "Montreal",
#   "region": "QC",
#   "country": "CA",
#   "edgeLocation": "YYZ50"
# }

# Test WAF endpoint
curl "https://your-cloudfront-url/default/getVisitorLocation?action=waf"

# Should return:
# {
#   "blockCount": 42
# }
```

### Check 5: Verify CloudFront Distribution

In AWS Console:

1. Go to **CloudFront** → **Distributions**
2. Find your distribution (name starts with your project name)
3. Check status: Should be **"Deployed"** (not "Deploying")
4. Click the distribution
5. Verify:
   - ✅ Origins: 2 (S3 + API Gateway)
   - ✅ Behaviors: 2 (default + /default/*)
   - ✅ WAF Web ACL: Attached
   - ✅ Certificate: Default CloudFront SSL

### Deployment Complete! ✅

If all checks pass, your Aether Drone is **live and working!**

---

## Performance Baseline

After deployment, expect these performance metrics:

| Metric | Expected |
|--------|----------|
| First Page Load | 500-1000ms (first visit) |
| Repeat Visits | 100-200ms (cached) |
| Location Detection | 50-100ms |
| WAF Block Count | 500-1000ms |
| CloudFront Cache Hit | 99%+ |

Test with: <https://pagespeed.web.dev/>

---

## Next Steps

### Option 1: Make Changes & Deploy

```bash
# Edit your site
nano app/page.tsx

# Commit & push
git add -A
git commit -m "Update content"
git push origin main

# Wait 1-2 minutes
# Visit your CloudFront URL
# Changes are live!
```

### Option 2: Update Infrastructure

To modify AWS resources:

1. Edit `terraform/main.tf`

   ```hcl
   # Example: Increase Lambda memory
   memory_size = 256  # Changed from 128
   ```

2. Commit changes

   ```bash
   git add terraform/main.tf
   git commit -m "increase lambda memory"
   git push origin main
   ```

3. Run infrastructure workflow
   - Go to **Actions** → **Manage Infrastructure**
   - Select action: `apply`
   - Confirmation: `apply`
   - Wait 3-5 minutes

### Option 3: Monitor Logs

View application logs:

```bash
# Lambda logs
aws logs tail /aws/lambda/aether-drone-api-handler --follow

# API Gateway logs
aws logs tail /aws/api-gateway/aether-drone-api-prod-stage --follow

# WAF logs
aws logs tail aws-waf-logs-aether-drone-web-acl --follow
```

---

## Common Deployment Patterns

### Pattern 1: Develop Locally, Deploy Automatically

```bash
# 1. Make changes locally
npm run dev                  # Test on localhost:3000

# 2. Push to GitHub
git add -A
git commit -m "feature: new section"
git push origin main

# 3. GitHub Actions deploys automatically (~1-2 min)

# 4. View live at CloudFront URL
```

### Pattern 2: Hotfix Deployment

```bash
# Critical bug fix
git commit -m "hotfix: fix login button"
git push origin main

# Site automatically redeployed
# No manual steps needed
```

### Pattern 3: Infrastructure Change

```bash
# Change AWS configuration
vim terraform/main.tf

# Deploy infrastructure only
# (Don't push app code yet)
# Actions → Manage Infrastructure → apply

# After infrastructure ready
git push origin main  # Deploy app
```

### Pattern 4: Rollback to Previous Version

```bash
# View deployment history
git log --oneline

# Revert to previous commit
git revert HEAD
git push origin main

# Automatic deployment with previous version
```

---

## Cost Optimization

After deployment, manage costs:

### Pause Infrastructure (Save Money)

When not using:

```bash
# Scale down infrastructure
# Go to Actions → Manage Infrastructure
# Action: destroy
# Confirmation: destroy

# All AWS resources deleted
# Monthly charges stop
# Run 'apply' again anytime to redeploy
```

### Monitor Costs

Track spending:

1. AWS Console → Billing → Bills
2. Expected monthly: $10-20
3. High usage: Check CloudFront distribution cache hit ratio

### Optimize Costs

Reduce spending:

```hcl
# In terraform/main.tf

# Reduce log retention
retention_in_days = 3  # Changed from 7

# Reduce rate limit (less CPU)
limit = 5000  # Changed from 10000

# Redeploy
```

---

## Troubleshooting

### Issue: Infrastructure Deployment Fails

**Error:**

```
Error: Error creating S3 bucket: BucketAlreadyOwnedByYou
```

**Solution:**

```bash
# Destroy and retry
cd terraform
terraform destroy
terraform apply

# Or run GitHub workflow with different project name
```

### Issue: Application Shows "Unknown" for Location

**Symptom:** Dashboard shows "Unknown" instead of city/country

**Solution:**

```bash
# Check Lambda logs
aws logs tail /aws/lambda/aether-drone-api-handler --follow

# Invalidate CloudFront
aws cloudfront create-invalidation \
  --distribution-id YOUR_DIST_ID \
  --paths "/*"

# Wait 2 minutes, refresh browser
```

### Issue: Push Doesn't Trigger Deployment

**Symptom:** GitHub Actions doesn't run after git push

**Solution:**

1. Verify you pushed to `main` branch
2. Check repository variables are set (Settings → Variables)
3. Check workflow file exists: `.github/workflows/deploy-app.yml`
4. Manually trigger: Actions → Deploy Application → Run workflow

### Issue: AWS Credentials Error

**Error:**

```
Error: Error authenticating to AWS: InvalidUserID.NotFound
```

**Solution:**

1. Verify credentials in `aws configure`:

   ```bash
   aws sts get-caller-identity
   ```

2. If fails, regenerate keys:
   - AWS Console → IAM → Your user → Security credentials
   - Delete old key
   - Create new access key
   - Update GitHub secrets

### Issue: Terraform State Locked

**Error:**

```
Error: Error acquiring the lock
```

**Solution:**

```bash
cd terraform
terraform force-unlock LOCK_ID

# Or in GitHub Actions:
# Cancel the workflow
# Re-run it
```

### Issue: CloudFront Still Shows Old Version

**Symptom:** Website shows old content even after deployment

**Solution:**

1. Wait 5 minutes (cache invalidation takes time)
2. Hard refresh browser: `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)
3. Try incognito/private window
4. Check different browser

---

## Getting Help

### Where to Look

| Problem | Documentation |
|---------|---------------|
| GitHub Actions not working | [CI-CD.md](CI-CD.md) |
| AWS resource issues | [terraform/README.md](../terraform/README.md) |
| API not responding | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) |
| Performance issues | [ARCHITECTURE.md](ARCHITECTURE.md) |

### Resources

- [AWS Documentation](https://docs.aws.amazon.com/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Help](https://docs.github.com/en/actions)
- [Next.js Documentation](https://nextjs.org/docs)

---

## Summary

✅ **Prerequisites checked**
✅ **AWS credentials configured**
✅ **GitHub secrets created**
✅ **Infrastructure deployed** (25 AWS resources)
✅ **Application deployed** (Next.js to S3/CloudFront)
✅ **Verified live** (tested all features)
✅ **Ready to iterate** (push code → auto-deploy)

Your Aether Drone is now **live and ready for production!** 🚀

---

**Need help?** See [Troubleshooting](#troubleshooting) or check [CI/CD Guide](CI-CD.md)

**Ready to make changes?** See [Next Steps](#next-steps)

**Want to understand the architecture?** See [Architecture Guide](ARCHITECTURE.md)

[Back to Main Docs](../README.md)
