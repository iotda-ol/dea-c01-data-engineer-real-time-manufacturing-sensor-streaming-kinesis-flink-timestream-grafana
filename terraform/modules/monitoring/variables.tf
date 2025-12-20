variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "kinesis_stream_name" {
  description = "Name of the Kinesis stream to monitor"
  type        = string
}

variable "flink_app_name" {
  description = "Name of the Flink application to monitor"
  type        = string
}

variable "alarm_email" {
  description = "Email address for alarm notifications"
  type        = string
  default     = ""
}
