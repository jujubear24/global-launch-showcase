#------------------------------------------------------------------------------
# Outputs
# These outputs are used by the CI/CD pipeline and for easy access to URLs.
#------------------------------------------------------------------------------

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.s3_distribution.id
  description = "CloudFront Distribution ID"
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
  description = "CloudFront Distribution Domain Name"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.site_bucket.id
  description = "S3 Bucket Name"
}

output "api_gateway_url" {
  value       = "${aws_api_gateway_rest_api.api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.api_stage.stage_name}"
  description = "API Gateway URL"
}