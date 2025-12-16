output "application_name" {
  description = "Name of the Flink application"
  value       = aws_kinesisanalyticsv2_application.processor.name
}

output "application_arn" {
  description = "ARN of the Flink application"
  value       = aws_kinesisanalyticsv2_application.processor.arn
}

output "application_id" {
  description = "ID of the Flink application"
  value       = aws_kinesisanalyticsv2_application.processor.id
}
