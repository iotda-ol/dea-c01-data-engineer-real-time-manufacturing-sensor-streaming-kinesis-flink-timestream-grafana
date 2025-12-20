# Variables for Real-Time Manufacturing Analytics Platform

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "manufacturing-analytics"
}

# Kinesis variables
variable "kinesis_shard_count" {
  description = "Number of shards for Kinesis Data Stream"
  type        = number
  default     = 2
}

variable "kinesis_retention_hours" {
  description = "Data retention period in hours"
  type        = number
  default     = 24
}

# Timestream variables
variable "timestream_memory_retention_hours" {
  description = "Memory store retention in hours"
  type        = number
  default     = 24
}

variable "timestream_magnetic_retention_days" {
  description = "Magnetic store retention in days"
  type        = number
  default     = 90
}

# Monitoring variables
variable "alarm_email" {
  description = "Email address for CloudWatch alarms"
  type        = string
  default     = ""
}
