# Outputs for Real-Time Manufacturing Analytics Platform

output "kinesis_stream_name" {
  description = "Name of the Kinesis Data Stream"
  value       = module.kinesis.stream_name
}

output "kinesis_stream_arn" {
  description = "ARN of the Kinesis Data Stream"
  value       = module.kinesis.stream_arn
}

output "timestream_database_name" {
  description = "Name of the Timestream database"
  value       = module.timestream.database_name
}

output "timestream_table_name" {
  description = "Name of the Timestream table"
  value       = module.timestream.table_name
}

output "flink_application_name" {
  description = "Name of the Flink application"
  value       = module.flink.application_name
}

output "flink_role_arn" {
  description = "ARN of the Flink execution role"
  value       = module.iam.flink_role_arn
}

output "producer_role_arn" {
  description = "ARN of the data producer role"
  value       = module.iam.producer_role_arn
}

output "s3_artifacts_bucket" {
  description = "Name of the S3 bucket for Flink artifacts"
  value       = aws_s3_bucket.flink_artifacts.id
}
