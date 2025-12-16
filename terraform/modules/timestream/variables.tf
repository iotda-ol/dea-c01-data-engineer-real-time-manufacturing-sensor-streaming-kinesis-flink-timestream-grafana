variable "database_name" {
  description = "Name of the Timestream database"
  type        = string
}

variable "table_name" {
  description = "Name of the Timestream table"
  type        = string
}

variable "memory_retention_hours" {
  description = "Memory store retention period in hours"
  type        = number
  default     = 24
}

variable "magnetic_retention_days" {
  description = "Magnetic store retention period in days"
  type        = number
  default     = 90
}

variable "environment" {
  description = "Environment name"
  type        = string
}
