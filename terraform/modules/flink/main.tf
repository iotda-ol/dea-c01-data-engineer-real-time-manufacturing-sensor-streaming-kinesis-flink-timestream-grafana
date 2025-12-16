# Amazon Managed Service for Apache Flink module

# CloudWatch Log Group for Flink application
resource "aws_cloudwatch_log_group" "flink" {
  name              = "/aws/kinesis-analytics/${var.application_name}"
  retention_in_days = 7
  
  tags = {
    Name        = var.application_name
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_stream" "flink" {
  name           = "${var.application_name}-stream"
  log_group_name = aws_cloudwatch_log_group.flink.name
}

# Flink application
resource "aws_kinesisanalyticsv2_application" "processor" {
  name                   = var.application_name
  runtime_environment    = var.runtime_environment
  service_execution_role = var.service_execution_role
  
  application_configuration {
    application_code_configuration {
      code_content {
        s3_content_location {
          bucket_arn = var.s3_bucket_arn
          file_key   = "flink-app.jar"
        }
      }
      
      code_content_type = "ZIPFILE"
    }
    
    environment_properties {
      property_group {
        property_group_id = "FlinkApplicationProperties"
        
        property_map = {
          "kinesis.stream.arn" = var.kinesis_stream_arn
          "region"             = data.aws_region.current.name
        }
      }
    }
    
    flink_application_configuration {
      checkpoint_configuration {
        configuration_type = "DEFAULT"
      }
      
      monitoring_configuration {
        configuration_type = "CUSTOM"
        log_level          = "INFO"
        metrics_level      = "APPLICATION"
      }
      
      parallelism_configuration {
        configuration_type   = "CUSTOM"
        auto_scaling_enabled = true
        parallelism          = 2
        parallelism_per_kpu  = 1
      }
    }
    
    application_snapshot_configuration {
      snapshots_enabled = true
    }
  }
  
  cloudwatch_logging_options {
    log_stream_arn = aws_cloudwatch_log_stream.flink.arn
  }
  
  tags = {
    Name        = var.application_name
    Environment = var.environment
  }
}

data "aws_region" "current" {}
