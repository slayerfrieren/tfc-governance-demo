terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# This workspace is FULLY COMPLIANT - passes all policies
resource "aws_s3_bucket" "app_assets" {
  bucket = "mobile-app-assets-prod-demo"
  
  tags = {
    Environment = "production"
    Team        = "mobile-app"
    CostCenter  = "engineering"
  }
}

# Has encryption - PASSES policy
resource "aws_s3_bucket_server_side_encryption_configuration" "assets_encryption" {
  bucket = aws_s3_bucket.app_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Small instance - under cost threshold
resource "aws_instance" "app_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.small"  # ~$15/month - well under threshold
  
  tags = {
    Name        = "mobile-api-prod"
    Environment = "production"
    Team        = "mobile-app"
    CostCenter  = "engineering"
  }
}