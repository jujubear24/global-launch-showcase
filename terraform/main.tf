#==============================================================================
# AWS Infrastructure Configuration
# This Terraform configuration defines a complete serverless architecture with:
# - S3 bucket for static website hosting
# - Lambda function for API backend
# - API Gateway for RESTful endpoints
# - CloudFront CDN with WAF protection
#==============================================================================

#------------------------------------------------------------------------------
# AWS Provider Data Sources
#------------------------------------------------------------------------------

# Data source to get the Account ID of the current AWS provider session
data "aws_caller_identity" "current" {}

# Data source to get the Region of the current AWS provider session
data "aws_region" "current" {}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

#==============================================================================
# Local Variables
#==============================================================================

locals {
  # Define the API Gateway access log format once to avoid repetition and cycles.
  api_gateway_access_log_format = jsonencode({
    requestId         = "$context.requestId"
    sourceIp          = "$context.identity.sourceIp"
    requestTime       = "$context.requestTime"
    protocol          = "$context.protocol"
    httpMethod        = "$context.httpMethod"
    resourcePath      = "$context.resourcePath"
    status            = "$context.status"
    responseLength    = "$context.responseLength"
    errorMessage      = "$context.error.message"
    extendedRequestId = "$context.extendedRequestId"
  })
  api_gateway_policy_json = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "execute-api:Invoke",
        Resource  = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*"
      }
    ]
  })
}

#------------------------------------------------------------------------------
# S3 Bucket for Static Website Hosting
#------------------------------------------------------------------------------

# Generate a random suffix to ensure bucket name uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Create S3 bucket to store static website files
resource "aws_s3_bucket" "site_bucket" {
  bucket        = "${var.project_name}-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name    = "${var.project_name}-bucket"
    Project = var.project_name
  }
}

# Configure S3 bucket for static website hosting
resource "aws_s3_bucket_website_configuration" "site_website_config" {
  bucket = aws_s3_bucket.site_bucket.id

  # Set default page for website
  index_document {
    suffix = "index.html"
  }

  # Configure error page (SPA routing support)
  error_document {
    key = "index.html"
  }
}

# Block all public access to S3 bucket (access via CloudFront only)
resource "aws_s3_bucket_public_access_block" "site_public_access_block" {
  bucket = aws_s3_bucket.site_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#------------------------------------------------------------------------------
# IAM Roles and Policies for Lambda Function
#------------------------------------------------------------------------------

# Create IAM role for Lambda execution
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}-lambda-exec-role"

  # Trust policy allowing Lambda service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Project = var.project_name
  }
}

# Create IAM policy for Lambda function permissions
resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.project_name}-lambda-policy"
  description = "Policy for Lambda function to access CloudWatch Logs and query WAF logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        # Allow Lambda to create and write to CloudWatch Logs
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        # Allow Lambda to query WAF logs
        Effect = "Allow",
        Action = [
          "logs:StartQuery",
          "logs:GetQueryResults",
          "logs:GetQueryResults",
          "logs:FilterLogEvents"
        ],
        Resource = "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.waf_logs.name}:*"
      }
    ]
  })
}

# Attach IAM policy to Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

#------------------------------------------------------------------------------
# Lambda Function Configuration
#------------------------------------------------------------------------------

# Package Lambda function code into a ZIP file
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

# Create Lambda function for API backend
resource "aws_lambda_function" "api_handler" {
  function_name    = "${var.project_name}-api-handler"
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_exec_role.arn
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30

  # Enable active X-Ray tracing
  tracing_config {
    mode = "Active"
  }

  # Environment variables for Lambda function
  environment {
    variables = {
      WAF_LOG_GROUP_NAME = aws_cloudwatch_log_group.waf_logs.name
    }
  }

  tags = {
    Project = var.project_name
  }
}

# Grant API Gateway permission to invoke Lambda function
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

#------------------------------------------------------------------------------
# API Gateway REST API Policy
#------------------------------------------------------------------------------

# This policy grants public access to invoke the API.
resource "aws_api_gateway_rest_api_policy" "api_policy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  policy      = local.api_gateway_policy_json
}

