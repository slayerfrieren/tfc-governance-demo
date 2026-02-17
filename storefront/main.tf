# =============================================================
# ACME Corp - Storefront Team
# Workspace: storefront
#
# Scenario: Mature e-commerce team managing customer-facing
# product catalog and web assets. Expected to follow all best practices and compliance for demo purposes.
#
# Policy Status: ALL PASSING
# Est. Monthly Cost: ~$25/month
# =============================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # TFC workspace connection
  # Isolates storefront state from other teams
  # Prevents accidental overwrites across teams
  cloud {
    organization = "acme-corp"
    workspaces {
      name = "storefront"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Product catalog storage
# Serves product images and descriptions to the storefront
resource "aws_s3_bucket" "product_catalog" {
  bucket = "acme-product-catalog-prod"

  tags = {
    Name        = "acme-product-catalog-prod"
    Environment = "production"
    Team        = "storefront"
    CostCenter  = "ecommerce"
    Owner       = "storefront-engineering"
    ManagedBy   = "terraform"
  }
}

# Encryption enabled - passes S3 policy
resource "aws_s3_bucket_server_side_encryption_configuration" "catalog_encryption" {
  bucket = aws_s3_bucket.product_catalog.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Static assets bucket (CSS, JS, images)
resource "aws_s3_bucket" "static_assets" {
  bucket = "acme-storefront-static-assets-prod"

  tags = {
    Name        = "acme-storefront-static-assets-prod"
    Environment = "production"
    Team        = "storefront"
    CostCenter  = "ecommerce"
    Owner       = "storefront-engineering"
    ManagedBy   = "terraform"
  }
}

# Encryption enabled - passes S3 policy
resource "aws_s3_bucket_server_side_encryption_configuration" "assets_encryption" {
  bucket = aws_s3_bucket.static_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Web server - small, cost-efficient, well under threshold
resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.small" # ~$15/month

  tags = {
    Name        = "acme-storefront-web-prod"
    Environment = "production"
    Team        = "storefront"
    CostCenter  = "ecommerce"
    Owner       = "storefront-engineering"
    ManagedBy   = "terraform"
  }
}