# Aether Drone - Complete Infrastructure Breakdown

**Quick Links:** [High-Level Overview](#high-level-overview) | [Architecture Components](#architecture-components) | [Cost Analysis](#how-costs-are-minimized) | [Security](#security-layers) | [Serverless Benefits](#serverless-benefits-in-your-setup) | [Back to Main Docs](../README.md)

**Table of Contents**

- [High-Level Overview](#high-level-overview)
- [Architecture Components](#architecture-components)
  - [1. CloudFront CDN](#1-content-delivery-layer--cloudfront-cdn)
  - [2. S3 Static Hosting](#2-static-website-hosting--amazon-s3)
  - [3. Lambda Backend](#3-api-backend--aws-lambda)
  - [4. API Gateway](#4-api-management--api-gateway)
  - [5. Web Application Firewall](#5-security--web-application-firewall-waf)
  - [6. Logging & Monitoring](#6-logging--monitoring)
  - [7. Networking & Origins](#7-networking--origins)
- [Request Lifecycle](#8-request-lifecycle-with-geolocation)
- [Data Flow Diagram](#9-data-flow-diagram)
- [Cost Analysis](#how-costs-are-minimized)
- [Security Layers](#security-layers)
- [Serverless Benefits](#serverless-benefits-in-your-setup)

---

## High-Level Overview

Your infrastructure is a fully serverless, globally distributed web application with enterprise-grade security. It follows AWS best practices with auto-scaling, minimal operational overhead, and geolocation-aware request routing.

---

## Architecture Components

### 1. Content Delivery Layer – CloudFront (CDN)

**What it does:** Acts as the global content distribution network, serving your website from edge locations closest to users worldwide.

**Key features:**

- Caches static content (HTML, CSS, JS, images) at 200+ edge locations globally
- Provides DDoS protection via AWS Shield
- Integrates with WAF for security rule enforcement
- Adds geolocation headers to all requests (city, country, region)
- Compresses content automatically for faster delivery

**How requests flow:**

1. User requests `yourdomain.com`
2. CloudFront checks if content is cached
3. If cached → serves from nearest edge location (milliseconds)
4. If not cached → fetches from origin (S3 or API Gateway)

---

### 2. Static Website Hosting – Amazon S3

**What it does:** Stores and serves your Next.js frontend application (HTML, CSS, JS, images).

**Configuration:**

- Website hosting enabled with `index.html` as default
- Error document set to `index.html` (enables SPA routing - all 404s go to React router)
- Public access completely blocked (only CloudFront can access via OAI)
- Force destroy enabled for easy teardown

**Security:**

- Blocked all public ACLs and bucket policies at resource level
- Uses Origin Access Identity (OAI) - CloudFront has a special AWS user that only it can use
- GitHub Actions user has upload permissions for CI/CD deployments

---

### 3. API Backend – AWS Lambda

**What it does:** Processes requests from your frontend, handles two main functions:

#### Function A: `get_visitor_location`

- Extracts geolocation data from CloudFront headers
- Returns: city, region, country, edge location (POP)
- Used by frontend to display "Your Location" card
- **Runtime:** ~20ms
- **Cost:** ~$0.0000002 per request

#### Function B: `get_waf_block_count`

- Queries CloudWatch Logs using CloudWatch Logs Insights
- Searches WAF logs from the past hour
- Counts total blocked requests
- Returns integer block count
- **Runtime:** ~1-2 seconds (depends on log volume)

**Configuration:**

- Runtime: Python 3.12
- Memory: 128 MB (default, sufficient for both operations)
- Timeout: 30 seconds
- X-Ray tracing enabled for performance monitoring
- Environment variables pass WAF log group name

---

### 4. API Management – API Gateway

**What it does:** Creates RESTful HTTP endpoints and routes traffic to Lambda.

**Architecture:**

```
GET /default/getVisitorLocation?action=location  →  Lambda
GET /default/getVisitorLocation?action=waf       →  Lambda
OPTIONS /default/getVisitorLocation              →  Mock (CORS preflight)
```

**Features:**

- Public access policy allows anyone to invoke
- Generates CloudFront-compatible endpoints
- CORS preflight handling (OPTIONS method)
- Access logging to CloudWatch for audit trail
- API Keys not required (open to public)

**Request flow:**

1. Browser makes request to CloudFront
2. CloudFront routes to API Gateway origin
3. API Gateway validates request
4. Invokes Lambda with event payload
5. Lambda returns response
6. API Gateway transforms to HTTP response
7. CloudFront caches (if applicable)

---

### 5. Security – Web Application Firewall (WAF)

**What it does:** Inspects all incoming requests and blocks malicious traffic.

**Rules:**

- **Rule 1: AWS Managed Common Rule Set**
  - Blocks SQL injection, XSS, path traversal, etc.
  - Excludes `/default/` API path (prevents blocking your own API)
  - Vendors: AWS-maintained security rules
  
- **Rule 2: Rate Limiting**
  - Limit: 10,000 requests per 5 minutes per IP
  - Very permissive (only blocks extreme abuse)
  - Prevents DDoS and resource exhaustion

**Logging:**

- Sends all requests (blocked and allowed) to CloudWatch Logs
- Log group: `aws-waf-logs-YOUR_PROJECT-web-acl`
- Retention: 7 days
- Lambda queries these logs to display threat count

---

### 6. Logging & Monitoring

#### CloudWatch Logs Groups

**API Gateway Logs** (`/aws/api-gateway/...`)

- Every API request logged with detailed metadata
- Source IP, request time, status code, response length
- Used for debugging and audit trail

**WAF Logs** (`aws-waf-logs-...`)

- All blocked requests logged with details
- Attack patterns, rule violations
- Lambda queries these for threat count display

**Lambda Logs** (`/aws/lambda/YOUR_PROJECT-api-handler`)

- Function execution logs
- Debug output from geolocation parsing
- Errors and exceptions

**Retention:** 7 days for all (cost-optimized)

---

### 7. Networking & Origins

#### Origin 1: S3 Bucket

- Domain: `YOUR_BUCKET.s3.REGION.amazonaws.com`
- Access: Only via Origin Access Identity
- Cache behavior: Optimized caching (CachingOptimized policy)

#### Origin 2: API Gateway

- Domain: `YOUR_API_ID.execute-api.us-east-1.amazonaws.com`
- Path: `/prod` (stage name)
- Cache behavior: No caching (CachingDisabled policy)
- Origin Request Policy: AllViewerExceptHostHeader (forwards headers, cookies, query strings)

---

### 8. Request Lifecycle with Geolocation

Here's exactly what happens when you visit the site:

```
1. Browser → CloudFront Edge Location (nearest to you)
   ├─ CloudFront detects your IP address
   ├─ Looks up geolocation data
   ├─ Creates headers: Cloudfront-Viewer-City, Cloudfront-Viewer-Country, etc.
   └─ Forwards request to origin

2. CloudFront Function (viewer-request) 
   └─ Converts geolocation data into request headers (added to both S3 and API requests)

3a. If requesting static content:
    ├─ Route: /index.html, /styles.css, etc.
    ├─ Serves from S3 (cached at edge)
    └─ Returns to browser

3b. If requesting API data (from Next.js fetch):
    ├─ Route: /default/getVisitorLocation?action=location
    ├─ CloudFront checks API Gateway origin
    ├─ API Gateway validates CORS
    ├─ Invokes Lambda with headers
    ├─ Lambda extracts city/region/country/edge_location
    ├─ Returns JSON response
    ├─ No caching (cache policy = disabled)
    └─ Returns to browser immediately

4. Browser receives both static content + API data
   └─ React renders "Your Location: Montreal, QC (CA)"
```

---

### 9. Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        User Browser                      │
│            (Aether Drone Marketing Site)                 │
└─────────────────────────────────┬─────────────────────────────────────┘
                     │ HTTPS
                     ▼
        ┌──────────────────────────────────┐
        │   CloudFront CDN            │
        │ (200+ Edge Locations)      │
        │ - DDoS Protection (Shield) │
        │ - WAF Integration          │
        │ - Geolocation Detection    │
        └──────────────────┬──────────────────┘
                   │
        ┌──────────────────┴──────────────────┐
        │                     │
        ▼                     ▼
    ┌────────────┐          ┌──────────────────┐
    │    S3   │          │ API Gateway  │
    │ Bucket  │          │              │
    │         │          └──────────┬──────────┘
    │ Assets: │                 │
    │ - HTML  │          ┌────────────▼─────────┐
    │ - CSS   │          │  Lambda Func │
    │ - JS    │          │             │
    │ - IMG   │          │ - Location  │
    └────────┬┘          │ - WAF Count │
        │               └──────────┬─────────┘
        │                      │
        │               ┌────────────▼─────────────┐
        │               │ CloudWatch    │
        │               │ Logs          │
        │               │               │
        │               │ - WAF Logs    │
        │               │ - Lambda Logs │
        │               │ - API Logs    │
        │               └───────────────────────┘
        │
        └──────────────────┬───────────────────────────────┐
                   │ Both cached at Edge    │
                   ▼                        ▼
            Browser displays:       Browser JS calls API:
            - HTML/CSS/JS           - fetch(...?action=location)
            - Images                - fetch(...?action=waf)
            - Static content        - Receives JSON responses
```

---

## How Costs Are Minimized

1. **CloudFront caching** - Reduces S3 requests by 99%+
2. **Lambda pay-per-use** - Only charged for actual invocations
3. **No database** - All data either static or computed on-demand
4. **Auto-scaling** - Handles traffic spikes without manual intervention
5. **CloudWatch retention** - 7 days keeps storage cost low
6. **S3 lifecycle** - Could be added to archive old data

**Estimated monthly costs:**

- CloudFront: ~$5-15
- S3: ~$1
- Lambda: <$1
- API Gateway: <$1
- CloudWatch: <$1
- **Total: ~$10-20/month**

---

## Security Layers

1. **Network Level** - CloudFront DDoS protection
2. **Application Level** - WAF blocks attacks
3. **Access Control** - S3 blocked to public, OAI only
4. **Logging** - Full audit trail in CloudWatch
5. **HTTPS** - All traffic encrypted in transit
6. **API** - No authentication needed (public demo site)

---

## Serverless Benefits in Your Setup

✅ **No servers to manage** - AWS handles infrastructure
✅ **Auto-scaling** - Handles 1 user or 1 million simultaneously
✅ **Pay per use** - Only pay for what you consume
✅ **Global by default** - CloudFront serves from nearest location
✅ **High availability** - Built-in redundancy across regions
✅ **Low latency** - Geolocation-based routing
