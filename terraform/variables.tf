# Defines input variables for the Terraform configuration.

variable "aws_region" {
    description = "The AWS region where primary resources will be created."
    type        = string
    default     = "us-east-2"
}

variable "project_name" {
    description = "A unique name for the project, used to prefix resource names."
    type        = string
    default     = "global-launch-showcase"
}

variable "domain_name" {
    description = "The custom domain name for the website (e.g., https://www.google.com/search?q=yoursite.com). You must own this domain."
    type        = string
    default     = "example.com" # <-- IMPORTANT: Replace with your actual domain name
}

