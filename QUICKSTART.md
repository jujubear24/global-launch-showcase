# Quick Start Guide

Get Aether Drone running in 5 minutes.

## Prerequisites

- AWS Account
- Terraform
- AWS CLI
- Git

## Step 1: Clone Repository

```bash
git clone git@github.com:jujubear24/global-launch-showcase.git
cd global-launch-showcase
```

## Step 2: Configure AWS

```bash
aws configure

# Enter: Access Key, Secret Key, Region (us-east-1), Output format (json)

```

## Step 3: Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Step 4: Set GitHub Secrets

1. Go to GitHub repository
2. Settings → Secrets and variables → Actions
3. Add: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, GH_PAT

## Step 5: Deploy Application

```bash
git push origin main
```

## Done! ✅

Visit your CloudFront URL to see your site live.


For detailed documentation, see:

- 📖 [Full Deployment Guide](docs/DEPLOYMENT.md)
- ⚙️ [CI/CD Workflows](docs/CI-CD.md)
- 🏗️ [Architecture](docs/ARCHITECTURE.md)
- ❓ [Troubleshooting](docs/TROUBLESHOOTING.md)
