# Main Terraform configuration for Real-Time Manufacturing Analytics Platform

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Manufacturing-Analytics"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Kinesis Data Stream for sensor data ingestion
module "kinesis" {
  source = "./modules/kinesis"
  
  stream_name           = "${var.project_name}-sensor-data-${var.environment}"
  shard_count          = var.kinesis_shard_count
  retention_period     = var.kinesis_retention_hours
  encryption_type      = "KMS"
  environment          = var.environment
}

# IAM roles and policies
module "iam" {
  source = "./modules/iam"
  
  project_name         = var.project_name
  environment          = var.environment
  kinesis_stream_arn   = module.kinesis.stream_arn
  timestream_db_arn    = module.timestream.database_arn
  timestream_table_arn = module.timestream.table_arn
}

# Amazon Timestream for storing processed data
module "timestream" {
  source = "./modules/timestream"
  
  database_name        = "${var.project_name}-db-${var.environment}"
  table_name           = "${var.project_name}-metrics-${var.environment}"
  memory_retention_hours = var.timestream_memory_retention_hours
  magnetic_retention_days = var.timestream_magnetic_retention_days
  environment          = var.environment
}

# Amazon Managed Service for Apache Flink
module "flink" {
  source = "./modules/flink"
  
  application_name     = "${var.project_name}-processor-${var.environment}"
  runtime_environment  = "FLINK-1_18"
  service_execution_role = module.iam.flink_role_arn
  kinesis_stream_arn   = module.kinesis.stream_arn
  s3_bucket_arn        = aws_s3_bucket.flink_artifacts.arn
  environment          = var.environment
}

# S3 bucket for Flink application artifacts
resource "aws_s3_bucket" "flink_artifacts" {
  bucket = "${var.project_name}-flink-artifacts-${var.environment}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "flink_artifacts" {
  bucket = aws_s3_bucket.flink_artifacts.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flink_artifacts" {
  bucket = aws_s3_bucket.flink_artifacts.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "flink_artifacts" {
  bucket = aws_s3_bucket.flink_artifacts.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudWatch monitoring
module "monitoring" {
  source = "./modules/monitoring"
  
  project_name         = var.project_name
  environment          = var.environment
  kinesis_stream_name  = module.kinesis.stream_name
  flink_app_name       = module.flink.application_name
  alarm_email          = var.alarm_email
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
