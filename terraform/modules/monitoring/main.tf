# CloudWatch monitoring and alarms module

# SNS topic for alarms
resource "aws_sns_topic" "alarms" {
  name = "${var.project_name}-alarms-${var.environment}"
  
  tags = {
    Name        = "${var.project_name}-alarms"
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "email" {
  count = var.alarm_email != "" ? 1 : 0
  
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# Kinesis stream alarms
resource "aws_cloudwatch_metric_alarm" "kinesis_iterator_age" {
  alarm_name          = "${var.kinesis_stream_name}-high-iterator-age"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "GetRecords.IteratorAgeMilliseconds"
  namespace           = "AWS/Kinesis"
  period              = 300
  statistic           = "Maximum"
  threshold           = 60000  # 1 minute
  alarm_description   = "Kinesis stream has high iterator age"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  
  dimensions = {
    StreamName = var.kinesis_stream_name
  }
}

resource "aws_cloudwatch_metric_alarm" "kinesis_write_throughput" {
  alarm_name          = "${var.kinesis_stream_name}-write-throttled"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "WriteProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Kinesis stream is experiencing write throttling"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  
  dimensions = {
    StreamName = var.kinesis_stream_name
  }
}

resource "aws_cloudwatch_metric_alarm" "kinesis_read_throughput" {
  alarm_name          = "${var.kinesis_stream_name}-read-throttled"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReadProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Kinesis stream is experiencing read throttling"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  
  dimensions = {
    StreamName = var.kinesis_stream_name
  }
}

# Flink application alarms
resource "aws_cloudwatch_metric_alarm" "flink_downtime" {
  alarm_name          = "${var.flink_app_name}-downtime"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "uptime"
  namespace           = "AWS/KinesisAnalytics"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Flink application is down"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "breaching"
  
  dimensions = {
    Application = var.flink_app_name
  }
}

resource "aws_cloudwatch_metric_alarm" "flink_checkpoints_failed" {
  alarm_name          = "${var.flink_app_name}-checkpoint-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "numFailedCheckpoints"
  namespace           = "AWS/KinesisAnalytics"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Flink application has too many checkpoint failures"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  
  dimensions = {
    Application = var.flink_app_name
  }
}

resource "aws_cloudwatch_metric_alarm" "flink_cpu_utilization" {
  alarm_name          = "${var.flink_app_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "cpuUtilization"
  namespace           = "AWS/KinesisAnalytics"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Flink application has high CPU utilization"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  
  dimensions = {
    Application = var.flink_app_name
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Kinesis", "IncomingRecords", { stat = "Sum", label = "Incoming Records", dimensions = { StreamName = var.kinesis_stream_name } }],
            [".", "IncomingBytes", { stat = "Sum", label = "Incoming Bytes", dimensions = { StreamName = var.kinesis_stream_name } }]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Kinesis Stream Ingestion"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/KinesisAnalytics", "uptime", { stat = "Average", label = "Uptime", dimensions = { Application = var.flink_app_name } }],
            [".", "cpuUtilization", { stat = "Average", label = "CPU %", dimensions = { Application = var.flink_app_name } }],
            [".", "heapMemoryUtilization", { stat = "Average", label = "Heap Memory %", dimensions = { Application = var.flink_app_name } }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Flink Application Metrics"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Kinesis", "GetRecords.IteratorAgeMilliseconds", { stat = "Maximum", label = "Iterator Age", dimensions = { StreamName = var.kinesis_stream_name } }]
          ]
          period = 300
          stat   = "Maximum"
          region = data.aws_region.current.name
          title  = "Kinesis Iterator Age"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/KinesisAnalytics", "numFailedCheckpoints", { stat = "Sum", label = "Failed Checkpoints", dimensions = { Application = var.flink_app_name } }],
            [".", "lastCheckpointDuration", { stat = "Average", label = "Checkpoint Duration (ms)", dimensions = { Application = var.flink_app_name } }]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Flink Checkpoint Metrics"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      }
    ]
  })
}

data "aws_region" "current" {}
