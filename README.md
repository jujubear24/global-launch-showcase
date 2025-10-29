# Aether Drone: The Self-Aware Product Launch Page

A modern, secure, and cost-effective cloud architecture for hosting a high-performance static website with a live technical dashboard. Built with Next.js, deployed on AWS, and managed entirely with Terraform.

**Live Demo:** The example site features a fictional "Aether Drone" product launch with a real-time dashboard showcasing the underlying cloud infrastructure.

### Quick Navigation

- 🚀 **Getting Started:** [QUICKSTART.md](QUICKSTART.md) - Deploy in 5 minutes
- 📖 **Full Guide:** [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) - Detailed walkthrough
- 🏗️ **Architecture:** [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - How it works
- ⚙️ **CI/CD:** [docs/CI-CD.md](docs/CI-CD.md) - Deployment automation
- 🔧 **Terraform:** [terraform/README.md](terraform/README.md) - Infrastructure code
- ❓ **Stuck?** [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Common fixes
- 🤝 **Contributing:** [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) - How to help

## 📚 Documentation

This project has comprehensive documentation organized as follows:

| Document | Purpose | Audience |
|----------|---------|----------|
| [QUICKSTART.md](QUICKSTART.md) | 5-minute setup guide | Everyone (start here!) |
| [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) | Step-by-step deployment | DevOps engineers |
| [docs/CI-CD.md](docs/CI-CD.md) | GitHub Actions workflows | DevOps engineers |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | System design & diagrams | Architects & developers |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common issues & fixes | Everyone |
| [terraform/README.md](terraform/README.md) | Terraform-specific docs | Infrastructure engineers |

---

## 🚀 Quick Start

Want to get running fast? See [QUICKSTART.md](QUICKSTART.md)

Want detailed setup? See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)

---

## The Business Problem & The Cloud Solution

This project solves three critical challenges for public-facing websites:

### 1. **Problem: High User Bounce Rates**

Users abandon sites that take longer than 1 second to load.

**Solution:** Global deployment on **AWS CloudFront's** edge network (200+ locations worldwide) ensures sub-100ms load times for visitors anywhere.

### 2. **Problem: Constant Security Threats**

Malicious bots and attackers target websites continuously.

**Solution:** An **AWS WAF (Web Application Firewall)** blocks SQL injection, XSS attacks, and rate-based abuse before traffic reaches your application. All blocked requests are logged for real-time monitoring.

### 3. **Problem: Budget Management**

Traditional servers require paying for idle capacity—inefficient and expensive.

**Solution:** A fully **serverless architecture** using S3 + CloudFront + Lambda means you only pay for what you use. Monthly costs typically $10-20 instead of $100+ for equivalent server infrastructure.

---

## Key Features

### ✨ Live Technical Insights Dashboard

The website includes a "Live Technical Insights" section that makes the invisible infrastructure visible to end-users:

- **🌍 Your Location**: Real-time geolocation detection (city, region, country) extracted from CloudFront headers
- **🚀 Serving Edge Location**: Shows the specific CloudFront edge server (POP code) delivering your content
- **🛡️ Threats Blocked**: Live counter of malicious requests blocked by WAF in the last hour
- **🔴 Interactive Security Test**: Users can trigger a mock XSS attack that gets blocked by WAF in real-time, with the threat counter incrementing instantly

### 🔒 Enterprise Security

- WAF with AWS Managed Common Rule Set (blocks OWASP Top 10)
- Rate limiting (10,000 requests per 5 minutes per IP)
- DDoS protection via CloudFront Shield
- S3 bucket completely blocked from public access (CloudFront-only via OAI)
- HTTPS everywhere with TLS 1.2+

### ⚡ Performance

- Sub-100ms latency via edge caching
- Automatic content compression
- Static asset optimization
- Zero cold starts for Lambda functions
- Intelligent cache invalidation

### 📊 Observability

- CloudWatch Logs for API Gateway, Lambda, and WAF
- Full audit trail of security events
- X-Ray tracing for performance analysis
- 7-day retention (configurable)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   User Browser                      │
│            (Visits yourdomain.com)                 │
└────────────────────┬────────────────────────────────┘
                     │ HTTPS
                     ▼
        ┌────────────────────────────┐
        │   CloudFront CDN           │
        │ (200+ Edge Locations)      │
        │ + WAF Protection           │
        │ + Geolocation Detection    │
        └──────────┬──────────────────┘
                   │
        ┌──────────┴──────────┐
        ▼                     ▼
    ┌─────────┐          ┌──────────────┐
    │    S3   │          │ API Gateway  │
    │ Bucket  │          │              │
    │         │          └──────┬───────┘
    │ (Static)│                 │
    │ Assets  │          ┌──────▼──────┐
    │         │          │  Lambda     │
    └─────────┘          │  Functions  │
                         │             │
                         │ • Location  │
                         │ • WAF Count │
                         └──────┬──────┘
                                │
                         ┌──────▼────────┐
                         │ CloudWatch    │
                         │ Logs          │
                         └───────────────┘
```

---

## Technology Stack

### Frontend

- **Next.js 14+** - React framework with built-in optimization
- **React 18+** - UI library with hooks
- **Tailwind CSS** - Utility-first CSS framework
- **TypeScript** - Static type safety
- **Lucide React** - Icon library

### Infrastructure as Code

- **Terraform** - Declarative infrastructure management
- **HCL** - HashiCorp Configuration Language

### AWS Services

| Service | Purpose |
|---------|---------|
| **S3** | Static website hosting (HTML, CSS, JS, images) |
| **CloudFront** | Global CDN, caching, WAF integration |
| **WAF v2** | Web application firewall with managed rules |
| **Lambda** | Serverless compute (Python 3.12) |
| **API Gateway** | RESTful API endpoint management |
| **CloudWatch** | Logging, monitoring, and metrics |
| **IAM** | Fine-grained access control |

### CI/CD

- **Git** - Version control
- **GitHub** - Repository hosting
- **GitHub Actions** - Automated build & deployment pipeline

---

## Setup & Deployment Guide

### Prerequisites

1. **AWS Account** - Create at [aws.amazon.com](https://aws.amazon.com)
2. **Terraform CLI** - [Install here](https://learn.hashicorp.com/tutorials/terraform/install-cli)
3. **AWS CLI** - [Install here](https://aws.amazon.com/cli/)
4. **Node.js 18+** - [Install here](https://nodejs.org/)
5. **Git** - [Install here](https://git-scm.com/)

### Step 1: Configure AWS Credentials

```bash
# Configure your AWS credentials locally
aws configure

# Enter your AWS Access Key ID, Secret Access Key, default region (e.g., us-east-1), and output format
```

### Step 2: Deploy Infrastructure with Terraform

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform (downloads provider plugins)
terraform init

# Review planned changes
terraform plan

# Apply the configuration (creates AWS resources)
terraform apply

# Type 'yes' when prompted to confirm
```

**Expected Output:**

```
Apply complete! Resources: 25 added, 0 changed, 0 destroyed.

Outputs:
cloudfront_domain_name = d123abc456.cloudfront.net
s3_bucket_name = aether-drone-bucket-a1b2c3d4
cloudfront_distribution_id = E1234ABCD5EFG
```

Save these values—you'll need them for the next step.

### Step 3: Configure GitHub Actions for CI/CD

1. Go to your GitHub repository: **Settings** → **Secrets and variables** → **Actions**

2. Create the following repository secrets:

| Secret | Value | Source |
|--------|-------|--------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | AWS IAM console |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | AWS IAM console |
| `AWS_S3_BUCKET` | `aether-drone-bucket-a1b2c3d4` | Terraform output: `s3_bucket_name` |
| `AWS_CLOUDFRONT_DISTRIBUTION_ID` | `E1234ABCD5EFG` | Terraform output: `cloudfront_distribution_id` |

3. Optional: Add AWS region secret if not `us-east-1`:

   ```
   AWS_REGION = us-west-2
   ```

### Step 4: Deploy the Frontend

```bash
# Build Next.js locally (optional, to test before pushing)
npm run build

# Push to main branch (triggers GitHub Actions)
git add -A
git commit -m "Deploy updated site"
git push origin main
```

GitHub Actions will automatically:

1. ✅ Build the Next.js application
2. ✅ Sync files to S3
3. ✅ Invalidate CloudFront cache
4. ✅ Deploy goes live (~2-5 minutes)

### Step 5: View Your Site

Visit your CloudFront domain:

```
https://d123abc456.cloudfront.net
```

Or configure a custom domain in **Amazon Certificate Manager (ACM)** and update CloudFront settings.

---

## Project Structure

```
aether-drone/
├── terraform/
│   ├── main.tf              # Primary AWS infrastructure
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   ├── providers.tf         # AWS provider configuration
│   └── README.md            # Terraform-specific documentation
│
├── app/                     # Next.js application
│   ├── page.tsx             # Home page component
│   ├── layout.tsx           # Root layout
│   └── globals.css          # Global styles
│
├── public/                  # Static assets
│   └── aether_drone.png     # Product image
│
├── .github/
│   └── workflows/
│       └── deploy.yml       # CI/CD pipeline configuration
│
├── package.json             # Node.js dependencies
├── tsconfig.json            # TypeScript configuration
├── tailwind.config.js       # Tailwind CSS configuration
├── next.config.js           # Next.js configuration
└── README.md                # This file
```

---

## Understanding the Live Dashboard

### How Geolocation Detection Works

1. **User visits site** → CloudFront detects IP address
2. **CloudFront adds headers** → `Cloudfront-Viewer-City`, `Cloudfront-Viewer-Country-Region`, etc.
3. **Frontend fetches API** → `GET /default/getVisitorLocation?action=location`
4. **Lambda receives headers** → Extracts city, region, country, edge location
5. **Returns JSON** → Frontend displays: "Montreal, QC (CA)"

### How Threat Counting Works

1. **WAF blocks request** → Logs to CloudWatch with reason
2. **Lambda queries logs** → `GET /default/getVisitorLocation?action=waf`
3. **CloudWatch Logs Insights** → Counts records where `action = 'BLOCK'` in last hour
4. **Returns count** → Frontend displays "47" threats blocked
5. **Test button** → Attempts XSS attack → WAF blocks it → Count increments

---

## Lambda Functions

### 1. `get_visitor_location`

**Endpoint:** `GET /default/getVisitorLocation?action=location`

**Runtime:** ~20ms

**Returns:**

```json
{
  "city": "Montreal",
  "region": "QC",
  "country": "CA",
  "edgeLocation": "YYZ50"
}
```

**How it works:**

- Extracts CloudFront geolocation headers (case-insensitive lookup)
- Parses `X-Amz-Cf-Id` header to get edge location POP code
- Returns location data for dashboard display

### 2. `get_waf_block_count`

**Endpoint:** `GET /default/getVisitorLocation?action=waf`

**Runtime:** ~1-2 seconds

**Returns:**

```json
{
  "blockCount": 42
}
```

**How it works:**

- Uses CloudWatch Logs Insights to query WAF logs
- Filters records where `action = 'BLOCK'`
- Counts records from past 60 minutes
- Returns total blocked request count

---

## API Endpoints

| Method | Path | Description | Response |
|--------|------|-------------|----------|
| `GET` | `/default/getVisitorLocation?action=location` | Get visitor geolocation | `{city, region, country, edgeLocation}` |
| `GET` | `/default/getVisitorLocation?action=waf` | Get WAF block count | `{blockCount}` |
| `OPTIONS` | `/default/getVisitorLocation` | CORS preflight | `200 OK` |

**Example Requests:**

```bash
# Get location data
curl "https://yourdomain.com/default/getVisitorLocation?action=location"

# Get WAF statistics
curl "https://yourdomain.com/default/getVisitorLocation?action=waf"
```

---

## Environment Variables

### Terraform Variables (`terraform/variables.tf`)

| Variable | Default | Description |
|----------|---------|-------------|
| `project_name` | `aether-drone` | Used in resource naming |
| `aws_region` | `us-east-1` | AWS region for deployment |
| `github_actions_principal_arn` | Required | ARN of GitHub Actions IAM role |

### Lambda Environment Variables

Automatically set by Terraform:

- `WAF_LOG_GROUP_NAME` - CloudWatch log group for WAF logs

### Next.js Environment Variables

None required for this demo. Customize `API_URL` in `page.tsx` if needed:

```typescript
const baseApiUrl = process.env.NEXT_PUBLIC_API_URL || '/default/getVisitorLocation';
```

---

## Monitoring & Debugging

### View API Gateway Logs

```bash
# Stream API Gateway logs
aws logs tail /aws/api-gateway/aether-drone-api-prod-stage --follow
```

### View Lambda Logs

```bash
# Stream Lambda execution logs
aws logs tail /aws/lambda/aether-drone-api-handler --follow --since 5m
```

### View WAF Logs

```bash
# Query WAF blocked requests in last hour
aws logs filter-log-events \
  --log-group-name "aws-waf-logs-aether-drone-web-acl" \
  --filter-pattern "BLOCK" \
  --since 3600000
```

### Check Lambda Performance

In AWS Console:

1. Go to **Lambda** → **Functions** → `aether-drone-api-handler`
2. Click **Monitor** tab
3. View duration, error rate, throttles, X-Ray traces

---

## Cost Estimation

| Service | Estimated Monthly Cost |
|---------|------------------------|
| CloudFront | $5-15 (depends on traffic) |
| S3 | <$1 |
| Lambda | <$1 (1M free requests/month) |
| API Gateway | <$1 (273 free requests/day) |
| CloudWatch | <$1 |
| **Total** | **~$10-20/month** |

**Scaling behavior:**

- 0 traffic: ~$5 (CloudFront minimum)
- 100K requests/month: ~$10
- 1M requests/month: ~$15
- 10M requests/month: ~$50

---

## Troubleshooting

### Site Shows "Unknown" for Location

**Cause:** Headers not being forwarded from CloudFront to API.

**Fix:**

1. Verify origin request policy is `Managed-AllViewerExceptHostHeader`
2. Check Lambda logs: `aws logs tail /aws/lambda/aether-drone-api-handler`
3. Invalidate CloudFront cache:

   ```bash
   aws cloudfront create-invalidation --distribution-id YOUR_DIST_ID --paths "/*"
   ```

### WAF Blocking Legitimate Traffic

**Cause:** AWS Managed Rules too strict for your use case.

**Fix:**

1. Go to **WAF** → **Web ACLs** → Your ACL
2. View **Sampled requests** to see what's being blocked
3. Add scope-down statement to exclude paths/patterns
4. Or adjust rule group to **Count** instead of **Block** to monitor

### Terraform Fails with "Resource Already Exists"

**Cause:** Resource was partially created from failed deployment.

**Fix:**

1. Check AWS Console for orphaned resources
2. Delete them manually if needed
3. Run `terraform destroy` to clean up state
4. Run `terraform apply` fresh

### GitHub Actions Deployment Fails

**Cause:** Missing or incorrect secrets.

**Fix:**

1. Verify all 4 secrets are set in GitHub
2. Test AWS credentials: `aws s3 ls`
3. Check Actions tab for detailed error logs
4. Ensure branch is `main` (workflow trigger)

---

## Security Best Practices

✅ **Implemented in this project:**

- S3 bucket blocked from public access
- WAF enabled with managed rules
- HTTPS/TLS enforcement
- CloudFront OAI for S3 access
- CloudWatch audit logging
- Least-privilege IAM roles
- DDoS protection (CloudFront Shield)

✅ **Additional recommendations:**

- Enable S3 versioning for rollback capability
- Use CloudFront functions for request/response manipulation
- Enable S3 encryption at rest
- Set up CloudTrail for API audit logging
- Implement GitHub branch protection rules
- Rotate AWS credentials regularly
- Use AWS Secrets Manager for sensitive data

---

## Performance Tips

1. **Optimize images** - Use WebP format, compress before upload
2. **Enable compression** - CloudFront automatically gzips text
3. **Leverage browser caching** - Set cache headers in Next.js
4. **Minimize bundle size** - Use tree-shaking, code splitting
5. **Monitor origin latency** - Lambda should respond <100ms

---

## Customization Guide

### Change Product Name

1. Update `terraform/variables.tf`:

   ```hcl
   variable "project_name" {
     default = "your-product-name"
   }
   ```

2. Update Next.js content:

   ```typescript
   // app/page.tsx
   <h1>Your Product Name</h1>
   ```

3. Redeploy:

   ```bash
   cd terraform && terraform apply
   git push origin main
   ```

### Use Custom Domain

1. Purchase domain (Route 53 or external registrar)
2. Request ACM certificate for domain
3. Update CloudFront distribution with certificate
4. Add Route 53 alias record pointing to CloudFront

### Add More API Endpoints

1. Create new Lambda function in `terraform/`
2. Add API Gateway resource and method
3. Update frontend to call new endpoint
4. Deploy: `terraform apply` + `git push`

---

## Cleanup & Cost Savings

To destroy all AWS resources and stop incurring charges:

```bash
# Navigate to terraform directory
cd terraform

# Destroy all infrastructure
terraform destroy

# Type 'yes' to confirm
```

**This will:**

- ✅ Delete CloudFront distribution
- ✅ Delete S3 bucket
- ✅ Delete Lambda functions
- ✅ Delete API Gateway
- ✅ Delete WAF rules
- ✅ Delete CloudWatch logs
- ✅ Delete IAM roles

---

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Commit: `git commit -m 'Add amazing feature'`
5. Push: `git push origin feature/amazing-feature`
6. Open a Pull Request

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## Resources & Learning

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Next.js Documentation](https://nextjs.org/docs)
- [CloudFront Best Practices](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/best-practices-content-based-routing.html)
- [AWS WAF Documentation](https://docs.aws.amazon.com/waf/)

---

## Support & Questions

- 📖 Check the [Troubleshooting](#troubleshooting) section above
- 🐛 Open an issue on GitHub for bugs
- 💬 Discussions tab for questions
- 📧 Contact: [your contact info]

---

## Author

**Jules Bahanyi**

- GitHub: [@jujubear24](https://github.com/jujubear24)
- LinkedIn: [@jules-bahanyi](https://www.linkedin.com/in/jules-bahanyi/)

---

## Acknowledgments

- AWS for comprehensive cloud services and documentation
- Terraform for excellent infrastructure-as-code tooling
- Next.js and React communities for excellent frameworks
- All contributors and users of this project