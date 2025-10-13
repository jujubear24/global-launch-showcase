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



