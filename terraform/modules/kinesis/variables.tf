variable "stream_name" {
  description = "Name of the Kinesis Data Stream"
  type        = string
}

variable "shard_count" {
  description = "Number of shards for the stream"
  type        = number
  default     = 1
}

variable "retention_period" {
  description = "Data retention period in hours (24-8760)"
  type        = number
  default     = 24
}

variable "encryption_type" {
  description = "Encryption type (NONE or KMS)"
  type        = string
  default     = "KMS"
}

variable "environment" {
  description = "Environment name"
  type        = string
}
