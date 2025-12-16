# Amazon Timestream module for time-series data storage

resource "aws_timestreamwrite_database" "manufacturing" {
  database_name = var.database_name
  
  kms_key_id = aws_kms_key.timestream.arn
  
  tags = {
    Name        = var.database_name
    Environment = var.environment
  }
}

resource "aws_timestreamwrite_table" "metrics" {
  database_name = aws_timestreamwrite_database.manufacturing.database_name
  table_name    = var.table_name
  
  retention_properties {
    magnetic_store_retention_period_in_days = var.magnetic_retention_days
    memory_store_retention_period_in_hours  = var.memory_retention_hours
  }
  
  magnetic_store_write_properties {
    enable_magnetic_store_writes = true
    
    magnetic_store_rejected_data_location {
      s3_configuration {
        bucket_name       = aws_s3_bucket.rejected_data.bucket
        encryption_option = "SSE_S3"
      }
    }
  }
  
  tags = {
    Name        = var.table_name
    Environment = var.environment
  }
}

# KMS key for Timestream encryption
resource "aws_kms_key" "timestream" {
  description             = "KMS key for Timestream database encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  tags = {
    Name        = "${var.database_name}-key"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "timestream" {
  name          = "alias/${var.database_name}"
  target_key_id = aws_kms_key.timestream.key_id
}

# S3 bucket for rejected data
resource "aws_s3_bucket" "rejected_data" {
  bucket = "${var.database_name}-rejected-data-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Name        = "${var.database_name}-rejected-data"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "rejected_data" {
  bucket = aws_s3_bucket.rejected_data.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "rejected_data" {
  bucket = aws_s3_bucket.rejected_data.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "rejected_data" {
  bucket = aws_s3_bucket.rejected_data.id
  
  rule {
    id     = "delete-old-rejected-data"
    status = "Enabled"
    
    expiration {
      days = 30
    }
  }
}

data "aws_caller_identity" "current" {}
