output "flink_role_arn" {
  description = "ARN of the Flink execution role"
  value       = aws_iam_role.flink_execution.arn
}

output "flink_role_name" {
  description = "Name of the Flink execution role"
  value       = aws_iam_role.flink_execution.name
}

output "producer_role_arn" {
  description = "ARN of the producer role"
  value       = aws_iam_role.producer.arn
}

output "producer_role_name" {
  description = "Name of the producer role"
  value       = aws_iam_role.producer.name
}

output "producer_instance_profile_name" {
  description = "Name of the producer instance profile"
  value       = aws_iam_instance_profile.producer.name
}

output "grafana_role_arn" {
  description = "ARN of the Grafana role"
  value       = aws_iam_role.grafana.arn
}
