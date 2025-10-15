terraform {
  backend "s3" {
    bucket         = "global-launch-showcase-tfstate" # Choose a unique bucket name
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "global-launch-showcase-tf-lock-table"
    encrypt        = true
  }
}