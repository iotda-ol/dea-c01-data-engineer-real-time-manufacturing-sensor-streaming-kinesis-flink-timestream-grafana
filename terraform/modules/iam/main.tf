# IAM module with least privilege access for all components

# Flink application execution role
resource "aws_iam_role" "flink_execution" {
  name = "${var.project_name}-flink-execution-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "kinesisanalytics.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = {
    Name        = "${var.project_name}-flink-execution-${var.environment}"
    Environment = var.environment
  }
}

# Flink policy - least privilege access to required resources
resource "aws_iam_role_policy" "flink_execution" {
  name = "${var.project_name}-flink-policy-${var.environment}"
  role = aws_iam_role.flink_execution.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadKinesisStream"
        Effect = "Allow"
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:ListShards"
        ]
        Resource = var.kinesis_stream_arn
      },
      {
        Sid    = "WriteToTimestream"
        Effect = "Allow"
        Action = [
          "timestream:WriteRecords",
          "timestream:DescribeEndpoints"
        ]
        Resource = var.timestream_table_arn
      },
      {
        Sid    = "DescribeTimestreamDatabase"
        Effect = "Allow"
        Action = [
          "timestream:DescribeDatabase"
        ]
        Resource = var.timestream_db_arn
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/kinesis-analytics/*"
      },
      {
        Sid    = "CloudWatchMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "AWS/KinesisAnalytics"
          }
        }
      }
    ]
  })
}

# Data producer role
resource "aws_iam_role" "producer" {
  name = "${var.project_name}-producer-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = {
    Name        = "${var.project_name}-producer-${var.environment}"
    Environment = var.environment
  }
}

# Producer policy - least privilege to write to Kinesis
resource "aws_iam_role_policy" "producer" {
  name = "${var.project_name}-producer-policy-${var.environment}"
  role = aws_iam_role.producer.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteToKinesisStream"
        Effect = "Allow"
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords",
          "kinesis:DescribeStream"
        ]
        Resource = var.kinesis_stream_arn
      },
      {
        Sid    = "CloudWatchMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "ManufacturingProducer"
          }
        }
      }
    ]
  })
}

# Instance profile for producer
resource "aws_iam_instance_profile" "producer" {
  name = "${var.project_name}-producer-${var.environment}"
  role = aws_iam_role.producer.name
}

# Grafana role for Timestream read access
resource "aws_iam_role" "grafana" {
  name = "${var.project_name}-grafana-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = {
    Name        = "${var.project_name}-grafana-${var.environment}"
    Environment = var.environment
  }
}

# Grafana policy - read-only access to Timestream
resource "aws_iam_role_policy" "grafana" {
  name = "${var.project_name}-grafana-policy-${var.environment}"
  role = aws_iam_role.grafana.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadTimestream"
        Effect = "Allow"
        Action = [
          "timestream:DescribeEndpoints",
          "timestream:Select",
          "timestream:DescribeTable",
          "timestream:ListMeasures"
        ]
        Resource = [
          var.timestream_table_arn,
          var.timestream_db_arn
        ]
      },
      {
        Sid    = "ListTimestreamDatabases"
        Effect = "Allow"
        Action = [
          "timestream:ListDatabases",
          "timestream:ListTables"
        ]
        Resource = "*"
      }
    ]
  })
}
