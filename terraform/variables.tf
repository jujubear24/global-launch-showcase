# Defines input variables for the Terraform configuration.

variable "aws_region" {
    description = "The AWS region where primary resources will be created."
    type        = string
    default     = "us-east-2"
}

variable "project_name" {
    description = "The name of the project"
    type        = string
    default     = "global-launch-showcase"
}

variable "github_actions_principal_arn" {
  description = "The ARN of the IAM user or role for GitHub Actions that will deploy to S3."
  type        = string
}


