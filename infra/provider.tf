terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.46"
    }
  }
  backend "s3" {
    bucket         = "laravel-app-terraform-state-bucket"
    key            = "laravel-app/terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "laravel-app-terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
}