# Kinesis Data Stream module for sensor data ingestion

resource "aws_kinesis_stream" "sensor_data" {
  name             = var.stream_name
  shard_count      = var.shard_count
  retention_period = var.retention_period
  
  encryption_type = var.encryption_type
  kms_key_id      = var.encryption_type == "KMS" ? aws_kms_key.kinesis[0].id : null
  
  shard_level_metrics = [
    "IncomingBytes",
    "IncomingRecords",
    "OutgoingBytes",
    "OutgoingRecords",
    "WriteProvisionedThroughputExceeded",
    "ReadProvisionedThroughputExceeded",
    "IteratorAgeMilliseconds"
  ]
  
  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
  
  tags = {
    Name        = var.stream_name
    Environment = var.environment
  }
}

# KMS key for encryption
resource "aws_kms_key" "kinesis" {
  count = var.encryption_type == "KMS" ? 1 : 0
  
  description             = "KMS key for Kinesis stream encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  tags = {
    Name        = "${var.stream_name}-key"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "kinesis" {
  count = var.encryption_type == "KMS" ? 1 : 0
  
  name          = "alias/${var.stream_name}"
  target_key_id = aws_kms_key.kinesis[0].key_id
}