#------------------------------------------------------------------------------
# API Gateway REST API Configuration
#------------------------------------------------------------------------------

# Create REST API in API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.project_name}-api"
  description = "API for the serverless backend of ${var.project_name}"

  endpoint_configuration {
    types = ["EDGE"]
  }
}

# Create 'default' resource path
resource "aws_api_gateway_resource" "default_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "default"
}

# Create 'getVisitorLocation' resource under 'default'
resource "aws_api_gateway_resource" "location_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.default_resource.id
  path_part   = "getVisitorLocation"
}

#------------------------------------------------------------------------------
# GET Method Configuration
#------------------------------------------------------------------------------

# Define GET method for location endpoint
resource "aws_api_gateway_method" "get_location_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.location_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Integrate API Gateway with Lambda function
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.location_resource.id
  http_method             = aws_api_gateway_method.get_location_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

#------------------------------------------------------------------------------
# OPTIONS Method Configuration (CORS Preflight)
#------------------------------------------------------------------------------

# Add OPTIONS method for CORS preflight
resource "aws_api_gateway_method" "options_location_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.location_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# CORS integration (mock response)
resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.location_resource.id
  http_method = aws_api_gateway_method.options_location_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# OPTIONS method response
resource "aws_api_gateway_method_response" "options_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.location_resource.id
  http_method = aws_api_gateway_method.options_location_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# OPTIONS integration response
resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.location_resource.id
  http_method = aws_api_gateway_method.options_location_method.http_method
  status_code = aws_api_gateway_method_response.options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

#------------------------------------------------------------------------------
# API Gateway Deployment
#------------------------------------------------------------------------------

# Deploy API Gateway
# Uses triggers to automatically redeploy when API configuration changes
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  # Trigger redeployment when any of these resources change
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.default_resource.id,
      aws_api_gateway_resource.location_resource.id,
      aws_api_gateway_method.get_location_method.id,
      aws_api_gateway_integration.lambda_integration.id,
      aws_api_gateway_method.options_location_method.id,
      aws_api_gateway_integration.options_integration.id,
      aws_api_gateway_method_response.options_response.id,
      aws_api_gateway_integration_response.options_integration_response.id,
      aws_cloudwatch_log_group.api_gateway_logs.arn,
      local.api_gateway_access_log_format,
      local.api_gateway_policy_json,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create 'prod' stage for API Gateway
resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "prod"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format          = local.api_gateway_access_log_format
  }

  depends_on = [
    aws_api_gateway_account.current,
    aws_cloudwatch_log_group.api_gateway_logs
  ]
}

#------------------------------------------------------------------------------
# CloudWatch Log Group for API Gateway Execution Logs
#------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/${aws_api_gateway_rest_api.api.name}-prod-stage"
  retention_in_days = 7
}

#------------------------------------------------------------------------------
# IAM Role and Account Settings for API Gateway Logging
#------------------------------------------------------------------------------

# This role allows the API Gateway service to assume it.
resource "aws_iam_role" "api_gateway_logging_role" {
  name = "${var.project_name}-api-gateway-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })
}

# This attaches the AWS-managed policy that grants the specific permissions needed.
resource "aws_iam_role_policy_attachment" "api_gateway_logging_policy_attach" {
  role       = aws_iam_role.api_gateway_logging_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# This crucial resource associates the IAM role with your API Gateway account in this region.
resource "aws_api_gateway_account" "current" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_logging_role.arn
  depends_on          = [aws_iam_role.api_gateway_logging_role]
}

#------------------------------------------------------------------------------
# CloudWatch Log Group for WAF Logs
#------------------------------------------------------------------------------

# Create CloudWatch Log Group for WAF logs in us-east-1
# Note: Log group name must start with 'aws-waf-logs-' and be in us-east-1
resource "aws_cloudwatch_log_group" "waf_logs" {
  provider          = aws.us_east_1
  name              = "aws-waf-logs-${var.project_name}-web-acl"
  retention_in_days = 7
}

#------------------------------------------------------------------------------
# WAF Web ACL Configuration
#------------------------------------------------------------------------------

