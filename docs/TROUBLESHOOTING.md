# Troubleshooting Guide

**Quick Links:** [Build Issues](#build-issues) | [Deployment Issues](#deployment-issues) | [Runtime Issues](#runtime-issues) | [AWS Issues](#aws-issues) | [GitHub Actions Issues](#github-actions-issues) | [Performance Issues](#performance-issues) | [Security Issues](#security-issues) | [Debug Commands](#debug-commands) | [FAQ](#faq---frequently-asked-questions) | [Disaster Recovery](#disaster-recovery-procedures) | [Back to Main Docs](../README.md)

**Table of Contents**

- [Build Issues](#build-issues)
- [Deployment Issues](#deployment-issues)
- [Runtime Issues](#runtime-issues)
- [AWS Issues](#aws-issues)
- [GitHub Actions Issues](#github-actions-issues)
- [Performance Issues](#performance-issues)
- [Security Issues](#security-issues)
- [Debug Commands](#debug-commands)
- [Getting Help](#getting-help)
- [Common Success Indicators](#common-success-indicators)
- [Still Stuck?](#still-stuck)
- [FAQ - Frequently Asked Questions](#faq---frequently-asked-questions)
- [Preventive Maintenance](#preventive-maintenance)
- [Disaster Recovery Procedures](#disaster-recovery-procedures)
- [Performance Optimization Checklist](#performance-optimization-checklist)
- [Monitoring Dashboard](#monitoring-dashboard)
- [Summary](#summary)

---

## How to Use This Guide

1. **Find your error** - Use Ctrl+F to search for key words
2. **Read the symptom** - Does it match your problem?
3. **Follow the solution** - Step-by-step fix
4. **Verify it worked** - Check the "How to Verify" section
5. **Still stuck?** - Jump to [Getting Help](#getting-help)

---

## Build Issues

### Issue: `npm install` Fails with Dependency Error

**Error message:**

```
npm error code ERESOLVE
npm error ERESOLVE could not resolve dependency conflict
```

**Cause:** Conflicting package versions in your dependencies

**Solution:**

```bash
# Option 1: Use npm legacy dependency resolution
npm install --legacy-peer-deps

# Option 2: Clean install (nuclear option)
rm -rf node_modules package-lock.json
npm install
```

**How to verify:**

```bash
npm list | head -20
# Should show dependency tree without errors
```

---

### Issue: `npm run build` Fails with Out of Memory

**Error message:**

```
FATAL ERROR: CALL_AND_RETRY_LAST Allocation failed - JavaScript heap out of memory
```

**Cause:** Not enough memory for Next.js build (usually on small CI runners)

**Solution:**

```bash
# Increase Node.js heap size
NODE_OPTIONS=--max-old-space-size=4096 npm run build

# Or in GitHub Actions, add to workflow:
# env:
#   NODE_OPTIONS: --max-old-space-size=4096
```

**How to verify:**

```bash
npm run build
# Should complete without memory errors
```

---

### Issue: TypeScript Build Errors

**Error message:**

```
error TS2345: Argument of type 'string' is not assignable to parameter of type 'number'
```

**Cause:** Type mismatches in your code

**Solution:**

```bash
# Check TypeScript errors
npm run type-check

# Fix errors in your code
vim app/page.tsx

# Common fixes:
# 1. Ensure types match: const count: number = parseInt(value)
# 2. Add type assertions: (value as string)
# 3. Check API responses: Verify response types

# Rebuild
npm run build
```

**How to verify:**

```bash
npm run type-check
# Should output: "✓ No TypeScript errors"
```

---

### Issue: Build Succeeds But Site Breaks on Load

**Symptom:** Build completes, but site shows blank page or errors

**Cause:** Runtime errors in React components

**Solution:**

```bash
# 1. Test locally first
npm run dev

# 2. Check browser console for errors
# Open DevTools (F12) → Console tab
# Look for red error messages

# 3. Common issues:
# - API endpoint not set: NEXT_PUBLIC_API_URL env variable
# - Missing image: Check public/ folder
# - Bad JavaScript: Check app/page.tsx for syntax errors

# 4. Fix and test
vim app/page.tsx
npm run dev

# 5. Rebuild
npm run build
```

**How to verify:**

```bash
npm run dev
# Open http://localhost:3000 in browser
# Check DevTools Console (F12) for errors
```

---

### Issue: Tailwind CSS Styles Not Applied

**Symptom:** Website loads but has no styling (looks broken)

**Cause:** Tailwind CSS not configured correctly

**Solution:**

```bash
# 1. Verify tailwind.config.js exists
ls tailwind.config.js

# 2. Check it includes correct paths
cat tailwind.config.js
# Should have:
# content: [
#   "./app/**/*.{js,ts,jsx,tsx}",
#   "./public/**/*.{js,ts,jsx,tsx}",
# ]

# 3. Verify globals.css imports Tailwind
grep "@tailwind" app/globals.css
# Should show:
# @tailwind base;
# @tailwind components;
# @tailwind utilities;

# 4. Rebuild
npm run build
npm run dev

# 5. Check DevTools
# Open DevTools (F12) → Elements
# Look for Tailwind classes applied
```

**How to verify:**

```bash
npm run dev
# Open http://localhost:3000
# Page should have colors, spacing, and styling
```

---

## Deployment Issues

### Issue: GitHub Workflow Fails to Trigger

**Symptom:** I pushed code but workflow didn't run

**Cause:** Workflow filter rules, wrong branch, or incorrect file path

**Solution:**

```bash
# 1. Verify you pushed to correct branch
git branch
# Should show: * main

# 2. Verify file paths match
# Edit file in correct location:
app/page.tsx        # ✅ Triggers
terraform/main.tf   # ❌ Doesn't trigger (filtered out)
README.md           # ❌ Doesn't trigger (filtered out)

# 3. Check workflow filters in .github/workflows/deploy-app.yml
grep -A 5 "paths-ignore" .github/workflows/deploy-app.yml

# 4. To force trigger workflow:
# Go to GitHub → Actions → Deploy Application
# Click "Run workflow" → Select branch: main → Run

# 5. Verify workflow runs
# Go to Actions tab, should see new run
```

**How to verify:**

```bash
# Check GitHub Actions
# Actions tab → Deploy Application
# Should show recent run with green checkmark ✅
```

---

### Issue: S3 Upload Fails with "Access Denied"

**Error message:**

```
An error occurred (AccessDenied) when calling the PutObject operation
```

**Cause:** AWS credentials in GitHub secrets are invalid or lack permissions

**Solution:**

```bash
# 1. Verify credentials work locally
aws s3 ls
# Should list your S3 buckets
# If error, credentials are wrong

# 2. Check permissions of IAM user
# Go to AWS Console → IAM → Users → Your user
# Verify policies attached:
#   - AmazonS3FullAccess
#   - CloudFrontFullAccess

# 3. Regenerate AWS access keys
# AWS Console → IAM → Users → Your user → Security credentials
# Delete old Access Key
# Create new Access Key
# Copy key and secret

# 4. Update GitHub secrets
# GitHub → Settings → Secrets → Actions
# Update AWS_ACCESS_KEY_ID
# Update AWS_SECRET_ACCESS_KEY

# 5. Re-run workflow
# Actions → Deploy Application → Run workflow
```

**How to verify:**

```bash
# Locally test S3 access
aws s3 ls s3://your-bucket-name/

# Or check deployment succeeds
# Actions → Deploy Application → Last run should be green ✅
```

---

### Issue: CloudFront Cache Not Invalidating

**Symptom:** Site still shows old version after deployment

**Cause:** Cache invalidation in progress or failed

**Solution:**

```bash
# 1. Wait 5 minutes
# CloudFront cache invalidation takes 2-5 minutes

# 2. Hard refresh browser
# Windows: Ctrl+Shift+R
# Mac: Cmd+Shift+R
# Firefox: Ctrl+F5

# 3. Try incognito/private window
# This bypasses browser cache

# 4. Check different device/network
# Use phone or different computer

# 5. Manually invalidate (if still not working)
aws cloudfront create-invalidation \
  --distribution-id YOUR_DIST_ID \
  --paths "/*"

# 6. Monitor invalidation
aws cloudfront get-invalidation \
  --distribution-id YOUR_DIST_ID \
  --id YOUR_INVALIDATION_ID
```

**How to verify:**

```bash
# Check status is "Completed"
# Or visit site and see new content
```

---

### Issue: Infrastructure Workflow Fails at "Terraform Plan"

**Error message:**

```
Error: Error requesting AWS STS GetCallerIdentity
```

**Cause:** AWS credentials invalid or expired

**Solution:**

```bash
# 1. Verify credentials in GitHub secrets
# GitHub → Settings → Secrets → Actions
# Check: AWS_ACCESS_KEY_ID exists
# Check: AWS_SECRET_ACCESS_KEY exists

# 2. Verify credentials are correct
# Regenerate new ones if unsure:
# AWS Console → IAM → Your user → Security credentials

# 3. Update GitHub secrets with new credentials

# 4. Retry workflow
# Actions → Manage Infrastructure → Run workflow
# Action: apply
# Confirmation: apply
```

**How to verify:**

```bash
# Check that workflow succeeds
# Actions tab shows green checkmark ✅
```

---

### Issue: "Confirmation Does Not Match Action"

**Error message:**

```
❌ Error: Confirmation does not match action
Action: apply
Confirmation: deployment
```

**Cause:** Action and confirmation text don't match exactly

**Solution:**

```bash
# In GitHub Actions workflow form:
# Action dropdown: Select "apply" or "destroy"
# Confirmation text field: Type EXACTLY the same word

# Examples of correct entries:
# Action: apply    → Confirmation: apply     ✅
# Action: destroy  → Confirmation: destroy   ✅

# Examples of WRONG entries:
# Action: apply    → Confirmation: deployment ❌
# Action: destroy  → Confirmation: remove    ❌
```

**How to verify:**

```bash
# Workflow should show:
# ✅ Confirmation verified
```

---

## Runtime Issues

### Issue: Location Shows "Unknown" Instead of City

**Symptom:**

- Dashboard shows: "Your Location: Unknown, Unknown (Unknown)"
- API endpoint shows correct data locally

**Cause:** CloudFront headers not being forwarded to Lambda

**Solution:**

```bash
# 1. Check Lambda logs
aws logs tail /aws/lambda/aether-drone-api-handler --follow --since 5m

# Look for:
# DEBUG: All headers received by Lambda:
# If headers are missing or empty, issue is in CloudFront

# 2. Check CloudFront origin request policy
# AWS Console → CloudFront → Your distribution
# Select distribution → Behaviors tab
# Check /default/* behavior
# Verify: Origin Request Policy = "Managed-AllViewerExceptHostHeader"

# 3. Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id YOUR_DIST_ID \
  --paths "/*"

# 4. Wait 2 minutes and test again
curl "https://your-cloudfront-url/default/getVisitorLocation?action=location"

# 5. If still "Unknown", check headers directly
# Test API Gateway (bypass CloudFront):
curl "https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/default/getVisitorLocation?action=location"
# If this returns real location, CloudFront is issue
```

**How to verify:**

```bash
# Should return real location
curl "https://your-cloudfront-url/default/getVisitorLocation?action=location"

# Output should be:
# {
#   "city": "Montreal",
#   "region": "QC",
#   "country": "CA",
#   "edgeLocation": "YYZ50"
# }
```

---

### Issue: WAF Block Count Shows "0" or "Unknown"

**Symptom:** Threats Blocked always shows 0 or Unknown

**Cause:** WAF logs not being queried correctly or Lambda lacks permissions

**Solution:**

```bash
# 1. Verify WAF is logging
# AWS Console → WAF & Shield → Web ACLs
# Select your ACL → Logging configuration
# Check: Logging enabled ✅

# 2. Check Lambda has permissions
# AWS Console → Lambda → aether-drone-api-handler
# Execution role → Permissions
# Should have:
#   - logs:StartQuery
#   - logs:GetQueryResults

# 3. Check CloudWatch log group exists
aws logs describe-log-groups | grep waf
# Should show: aws-waf-logs-aether-drone-web-acl

# 4. Check Lambda environment variable
# AWS Console → Lambda → aether-drone-api-handler
# Environment variables
# Should have: WAF_LOG_GROUP_NAME = aws-waf-logs-aether-drone-web-acl

# 5. Test Lambda manually
aws lambda invoke \
  --function-name aether-drone-api-handler \
  --payload '{"queryStringParameters":{"action":"waf"}}' \
  response.json
cat response.json

# 6. Check logs for errors
aws logs tail /aws/lambda/aether-drone-api-handler --follow
```

**How to verify:**

```bash
# Should return block count
curl "https://your-cloudfront-url/default/getVisitorLocation?action=waf"

# Output should be:
# {
#   "blockCount": 42
# }
```

---

### Issue: API Returns "502 Bad Gateway"

**Error:** Browser shows "502 Bad Gateway"

**Cause:** Lambda timeout, Lambda error, or API Gateway misconfiguration

**Solution:**

```bash
# 1. Check Lambda logs for errors
aws logs tail /aws/lambda/aether-drone-api-handler --follow

# Look for ERROR or TIMEOUT messages

# 2. Check Lambda timeout is sufficient
# AWS Console → Lambda → aether-drone-api-handler
# General configuration → Timeout
# Should be at least 30 seconds

# 3. Check Lambda memory
# Increase memory if needed:
# Memory: 256 MB (was 128 MB)

# 4. Test Lambda directly
aws lambda invoke \
  --function-name aether-drone-api-handler \
  --payload '{"queryStringParameters":{"action":"location"}}' \
  response.json

# 5. Check API Gateway integration
# AWS Console → API Gateway → Your API
# Resources → /default → getVisitorLocation → GET
# Integration: Should be AWS_PROXY pointing to Lambda

# 6. If still failing, manually test
# Call API Gateway URL directly (bypass CloudFront)
curl "https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/default/getVisitorLocation?action=location"
```

**How to verify:**

```bash
# Should return 200 OK with JSON
curl -i "https://your-cloudfront-url/default/getVisitorLocation?action=location"
# Look for: HTTP/2 200
```

---

### Issue: Browser Shows "403 Forbidden" When Testing Security

**Symptom:** After clicking "Test Security" button, page shows 403

**Cause:** This is EXPECTED - it means WAF is working!

**Solution:**

```
This is NOT an error. This is the expected behavior:

1. You click "Test Security" button
2. Frontend attempts XSS attack: ?q=<script>alert("xss")</script>
3. WAF detects malicious query
4. WAF blocks request → Returns 403 Forbidden
5. Threat counter increments
6. Everything is working correctly! ✅
```

**How to verify:**

```
Check that:
✅ 403 Forbidden page appears
✅ Threat counter incremented
✅ No actual attack occurred (button worked as demo)
```

---

## AWS Issues

### Issue: S3 Bucket Already Exists

**Error message:**

```
Error creating S3 bucket: BucketAlreadyOwnedByYou
```

**Cause:** Bucket name conflict (S3 bucket names are globally unique)

**Solution:**

```bash
# 1. Check existing buckets
aws s3 ls

# 2. Option A: Use different project name
# Edit terraform/variables.tf
# Change: project_name = "different-name"

# 3. Option B: Destroy and recreate
cd terraform
terraform destroy
# Type: yes
terraform apply

# 4. Option C: List and check bucket
# AWS Console → S3
# Delete old/unused buckets if needed
```

**How to verify:**

```bash
# Terraform apply should complete successfully
# AWS Console → S3 shows your bucket
```

---

### Issue: CloudFront Distribution Deployment Fails

**Error message:**

```
Error: error creating CloudFront distribution: OriginRequestPolicyInUse
```

**Cause:** Old origin request policy still attached

**Solution:**

```bash
# 1. In Terraform state, remove old policy
cd terraform
terraform state rm aws_cloudfront_origin_request_policy.api_location_policy

# 2. Manually delete from AWS (if needed)
# AWS Console → CloudFront → Policies → Origin request policies
# Find old policy, click Delete

# 3. Retry Terraform
terraform apply
```

**How to verify:**

```bash
# Should apply successfully
# AWS Console → CloudFront → Your distribution exists
```

---

### Issue: Lambda Function Execution Timeout

**Error message:**

```
Task timed out after 30.00 seconds
```

**Cause:** WAF query takes too long or Lambda processing slow

**Solution:**

```bash
# 1. Increase timeout
# AWS Console → Lambda → aether-drone-api-handler
# General configuration → Timeout: 60 seconds (from 30)

# 2. Or via Terraform
# Edit terraform/main.tf
resource "aws_lambda_function" "api_handler" {
  timeout = 60  # Increased from 30
}
terraform apply

# 3. Check CloudWatch Logs for long-running queries
aws logs tail /aws/lambda/aether-drone-api-handler --follow

# 4. Optimize WAF query
# Reduce time window or improve query efficiency
```

**How to verify:**

```bash
# Test should complete within 60 seconds
curl "https://your-cloudfront-url/default/getVisitorLocation?action=waf"
# Should respond within seconds
```

---

### Issue: IAM Role Missing Permissions

**Error message:**

```
User: arn:aws:iam::... is not authorized to perform: s3:GetObject
```

**Cause:** IAM user lacks required permissions

**Solution:**

```bash
# 1. Check current IAM user
aws sts get-caller-identity

# 2. Add missing permissions
# AWS Console → IAM → Users → Your user
# Add policies:
#   - AmazonS3FullAccess
#   - CloudFrontFullAccess
#   - AWSLambda_FullAccess
#   - APIGatewayAdministrator
#   - WAFFullAccess

# 3. Verify permissions
aws s3 ls
# Should list buckets

# 4. Retry operation
```

**How to verify:**

```bash
aws sts get-caller-identity
# Should show your user ARN
```

---

## GitHub Actions Issues

### Issue: "Secrets and Variables" Tab Doesn't Show Secrets

**Symptom:** Can't find where to add GitHub secrets

**Cause:** Navigation changed in GitHub

**Solution:**

```
Navigate using exact path:
1. Your GitHub repository
2. Click "Settings" tab (top menu)
3. Left sidebar → "Secrets and variables"
4. Dropdown → "Actions"
5. Click "New repository secret"

Alternative:
GitHub.com → Your repository → Settings → Secrets and variables → Actions
```

**How to verify:**

```
Should see section with existing secrets
(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, GH_PAT)
```

---

### Issue: "Personal Access Token Expired"

**Error message:**

```
API Error: Response error: 401 Unauthorized
```

**Cause:** GitHub Personal Access Token expired

**Solution:**

```bash
# 1. Generate new token
# GitHub → Settings → Developer settings
# Personal access tokens → Tokens (classic)
# Click "Generate new token (classic)"

# 2. Select scopes:
# ✅ repo (all)
# ✅ workflow
# ✅ admin:repo_hook

# 3. Copy token immediately

# 4. Update GitHub secret
# Settings → Secrets and variables → Actions
# Update GH_PAT with new token

# 5. Delete old token
# GitHub → Settings → Developer settings
# Find old token → Delete
```

**How to verify:**

```bash
# Workflow should run without authentication errors
# Check Actions tab for green checkmark ✅
```

---

### Issue: Workflow Cancelled Because of Missing Permissions

**Error message:**

```
GitHub Token has insufficient permissions
```

**Cause:** GH_PAT token lacks required scopes

**Solution:**

```bash
# 1. Delete old token
# GitHub → Settings → Developer settings
# Personal access tokens → Tokens (classic)
# Find token → Delete

# 2. Generate new token with correct scopes
# Click "Generate new token (classic)"
# Select scopes:
#   ✅ repo (all)
#   ✅ workflow
#   ✅ admin:repo_hook
# Click "Generate token"
# Copy token

# 3. Update GitHub secret
# Settings → Secrets and variables → Actions
# Click "GH_PAT" → Update value
# Paste new token

# 4. Re-run workflow
# Actions → Select workflow → Run workflow
```

**How to verify:**

```
Workflow should complete successfully
Actions tab shows green checkmark ✅
```

---

## Performance Issues

### Issue: Build Takes Too Long (>5 minutes)

**Cause:** Large dependencies, unoptimized images, or slow runner

**Solution:**

```bash
# 1. Check build time locally
npm run build
# Note the duration

# 2. Check bundle size
npm run build
# Look at output: "Optimized packages"

# 3. Optimize images
# Convert images to WebP format
# Compress using: https://tinypng.com/

# 4. Remove unused dependencies
npm list
npm uninstall unused-package

# 5. Use GitHub Actions cache
# In .github/workflows/deploy-app.yml:
# - uses: actions/setup-node@v4
#   with:
#     cache: 'npm'  # Add this line

# 6. Rebuild locally to test
npm run build
```

**How to verify:**

```bash
npm run build
# Should complete in <2 minutes

# Check Actions
# Deployment should be fast
```

---

### Issue: Website Loads Slowly

**Cause:** Large assets, poor CloudFront cache, or slow origin

**Solution:**

```bash
# 1. Check CloudFront cache hit ratio
# AWS Console → CloudFront → Your distribution → Monitoring
# Cache hit rate should be >95%

# 2. Optimize images
# Use WebP format
# Compress with: https://tinypng.com/

# 3. Check Lambda performance
# AWS Console → Lambda → Monitoring → Duration
# Should be <500ms for location endpoint

# 4. Test from different regions
# Use: https://www.pagespeed.web.dev/
# Test from US, EU, Asia

# 5. Enable CloudFront compression
# AWS Console → CloudFront → Distribution
# Default cache behavior → Compression: On
```

**How to verify:**

```bash
# Test page speed
# https://pagespeed.web.dev/

# Check metrics:
# First Contentful Paint < 1s
# Largest Contentful Paint < 2.5s
```

---

### Issue: High CloudFront Costs

**Cause:** Excessive data transfer or cache misses

**Solution:**

```bash
# 1. Check cache hit ratio
# AWS Console → CloudFront → Distribution → Monitoring
# If <90%, increase cache TTL

# 2. Monitor data transfer
# AWS Console → CloudFront → Monitoring
# Look for "Bytes downloaded" spike

# 3. Add cache control headers
# In Next.js, set cache headers:
# res.setHeader('Cache-Control', 'public, max-age=31536000')

# 4. Check traffic sources
# Who's accessing your site?
# Legitimate users or bots?
# Add WAF rule to block bots if needed

# 5. Consider removing unused features
# Disable CloudFront logging if not needed
```

**How to verify:**

```bash
# Check AWS Billing
# AWS Console → Billing → Bills
# CloudFront charges should be < $15/month
```

---

## Security Issues

### Issue: WAF Blocking Legitimate Traffic

**Error:** Users get "403 Forbidden" on normal pages

**Cause:** WAF rule too strict

**Solution:**

```bash
# 1. Check which rule blocked request
# AWS Console → WAF & Shield → Web ACLs
# Your ACL → Sampled requests
# Look for blocked requests

# 2. Add exception to rule
# Go to WAF rule → Edit
# Add scope-down statement to exclude paths

# 3. Or temporarily disable rule for testing
# WAF → Web ACLs → Your ACL
# Rule → Change to "Count" (instead of Block)
# Monitor for 1 hour, then re-enable

# 4. More precise filtering
# Block only POST requests (not GET)
# Block only certain paths (/admin, /api)

# 5. Allow known IPs
# Add IP whitelist rule for your office

# 6. Rebuild after changes
terraform apply
```

**How to verify:**

```bash
# Users should access site without 403 errors
# Check WAF logs for false positives
aws logs filter-log-events \
  --log-group-name "aws-waf-logs-aether-drone-web-acl" \
  --filter-pattern "BLOCK"
```

---

### Issue: Credentials Exposed in Git History

**Symptom:** You accidentally committed a secret to Git

**Cause:** Committed credentials to repository

**Solution:**

```bash
# 1. IMMEDIATELY revoke credentials
# AWS Console → IAM → Your user → Security credentials
# Delete exposed Access Key

# 2. Generate new credentials
# Create new Access Key

# 3. Update GitHub secrets with new credentials
# Settings → Secrets → Update AWS_ACCESS_KEY_ID
# Settings → Secrets → Update AWS_SECRET_ACCESS_KEY

# 4. Remove from Git history
# Using git-filter-branch or BFG Repo-Cleaner
# BFG is easier: https://rtyley.github.io/bfg-repo-cleaner/

# 5. If already public:
# Assume credentials compromised
# Regenerate all credentials immediately
```

**How to verify:**

```bash
# Credentials should be revoked
# AWS Console shows old key deleted
# New deployment works with new credentials
```

---

### Issue: Lambda Code Visible in CloudWatch

**Concern:** Can see source code in logs

**Cause:** Debug logging enabled

**Solution:**

```bash
# 1. Disable debug logging in production
# In handler.py:
# Remove or comment out print() statements

# 2. Use log levels instead
# import logging
# logger = logging.getLogger()
# logger.setLevel(logging.WARNING)  # Not DEBUG

# 3. Don't log sensitive data
# Never log: passwords, API keys, tokens

# 4. Rebuild Lambda
terraform apply

# 5. Delete old logs (optional)
# AWS Console → CloudWatch → Log Groups
# Delete old logs
```

**How to verify:**

```bash
# Check Lambda logs
aws logs tail /aws/lambda/aether-drone-api-handler

# Should NOT see sensitive information
# Should only see essential info
```

---

## Debug Commands

Quick reference for debugging:

### AWS CLI Commands

```bash
# Verify AWS credentials
aws sts get-caller-identity

# List S3 buckets
aws s3 ls

# Check CloudFront distributions
aws cloudfront list-distributions

# Check Lambda functions
aws lambda list-functions --query 'Functions[*].[FunctionName,Runtime,Timeout]' --output table

# Check IAM user
aws iam get-user

# Monitor real-time logs
aws logs tail /aws/lambda/aether-drone-api-handler --follow

# View WAF metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --start-time 2025-01-01T00:00:00Z \
  --end-time 2025-01-02T00:00:00Z \
  --period 3600 \
  --statistics Sum

# Test Lambda manually
aws lambda invoke \
  --function-name aether-drone-api-handler \
  --payload '{"queryStringParameters":{"action":"location"}}' \
  response.json
```

### Terraform Commands

```bash
# Validate configuration
terraform validate

# Check what will change
terraform plan

# Check state
terraform state list
terraform state show aws_s3_bucket.site_bucket

# Refresh state from AWS
terraform refresh

# Force unlock (if stuck)
terraform force-unlock LOCK_ID

# Get output values
terraform output
```

### Local Development Commands

```bash
# Start development server
npm run dev

# Type checking
npm run type-check

# Build for production
npm run build

# Run tests (if configured)
npm run test

# Check for issues
npm run lint

# Format code
npm run format
```

### Git Commands

```bash
# View recent commits
git log --oneline -5

# Check what branch you're on
git branch

# Check uncommitted changes
git status

# View file changes
git diff app/page.tsx

# Revert last commit
git revert HEAD

# Push to GitHub
git push origin main
```

### Network Commands

```bash
# Test API endpoint
curl "https://your-cloudfront-url/default/getVisitorLocation?action=location"

# Test with headers
curl -H "X-Custom-Header: value" "https://your-cloudfront-url/"

# Check DNS resolution
dig yourdomain.com

# Test connection
curl -I https://your-cloudfront-url

# Measure response time
curl -w "@curl-format.txt" -o /dev/null -s https://your-cloudfront-url
```

---

## Getting Help

### When to Check Documentation

| Problem | Check |
|---------|-------|
| Deployment stuck | [docs/CI-CD.md](docs/CI-CD.md) |
| Build failing | This file → Build Issues |
| Site not working | This file → Runtime Issues |
| AWS resource error | This file → AWS Issues |
| Don't understand architecture | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) |
| Infrastructure questions | [terraform/README.md](../terraform/README.md) |

### External Resources

- **AWS Documentation:** <https://docs.aws.amazon.com/>
- **Terraform Docs:** <https://www.terraform.io/docs/>
- **Next.js Docs:** <https://nextjs.org/docs>
- **GitHub Actions:** <https://docs.github.com/en/actions>
- **CloudFront Troubleshooting:** <https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/troubleshooting-CloudFront.html>

### Debug Log Example

When reporting an issue, include:

```
**Error Message:**
[Exact error text here]

**What You Did:**
1. Step 1
2. Step 2

**Expected Behavior:**
[What should have happened]

**Actual Behavior:**
[What actually happened]

**Logs:**
[Relevant log output]

**System Info:**
- OS: Windows/Mac/Linux
- Terraform version: x.x.x
- AWS region: us-east-1
```

---

## Common Success Indicators

### ✅ Infrastructure Working

- Terraform apply completes successfully
- GitHub shows green checkmark on Manage Infrastructure
- Repository variables are set (S3_BUCKET_NAME, CLOUDFRONT_DISTRIBUTION_ID, etc.)

### ✅ Application Working

- npm run build completes successfully
- Website loads at CloudFront URL
- No console errors in DevTools (F12)
- Dashboard shows real location data

### ✅ API Working

- `/default/getVisitorLocation?action=location` returns city/region/country
- `/default/getVisitorLocation?action=waf` returns block count
- Response time < 1 second

### ✅ Security Working

- WAF blocks XSS attempts (403 Forbidden)
- Test Security button increments threat counter
- CloudFront cache hit ratio > 95%

### ✅ Performance Working

- First page load < 1 second
- Repeat visits < 200ms
- PageSpeed score > 90

---

## Still Stuck?

1. ✅ Check this troubleshooting guide (Ctrl+F search)
2. ✅ Review [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) step-by-step
3. ✅ Check [docs/CI-CD.md](docs/CI-CD.md) for workflow help
4. ✅ Review [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) to understand components
5. ✅ Check [terraform/README.md](../terraform/README.md) for infrastructure questions

### Get Debug Logs

Collect detailed logs before asking for help:

```bash
# 1. Infrastructure logs
cd terraform
terraform plan > terraform_plan.txt 2>&1

# 2. Lambda logs (last 10 minutes)
aws logs tail /aws/lambda/aether-drone-api-handler --since 10m > lambda_logs.txt

# 3. GitHub Actions logs
# Go to Actions tab → failed workflow → click on step
# Copy full log text

# 4. API Gateway logs
aws logs tail /aws/api-gateway/aether-drone-api-prod-stage --since 10m > api_logs.txt

# 5. WAF logs
aws logs filter-log-events \
  --log-group-name "aws-waf-logs-aether-drone-web-acl" \
  --since 600000 > waf_logs.txt

# Include these when asking for help!
```

### Where to Ask for Help

- **GitHub Issues:** Report bugs on the project repository
- **Stack Overflow:** Tag with `aws`, `terraform`, `next-js`
- **AWS Support:** For AWS-specific issues
- **Terraform Community:** HashiCorp community forums

---

## Quick Reference Cheat Sheet

### Most Common Issues & Quick Fixes

| Issue | Quick Fix |
|-------|-----------|
| Unknown location | `aws cloudfront create-invalidation --distribution-id YOUR_ID --paths "/*"` |
| Build fails | `npm install --legacy-peer-deps && npm run build` |
| 403 Forbidden | This is expected! WAF working correctly |
| Deployment doesn't trigger | Check GitHub secrets are set |
| Secrets missing | GitHub → Settings → Secrets and variables → Actions |
| S3 access denied | Check AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY secrets |
| Lambda timeout | Increase timeout from 30 to 60 seconds in Lambda console |
| Workflow stuck | Cancel workflow, re-run, or check GitHub status |
| High costs | Check CloudFront cache hit ratio (should be >95%) |

---

## Preventive Maintenance

To avoid issues in the future:

### Weekly Checks

```bash
# Monitor CloudWatch logs
aws logs tail /aws/lambda/aether-drone-api-handler --since 1w

# Check CloudFront metrics
# AWS Console → CloudFront → Distributions → Monitoring

# Review GitHub Actions history
# GitHub → Actions tab → Check for failures
```

### Monthly Checks

```bash
# Review AWS costs
# AWS Console → Billing → Bills

# Check Terraform drift
cd terraform
terraform plan

# Validate no security issues
# AWS Console → Security Hub (if enabled)
```

### Quarterly Checks

```bash
# Update dependencies
npm outdated
npm update

# Review and update IAM permissions
# AWS Console → IAM → Access Analyzer

# Check Terraform version
terraform version
# Upgrade if needed: terraform init -upgrade
```

---

## Disaster Recovery Procedures

### If Website is Down

1. **Immediate:** Check CloudFront status

   ```bash
   aws cloudfront get-distribution-config --id YOUR_DIST_ID
   ```

2. **Check Lambda is running**

   ```bash
   aws lambda get-function --function-name aether-drone-api-handler
   ```

3. **Check S3 bucket is accessible**

   ```bash
   aws s3 ls s3://your-bucket/
   ```

4. **If S3 files missing, redeploy**

   ```bash
   # Push code to trigger deployment
   git add -A
   git commit -m "redeploy"
   git push origin main
   ```

### If Infrastructure is Corrupted

1. **Destroy corrupted infrastructure**

   ```bash
   cd terraform
   terraform destroy
   ```

2. **Verify deletion**

   ```bash
   aws cloudfront list-distributions
   aws s3 ls
   ```

3. **Recreate infrastructure**

   ```bash
   terraform apply
   ```

4. **Redeploy application**

   ```bash
   git push origin main
   ```

### If AWS Credentials Compromised

1. **Immediately revoke old credentials**

   ```bash
   # AWS Console → IAM → Your user → Security credentials
   # Delete Access Key
   ```

2. **Generate new credentials**
   - Create new Access Key in IAM

3. **Update all references**

   ```bash
   aws configure  # Update locally
   
   # Update GitHub secrets:
   # Settings → Secrets → AWS_ACCESS_KEY_ID
   # Settings → Secrets → AWS_SECRET_ACCESS_KEY
   ```

4. **Test new credentials**

   ```bash
   aws sts get-caller-identity
   ```

5. **Re-run workflows**
   - GitHub → Actions → Manage Infrastructure → Run workflow

### If Git Repository Corrupted

```bash
# Clone fresh copy
cd ..
rm -rf aether-drone
git clone https://github.com/yourusername/aether-drone.git
cd aether-drone

# Verify remotes
git remote -v

# Pull latest
git pull origin main
```

---

## Performance Optimization Checklist

After deployment, optimize performance:

### ✅ Frontend Optimization

- [ ] Compress images to WebP format
- [ ] Lazy load images below fold
- [ ] Split code into smaller bundles
- [ ] Enable compression in CloudFront
- [ ] Set appropriate cache headers
- [ ] Remove unused CSS/JavaScript

### ✅ Backend Optimization

- [ ] Increase Lambda memory if cold starts slow
- [ ] Cache Lambda responses when appropriate
- [ ] Optimize WAF queries
- [ ] Monitor Lambda duration metrics
- [ ] Set appropriate Lambda timeout

### ✅ CDN Optimization

- [ ] Verify CloudFront cache hit ratio > 95%
- [ ] Set appropriate TTL values
- [ ] Enable gzip compression
- [ ] Use CloudFront functions for optimization
- [ ] Review origin performance

### ✅ Security Optimization

- [ ] WAF rules adjusted to reduce false positives
- [ ] Rate limiting tuned for your traffic
- [ ] No debug logging in production
- [ ] Credentials rotated regularly
- [ ] IAM permissions follow least privilege

---

## Monitoring Dashboard

Create a simple monitoring routine:

```bash
#!/bin/bash
# save as: monitor.sh

echo "=== AWS Infrastructure Status ==="
echo "CloudFront Distributions:"
aws cloudfront list-distributions --query 'DistributionList.Items[].DomainName'

echo -e "\n=== Lambda Functions ==="
aws lambda list-functions --query 'Functions[].FunctionName'

echo -e "\n=== Recent Errors ==="
aws logs tail /aws/lambda/aether-drone-api-handler --since 1h --filter-pattern "ERROR"

echo -e "\n=== CloudFront Cache Hit Ratio ==="
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name CacheHitRate \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average

echo -e "\n=== AWS Billing This Month ==="
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d 'first day of month' +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

echo "=== Monitoring Complete ==="
```

Run weekly:

```bash
chmod +x monitor.sh
./monitor.sh
```

---

## FAQ - Frequently Asked Questions

### Q: How do I know if my infrastructure is working?

**A:** Run this checklist:

1. Website loads at CloudFront URL ✅
2. Dashboard shows real location data ✅
3. Threat counter shows number > 0 ✅
4. API responds to curl requests ✅
5. CloudFront cache hit ratio > 95% ✅

If all ✅, infrastructure is working!

---

### Q: What should I do if I see "Unknown" for location?

**A:** Follow this in order:

1. Wait 2 minutes (cache invalidation takes time)
2. Hard refresh browser (Ctrl+Shift+R)
3. Try incognito window
4. Check Lambda logs for errors
5. Invalidate CloudFront cache manually
6. See [Location Shows "Unknown"](#issue-location-shows-unknown-instead-of-city)

---

### Q: How do I make my site faster?

**A:** Check this in order:

1. CloudFront cache hit ratio - should be > 95%
2. Lambda duration - should be < 500ms
3. Image sizes - compress to WebP
4. Bundle size - check npm list for large packages
5. See [Performance Issues](#performance-issues)

---

### Q: Why are my AWS bills so high?

**A:** Usually caused by:

1. CloudFront excessive data transfer - check cache hit ratio
2. Lambda over-provisioned memory - reduce to 128MB
3. CloudWatch logs retention - reduce to 3 days
4. WAF requests being counted - normal, check CloudFront metrics

See [High CloudFront Costs](#issue-high-cloudfront-costs)

---

### Q: How do I update my website?

**A:** Simple:

```bash
# Edit your site
nano app/page.tsx

# Commit and push
git add -A
git commit -m "Update content"
git push origin main

# Done! Auto-deployed in 1-2 minutes
```

---

### Q: What if I need to change AWS region?

**A:** Change in Terraform:

```hcl
# terraform/variables.tf
variable "aws_region" {
  default = "eu-west-1"  # Changed from us-east-1
}

# Apply
terraform apply
```

---

### Q: How do I reduce costs?

**A:** Three options:

1. **Scale down:** Set WAF rate limit lower, reduce Lambda memory
2. **Pause infrastructure:** Run `terraform destroy` when not using
3. **Optimize:** Increase CloudFront cache TTL, optimize images

Estimated savings: $5-15/month on production

---

### Q: Can I use a custom domain?

**A:** Yes! See [terraform/README.md](../terraform/README.md) - "Using Custom Domain" section

Steps:

1. Register domain (Route 53 or external)
2. Request ACM certificate
3. Update CloudFront distribution
4. Update Route 53 DNS records

---

### Q: How do I add a new feature?

**A:** Standard workflow:

1. Create feature branch: `git checkout -b feature/my-feature`
2. Make changes: edit `app/page.tsx`
3. Test locally: `npm run dev`
4. Commit: `git commit -m "feature: add new section"`
5. Push to main: `git push origin main`
6. Auto-deploys!

---

### Q: What if deployment fails?

**A:** Check in this order:

1. GitHub Actions logs (red X on workflow)
2. AWS credentials valid? (`aws sts get-caller-identity`)
3. Repository variables set? (Settings → Variables)
4. Terraform syntax correct? (`terraform validate`)
5. See [Deployment Issues](#deployment-issues)

---

### Q: How long does deployment take?

**A:**

- Infrastructure deployment: 3-5 minutes
- Application deployment: 1-2 minutes
- Cache invalidation: 2-5 minutes
- **Total for full update: 5-10 minutes**

---

## Summary

**This troubleshooting guide covers:**

- ✅ Build issues
- ✅ Deployment issues
- ✅ Runtime issues
- ✅ AWS issues
- ✅ GitHub Actions issues
- ✅ Performance issues
- ✅ Security issues
- ✅ Debug commands
- ✅ Preventive Maintenance
- ✅ Disaster Recovery
- ✅ Performance Optimization
- ✅ Monitoring
- ✅ Common questions

**For issues not covered here:**

1. Check other docs (CI-CD, Architecture, etc.)
2. Review AWS CloudTrail and CloudWatch logs
3. Use debug commands to collect information
4. Report with full context

**Remember:** Most issues have simple solutions - start with logs! 📊
