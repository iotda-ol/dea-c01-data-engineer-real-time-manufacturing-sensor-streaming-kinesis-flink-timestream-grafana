output "database_name" {
  description = "Name of the Timestream database"
  value       = aws_timestreamwrite_database.manufacturing.database_name
}

output "database_arn" {
  description = "ARN of the Timestream database"
  value       = aws_timestreamwrite_database.manufacturing.arn
}

output "table_name" {
  description = "Name of the Timestream table"
  value       = aws_timestreamwrite_table.metrics.table_name
}

output "table_arn" {
  description = "ARN of the Timestream table"
  value       = aws_timestreamwrite_table.metrics.arn
}
