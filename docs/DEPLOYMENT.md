# Deployment Guide

## Prerequisites

### Required Tools
- Terraform >= 1.0
- AWS CLI >= 2.0
- Python 3.8+
- AWS Account with appropriate permissions

### AWS Permissions Required
- Kinesis: Full access
- Kinesis Analytics (Flink): Full access
- Timestream: Full access
- IAM: Create roles and policies
- S3: Create and manage buckets
- CloudWatch: Logs and metrics
- KMS: Create and manage keys

## Step 1: Clone Repository

```bash
git clone https://github.com/iotda-ol/dea-c01-data-engineer-real-time-manufacturing-sensor-streaming-kinesis-flink-timestream-grafana.git
cd dea-c01-data-engineer-real-time-manufacturing-sensor-streaming-kinesis-flink-timestream-grafana
```

## Step 2: Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (e.g., us-east-1)
# Enter your output format (json)
```

## Step 3: Initialize Terraform

```bash
cd terraform
terraform init
```

## Step 4: Configure Variables

Create `terraform.tfvars`:

```hcl
aws_region                        = "us-east-1"
environment                       = "dev"
project_name                      = "manufacturing-analytics"
kinesis_shard_count              = 2
kinesis_retention_hours          = 24
timestream_memory_retention_hours = 24
timestream_magnetic_retention_days = 90
alarm_email                       = "your-email@example.com"
```

## Step 5: Plan Infrastructure

```bash
terraform plan
```

Review the plan to ensure all resources are correct.

## Step 6: Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm.

**Expected Resources Created**:
- 1 Kinesis Data Stream
- 1 Flink Application
- 1 Timestream Database
- 1 Timestream Table
- 3 IAM Roles (Flink, Producer, Grafana)
- 1 S3 Bucket (Flink artifacts)
- 1 S3 Bucket (Rejected data)
- 2 KMS Keys (Kinesis, Timestream)
- 5+ CloudWatch Alarms
- 1 CloudWatch Dashboard
- 1 SNS Topic

**Deployment Time**: ~10-15 minutes

## Step 7: Verify Deployment

```bash
# Check Kinesis stream
aws kinesis describe-stream --stream-name manufacturing-analytics-sensor-data-dev

# Check Timestream database
aws timestream-write describe-database --database-name manufacturing-analytics-db-dev

# Check Flink application
aws kinesisanalyticsv2 describe-application --application-name manufacturing-analytics-processor-dev
```

## Step 8: Set Up Python Producer

```bash
cd ../python/producer

# Install dependencies
pip install -r requirements.txt

# Run producer
python sensor_data_producer.py \
  --stream-name manufacturing-analytics-sensor-data-dev \
  --region us-east-1 \
  --interval 1.0 \
  --batch-size 10
```

**Expected Output**:
```
2024-01-15 10:00:00 - INFO - Starting continuous data generation...
2024-01-15 10:00:01 - INFO - Successfully sent 10 records to stream
2024-01-15 10:00:01 - INFO - Total records sent: 10
```

## Step 9: Start Flink Application

The Flink application needs to be started manually:

```bash
aws kinesisanalyticsv2 start-application \
  --application-name manufacturing-analytics-processor-dev \
  --run-configuration '{}'
```

**Note**: For production deployment with Java/Scala Flink application:

1. Build the JAR file:
```bash
cd python/flink_app
# Build your Java/Scala Flink application
mvn clean package
```

2. Upload to S3:
```bash
aws s3 cp target/flink-app.jar s3://$(terraform output -raw s3_artifacts_bucket)/flink-app.jar
```

3. Update Flink application:
```bash
aws kinesisanalyticsv2 update-application \
  --application-name manufacturing-analytics-processor-dev \
  --current-application-version-id 1 \
  --application-configuration-update '{
    "ApplicationCodeConfigurationUpdate": {
      "CodeContentUpdate": {
        "S3ContentLocationUpdate": {
          "BucketARNUpdate": "arn:aws:s3:::YOUR-BUCKET",
          "FileKeyUpdate": "flink-app.jar"
        }
      }
    }
  }'
```

## Step 10: Verify Data Flow

### Check Kinesis Metrics
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Kinesis \
  --metric-name IncomingRecords \
  --dimensions Name=StreamName,Value=manufacturing-analytics-sensor-data-dev \
  --statistics Sum \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60
```

