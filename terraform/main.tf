#==============================================================================
# AWS Infrastructure Configuration
# This Terraform configuration defines a complete serverless architecture with:
# - S3 bucket for static website hosting
# - Lambda function for API backend
# - API Gateway for RESTful endpoints
# - CloudFront CDN with WAF protection
#==============================================================================

#------------------------------------------------------------------------------
# S3 Bucket for Static Website Hosting
#------------------------------------------------------------------------------

# Generate a random suffix to ensure bucket name uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Create S3 bucket to store static website files
resource "aws_s3_bucket" "site_bucket" {
  bucket = "${var.project_name}-bucket-${random_id.bucket_suffix.hex}"
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
          "logs:GetQueryResults"
        ],
        Resource = aws_cloudwatch_log_group.waf_logs.arn
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
  http_method = aws_api_gateway_method.options_location_method.http_method  # FIXED: Was referencing wrong resource
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
      # ADDED: Include CORS resources in deployment triggers
      aws_api_gateway_method.options_location_method.id,
      aws_api_gateway_integration.options_integration.id,
      aws_api_gateway_method_response.options_response.id,
      aws_api_gateway_integration_response.options_integration_response.id,
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
}

#------------------------------------------------------------------------------
# CloudWatch Log Group for WAF Logs
#------------------------------------------------------------------------------

# Create CloudWatch Log Group for WAF logs in us-east-1
# Note: Log group name must start with 'aws-waf-logs-' and be in us-east-1
resource "aws_cloudwatch_log_group" "waf_logs" {
  provider = aws.us_east_1

  name              = "aws-waf-logs-${var.project_name}-web-acl"
  retention_in_days = 7
}

#------------------------------------------------------------------------------
# WAF Web ACL Configuration
#------------------------------------------------------------------------------

# Create WAF Web ACL with security rules (in us-east-1 for CloudFront)
resource "aws_wafv2_web_acl" "web_acl" {
  provider = aws.us_east_1

  name  = "${var.project_name}-web-acl"
  scope = "CLOUDFRONT"

  # Allow traffic by default (rules below will block specific threats)
  default_action {
    allow {}
  }

  # Rule 1: Allow all API traffic (bypass all WAF rules for /default/* path)
  rule {
    name     = "AllowAPITraffic"
    priority = 0

    action {
      allow {}
    }

    statement {
      byte_match_statement {
        search_string         = "/default/"
        positional_constraint = "CONTAINS"

        field_to_match {
          uri_path {}
        }

        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "allowAPITraffic"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: AWS Managed Common Rule Set (only for non-API traffic)
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
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "awsCommonRules"
      sampled_requests_enabled   = true
    }
  }

  # Rule 3: Rate limiting to prevent DDoS
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
  provider = aws.us_east_1

  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.web_acl.arn

  depends_on = [aws_wafv2_web_acl.web_acl]
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
      # IMPORTANT: Replace with your actual IAM user ARN from the error message
      identifiers = ["arn:aws:iam::288232812020:user/github-actions-deployer"]
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
    origin_path = "/prod"  # ADDED: This fixes the 403 error
    
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
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  # Ordered cache behavior for API endpoints (no caching)
  ordered_cache_behavior {
    path_pattern           = "/default/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "APIGW-${aws_api_gateway_rest_api.api.id}"
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "none"
      }
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