# Create WAF Web ACL with security rules (in us-east-1 for CloudFront)
resource "aws_wafv2_web_acl" "web_acl" {
  provider = aws.us_east_1
  name     = "${var.project_name}-web-acl"
  scope    = "CLOUDFRONT"

  # Allow traffic by default (rules below will block specific threats)
  default_action {
    allow {}
  }

  # Rule 1: AWS Managed Common Rule Set with scope-down to exclude API paths
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"

        scope_down_statement {
          not_statement {
            statement {
              byte_match_statement {
                search_string         = "/default/"
                positional_constraint = "STARTS_WITH"

                field_to_match {
                  uri_path {}
                }

                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "awsCommonRules"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: Rate limiting (very permissive)
  rule {
    name     = "RateLimitRule"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 10000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  # WAF visibility configuration
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf"
    sampled_requests_enabled   = true
  }
}

# Enable WAF logging to CloudWatch
resource "aws_wafv2_web_acl_logging_configuration" "web_acl_logging" {
  provider                = aws.us_east_1
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.web_acl.arn
  depends_on              = [aws_wafv2_web_acl.web_acl]
}

#------------------------------------------------------------------------------
# CloudFront Data Sources for Managed Policies
#------------------------------------------------------------------------------

# Look up the AWS-managed cache policy for "Caching Disabled"
data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

# Look up the AWS-managed origin request policy for "All Viewer Except Host Header"
data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

#------------------------------------------------------------------------------
# CloudFront Distribution and S3 Bucket Policy
#------------------------------------------------------------------------------

# Create Origin Access Identity for secure S3 access
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.project_name}"
}

# Define S3 bucket policy with TWO statements
data "aws_iam_policy_document" "s3_policy" {
  # Statement 1: Allow CloudFront to get objects
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }

  # Statement 2: Allow GitHub Actions user to sync files
  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.site_bucket.arn,
      "${aws_s3_bucket.site_bucket.arn}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = [var.github_actions_principal_arn]
    }
  }
}

# Attach policy to S3 bucket
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.site_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

# Create CloudFront distribution for global content delivery
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${var.project_name}"
  default_root_object = "index.html"
  web_acl_id          = aws_wafv2_web_acl.web_acl.arn

  # Origin 1: S3 bucket for static content
  origin {
    domain_name = aws_s3_bucket.site_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.site_bucket.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  # Origin 2: API Gateway for dynamic content
  origin {
    domain_name = "${aws_api_gateway_rest_api.api.id}.execute-api.${var.aws_region}.amazonaws.com"
    origin_id   = "APIGW-${aws_api_gateway_rest_api.api.id}"
    origin_path = "/prod"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default cache behavior for static content (S3)
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.site_bucket.id}"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.location_headers_function.arn
    }
  }

  # Ordered cache behavior for API endpoints (no caching)
  ordered_cache_behavior {
    path_pattern             = "/default/*"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD", "OPTIONS"]
    target_origin_id         = "APIGW-${aws_api_gateway_rest_api.api.id}"
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.location_headers_function.arn
    }
  }

  # No geographic restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL/TLS certificate configuration
  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  tags = {
    Project = var.project_name
  }
}

#------------------------------------------------------------------------------
# CloudFront Function to Add Location Headers
#------------------------------------------------------------------------------

resource "aws_cloudfront_function" "location_headers_function" {
  name    = "${var.project_name}-location-headers"
  runtime = "cloudfront-js-1.0"
  comment = "Adds viewer geo-location headers to the request"
  publish = true

  code = <<-EOT
    function handler(event) {
        var request = event.request;
        var viewer = event.viewer;

        // Add viewer location headers from the viewer object to the request headers
        // These are added as lowercase headers.
        if (viewer.country) {
            request.headers['cloudfront-viewer-country'] = { value: viewer.country };
        }
        if (viewer.city) {
            request.headers['cloudfront-viewer-city'] = { value: viewer.city };
        }
        if (viewer.region) {
            request.headers['cloudfront-viewer-country-region'] = { value: viewer.region };
        }
        if (viewer.postalCode) {
            request.headers['cloudfront-viewer-postal-code'] = { value: viewer.postalCode };
        }

        return request;
    }
  EOT
}
