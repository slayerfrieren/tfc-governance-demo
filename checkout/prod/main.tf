# =============================================================
# ACME Corp - Checkout Team
# Workspace: checkout
#
# Scenario: Fast-moving payments team shipping a new order
# management feature under deadline pressure. Developer
# copy-pasted an S3 config and missed the encryption block.
# A realistic, common mistake on any high-velocity team.
#
# Without TFC policies: this reaches production with customer
# order data unencrypted.
# With TFC policies: blocked at plan time, fixed in minutes.
#
# Policy Status: HARD FAIL - S3 encryption violation
# Est. Monthly Cost: ~$30/month (under threshold)
# =============================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  cloud {
    organization = "acme-corp"
    workspaces {
      name = "checkout"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Customer order data storage
# Contains PII: names, addresses, purchase history
#
# POLICY VIOLATION: Missing server-side encryption
# Realistic scenario: developer copy-pasted a basic S3
# config and forgot to add the encryption block while
# rushing to meet a sprint deadline
resource "aws_s3_bucket" "order_data" {
  bucket = "acme-customer-orders-prod"

  tags = {
    Name        = "acme-customer-orders-prod"
    Environment = "production"
    Team        = "checkout"
    CostCenter  = "ecommerce"
    Owner       = "checkout-engineering"
    ManagedBy   = "terraform"
  }
}

# Payment audit log storage
# Properly encrypted - passes policy
# Shows realistic partial compliance within a workspace
resource "aws_s3_bucket" "payment_audit_logs" {
  bucket = "acme-payment-audit-logs-prod"

  tags = {
    Name        = "acme-payment-audit-logs-prod"
    Environment = "production"
    Team        = "checkout"
    CostCenter  = "ecommerce"
    Owner       = "checkout-engineering"
    ManagedBy   = "terraform"
  }
}

# Encryption enabled on audit logs - passes S3 policy
resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs_encryption" {
  bucket = aws_s3_bucket.payment_audit_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Checkout API server
# t3.medium handles order processing load (~$30/month)
resource "aws_instance" "checkout_api" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"

  tags = {
    Name        = "acme-checkout-api-prod"
    Environment = "production"
    Team        = "checkout"
    CostCenter  = "ecommerce"
    Owner       = "checkout-engineering"
    ManagedBy   = "terraform"
  }
}