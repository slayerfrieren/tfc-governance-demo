# =============================================================
# ACME Corp - Data Platform Team
# Workspace: data-platform
#
# Scenario: Brand new team of data scientists building ACME's
# customer analytics pipeline. Brilliant engineers, but new
# to cloud infrastructure governance. Copied a quick example
# from online documentation without understanding ACME's
# required standards.
#
# Without TFC policies: $900/month surprise bill, customer
# behavioral data unencrypted, no cost visibility.
# With TFC policies: every violation caught at plan time
# before a single dollar is spent.
#
# Policy Status: MULTIPLE FAILURES
#   - S3 missing encryption          (hard fail)
#   - S3 missing required tags       (hard fail)
#   - EC2 exceeds cost threshold     (soft fail - requires approval)
#   - RDS storage not encrypted      (hard fail)
#   - RDS missing required tags      (hard fail)
#   - RDS exceeds cost threshold     (soft fail - requires approval)
#
# Est. Monthly Cost: ~$900/month (way over threshold)
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
      name = "data-platform"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Raw customer behavior data lake
# Stores clickstream data, browsing history, purchase signals
#
# VIOLATION 1: No server-side encryption
# VIOLATION 2: No required tags
# Realistic scenario: data scientist copied a minimal S3
# example to get started quickly - didn't know tags and
# encryption were required by ACME policy
resource "aws_s3_bucket" "customer_behavior_data" {
  bucket = "acme-customer-behavior-raw-prod"

  # No tags - triggers tagging policy failure
  # No encryption block below - triggers encryption policy failure
}

# Data processing instance
# Memory-optimized for ML feature engineering workloads
#
# VIOLATION 3: r5.2xlarge = ~$500/month
# Exceeds $200/month cost threshold - requires approval
# Realistic scenario: data team requested large instance
# for a POC without going through normal approval process
resource "aws_instance" "data_processor" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "r5.2xlarge" # ~$500/month - triggers cost policy

  tags = {
    Name        = "acme-data-processor-prod"
    Environment = "production"
    Team        = "data-platform"
    CostCenter  = "analytics"
    Owner       = "data-engineering"
    ManagedBy   = "terraform"
  }
}

# Analytics database
# PostgreSQL for aggregated customer metrics and reporting
#
# VIOLATION 4: storage_encrypted = false
# VIOLATION 5: No required tags
# VIOLATION 6: db.r5.xlarge = ~$400/month (over threshold)
# Realistic scenario: provisioned quickly before a board
# presentation - security and cost requirements overlooked
resource "aws_db_instance" "analytics_db" {
  identifier        = "acme-analytics-prod"
  engine            = "postgres"
  engine_version    = "15.3"
  instance_class    = "db.r5.xlarge" # ~$400/month - triggers cost policy
  allocated_storage = 100

  # Explicit encryption violation
  storage_encrypted = false

  username            = "analytics_admin"
  password            = "ChangeMe123!"
  skip_final_snapshot = true

  # No tags - triggers tagging policy failure
  # Combined with EC2 above: ~$900/month total
}
