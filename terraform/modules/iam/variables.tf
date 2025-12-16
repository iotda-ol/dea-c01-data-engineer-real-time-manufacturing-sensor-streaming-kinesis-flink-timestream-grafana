variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "kinesis_stream_arn" {
  description = "ARN of the Kinesis Data Stream"
  type        = string
}

variable "timestream_db_arn" {
  description = "ARN of the Timestream database"
  type        = string
}

variable "timestream_table_arn" {
  description = "ARN of the Timestream table"
  type        = string
}
