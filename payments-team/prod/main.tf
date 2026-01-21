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

# This S3 bucket is MISSING encryption - will FAIL policy
resource "aws_s3_bucket" "customer_data" {
  bucket = "payments-customer-data-prod-demo"
  
  tags = {
    Environment = "production"
    Team        = "payments"
    CostCenter  = "engineering"
  }
}

# This one HAS encryption - will PASS policy
resource "aws_s3_bucket" "secure_logs" {
  bucket = "payments-secure-logs-prod-demo"
  
  tags = {
    Environment = "production"
    Team        = "payments"
    CostCenter  = "engineering"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs_encryption" {
  bucket = aws_s3_bucket.secure_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Small EC2 instance for cost demo
resource "aws_instance" "api_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"
  
  tags = {
    Name        = "payments-api-prod"
    Environment = "production"
    Team        = "payments"
    CostCenter  = "engineering"
  }
}