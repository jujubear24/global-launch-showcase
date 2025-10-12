# required_providers block to specify the AWS provider and its version

terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

#Provider for primary resources like S3, Lambda, and API Gateway
provider "aws" {
    region = var.aws_region
}

# Provider for global services (CloudFront, WAF, ACM)
provider "aws" {
    alias  = "us_east_1"
    region = "us-east-1"
}