terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# Missing encryption AND missing required tags - DOUBLE VIOLATION
resource "aws_s3_bucket" "analytics_data" {
  bucket = "analytics-raw-data-prod-demo"
  
  # Intentionally missing tags to fail policy
}

# Expensive instance to trigger cost threshold
resource "aws_instance" "data_warehouse" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "r5.2xlarge"  # ~$500/month - triggers cost alert
  
  tags = {
    Name        = "data-warehouse-prod"
    Environment = "production"
    Team        = "data-platform"
    CostCenter  = "engineering"
  }
}

# RDS instance for more cost impact
resource "aws_db_instance" "analytics_db" {
  identifier           = "analytics-prod-db"
  engine              = "postgres"
  engine_version      = "15.3"
  instance_class      = "db.r5.xlarge"  # ~$400/month
  allocated_storage   = 100
  storage_encrypted   = false  # Policy violation
  skip_final_snapshot = true
  
  # Missing required tags - another violation
}