### Check Timestream Data
```bash
aws timestream-query query \
  --query-string "SELECT * FROM \"manufacturing-analytics-db-dev\".\"manufacturing-analytics-metrics-dev\" ORDER BY time DESC LIMIT 10"
```

## Step 11: Set Up Grafana

See [grafana/README.md](../grafana/README.md) for detailed Grafana setup instructions.

Quick start:
```bash
# Install Grafana
brew install grafana  # macOS
# or
sudo apt-get install grafana  # Ubuntu

# Start Grafana
grafana-server

# Access Grafana at http://localhost:3000
# Default credentials: admin/admin
```

## Environment-Specific Deployments

### Development
```bash
terraform workspace new dev
terraform workspace select dev
terraform apply -var-file=environments/dev/terraform.tfvars
```

### Production
```bash
terraform workspace new prod
terraform workspace select prod
terraform apply -var-file=environments/prod/terraform.tfvars
```

## Monitoring Deployment

### CloudWatch Dashboard
Visit AWS Console → CloudWatch → Dashboards → `manufacturing-analytics-dev`

### Alarms
If configured with email, confirm SNS subscription:
1. Check email for "AWS Notification - Subscription Confirmation"
2. Click "Confirm subscription"

### Logs
```bash
# Flink application logs
aws logs tail /aws/kinesis-analytics/manufacturing-analytics-processor-dev --follow
```

## Troubleshooting

### Issue: Terraform Apply Fails

**Error**: "Stream already exists"
- **Solution**: Import existing resource or destroy and recreate
```bash
terraform import module.kinesis.aws_kinesis_stream.sensor_data manufacturing-analytics-sensor-data-dev
```

### Issue: Producer Cannot Write to Kinesis

**Error**: "Access Denied"
- **Solution**: Ensure IAM credentials have kinesis:PutRecord permission
- Use the producer role created by Terraform

### Issue: Flink Application Won't Start

**Error**: "Application code not found"
- **Solution**: Upload JAR file to S3 bucket
```bash
# Create a dummy JAR for testing
echo "dummy" > dummy.jar
aws s3 cp dummy.jar s3://$(terraform output -raw s3_artifacts_bucket)/flink-app.jar
```

### Issue: No Data in Timestream

**Error**: "No records found"
- **Solution**: 
  1. Verify producer is running
  2. Check Flink application is started
  3. Check Flink logs for errors
  4. Verify IAM permissions

### Issue: Grafana Cannot Connect to Timestream

**Error**: "Connection failed"
- **Solution**:
  1. Install Timestream plugin
  2. Configure AWS credentials
  3. Verify IAM role has timestream:Select permission

## Cleanup

To destroy all resources:

```bash
# Stop producer (Ctrl+C)

# Stop Flink application
aws kinesisanalyticsv2 stop-application \
  --application-name manufacturing-analytics-processor-dev

# Destroy infrastructure
cd terraform
terraform destroy
```

Type `yes` when prompted to confirm.

**Warning**: This will delete all data in Timestream and Kinesis. Ensure you have backups if needed.

## Cost Estimation

Approximate monthly costs for development environment (us-east-1):

- Kinesis Data Streams (2 shards): ~$30
- Managed Flink (2 KPU): ~$150
- Timestream (1 GB storage): ~$1-5
- CloudWatch (logs, metrics): ~$5-10
- S3 (artifacts): <$1
- Data Transfer: ~$5-10

**Total**: ~$191-206/month

For production, adjust shard count, KPUs, and retention periods based on workload.

## Best Practices

1. **Use Terraform Workspaces**: Separate dev/staging/prod environments
2. **Enable CloudWatch Alarms**: Get notified of issues
3. **Monitor Costs**: Use AWS Cost Explorer
4. **Regular Backups**: Take Flink snapshots regularly
5. **Security**: Rotate IAM credentials regularly
6. **Scaling**: Monitor metrics and adjust resources
7. **Documentation**: Keep Terraform variables documented
8. **Version Control**: Commit Terraform state to remote backend
9. **Testing**: Test in dev before deploying to prod
10. **Monitoring**: Set up comprehensive CloudWatch dashboards

## Next Steps

1. Customize Grafana dashboards for your use case
2. Implement custom Flink aggregations
3. Add more sensors and metrics
4. Configure alerting rules in Grafana
5. Set up CI/CD pipeline for Flink application
6. Implement data quality checks
7. Add machine learning for anomaly detection
8. Create reports and analytics
