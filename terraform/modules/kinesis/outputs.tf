output "stream_name" {
  description = "Name of the Kinesis stream"
  value       = aws_kinesis_stream.sensor_data.name
}

output "stream_arn" {
  description = "ARN of the Kinesis stream"
  value       = aws_kinesis_stream.sensor_data.arn
}

output "stream_id" {
  description = "ID of the Kinesis stream"
  value       = aws_kinesis_stream.sensor_data.id
}

output "kms_key_id" {
  description = "ID of the KMS key used for encryption"
  value       = var.encryption_type == "KMS" ? aws_kms_key.kinesis[0].id : null
}
