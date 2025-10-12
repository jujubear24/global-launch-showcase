# Defines the output values from the Terraform configuration.

output "s3_bucket_name" {
    description = "The name of the S3 bucket hosting the website."
    value       = aws_s3_bucket.site_bucket.bucket
}

output "cloudfront_distribution_domain" {
    description = "The domain name of the CloudFront distribution."
    value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "website_url" {
    description = "The CloudFront URL for the website."
    value       = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
}