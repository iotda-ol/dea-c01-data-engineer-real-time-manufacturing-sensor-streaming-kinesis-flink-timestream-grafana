variable "application_name" {
  description = "Name of the Flink application"
  type        = string
}

variable "runtime_environment" {
  description = "Runtime environment for Flink"
  type        = string
  default     = "FLINK-1_18"
}

variable "service_execution_role" {
  description = "ARN of the IAM role for Flink execution"
  type        = string
}

variable "kinesis_stream_arn" {
  description = "ARN of the Kinesis Data Stream"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for application code"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
