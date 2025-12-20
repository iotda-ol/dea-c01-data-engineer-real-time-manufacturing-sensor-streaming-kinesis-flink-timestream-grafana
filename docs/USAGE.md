# Usage Guide

## Running the Data Producer

### Basic Usage

```bash
cd python/producer
python sensor_data_producer.py \
  --stream-name manufacturing-analytics-sensor-data-dev \
  --region us-east-1
```

### Advanced Options

```bash
python sensor_data_producer.py \
  --stream-name manufacturing-analytics-sensor-data-dev \
  --region us-east-1 \
  --interval 2.0 \           # Send batches every 2 seconds
  --batch-size 50 \          # 50 records per batch
  --debug                    # Enable debug logging
```

### Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--stream-name` | Kinesis stream name (required) | - |
| `--region` | AWS region | us-east-1 |
| `--interval` | Seconds between batches | 1.0 |
| `--batch-size` | Records per batch | 10 |
| `--debug` | Enable debug logging | False |

### Understanding the Data

Each sensor reading includes:

```json
{
  "sensor_id": "SENSOR-001",
  "machine_id": "MACHINE-01",
  "production_line": "LINE-A",
  "timestamp": "2024-01-15T10:00:00.123Z",
  "measurements": {
    "temperature_celsius": 75.23,
    "pressure_psi": 98.45,
    "vibration_mms": 0.52,
    "power_kw": 48.76
  },
  "production": {
    "items_produced": 95,
    "quality_score": 96.5,
    "downtime_minutes": 2
  },
  "status": "OPERATIONAL"
}
```

### Sensors and Configuration

- **10 Sensors**: SENSOR-001 through SENSOR-010
- **5 Machines**: MACHINE-01 through MACHINE-05
- **3 Production Lines**: LINE-A, LINE-B, LINE-C

### Data Patterns

The producer generates realistic data:
- Normal operation with Gaussian distribution
- 5% anomaly rate (high temperature, high vibration)
- Correlated metrics (power vs production)
- Status changes based on thresholds

## Querying Timestream

### AWS CLI

```bash
# View recent temperature data
aws timestream-query query \
  --query-string "SELECT sensor_id, machine_id, measure_value::double as temperature, time 
                  FROM \"manufacturing-analytics-db-dev\".\"manufacturing-analytics-metrics-dev\" 
                  WHERE measure_name = 'temperature_celsius' 
                  ORDER BY time DESC 
                  LIMIT 10"
```

### Common Queries

#### Average Temperature by Machine (Last Hour)
```sql
SELECT 
  machine_id, 
  AVG(measure_value::double) as avg_temp,
  BIN(time, 5m) as time_bucket
FROM "manufacturing-analytics-db-dev"."manufacturing-analytics-metrics-dev"
WHERE 
  measure_name = 'temperature_celsius' 
  AND time > ago(1h)
GROUP BY machine_id, BIN(time, 5m)
ORDER BY time_bucket DESC
```

#### Total Production by Line
```sql
SELECT 
  production_line,
  SUM(measure_value::bigint) as total_items,
  BIN(time, 1h) as time_bucket
FROM "manufacturing-analytics-db-dev"."manufacturing-analytics-metrics-dev"
WHERE 
  measure_name = 'items_produced' 
  AND time > ago(24h)
GROUP BY production_line, BIN(time, 1h)
ORDER BY time_bucket DESC
```

#### Quality Score Trends
```sql
SELECT 
  machine_id,
  AVG(measure_value::double) as avg_quality,
  MIN(measure_value::double) as min_quality,
  MAX(measure_value::double) as max_quality,
  BIN(time, 15m) as time_bucket
FROM "manufacturing-analytics-db-dev"."manufacturing-analytics-metrics-dev"
WHERE 
  measure_name = 'quality_score' 
  AND time > ago(4h)
GROUP BY machine_id, BIN(time, 15m)
ORDER BY time_bucket DESC
```

#### Anomaly Detection (High Temperature)
```sql
SELECT 
  sensor_id,
  machine_id,
  measure_value::double as temperature,
  time
FROM "manufacturing-analytics-db-dev"."manufacturing-analytics-metrics-dev"
WHERE 
  measure_name = 'temperature_celsius' 
  AND measure_value::double > 90
  AND time > ago(1h)
ORDER BY time DESC
```

#### Downtime Analysis
```sql
SELECT 
  production_line,
  machine_id,
  SUM(measure_value::bigint) as total_downtime_min,
  COUNT(*) as occurrences
FROM "manufacturing-analytics-db-dev"."manufacturing-analytics-metrics-dev"
WHERE 
  measure_name = 'downtime_minutes' 
  AND measure_value::bigint > 0
  AND time > ago(24h)
GROUP BY production_line, machine_id
ORDER BY total_downtime_min DESC
```

## Monitoring with CloudWatch

### View Dashboard

1. AWS Console → CloudWatch → Dashboards
2. Select `manufacturing-analytics-dev`

### Check Alarms

```bash
# List all alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix manufacturing-analytics

# Check alarm state
aws cloudwatch describe-alarms \
  --alarm-names "manufacturing-analytics-sensor-data-dev-high-iterator-age" \
  --query 'MetricAlarms[0].StateValue'
```

### View Metrics

```bash
# Kinesis incoming records
aws cloudwatch get-metric-statistics \
  --namespace AWS/Kinesis \
  --metric-name IncomingRecords \
  --dimensions Name=StreamName,Value=manufacturing-analytics-sensor-data-dev \
  --statistics Sum \
  --start-time $(date -u -d '30 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300

# Flink CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/KinesisAnalytics \
  --metric-name cpuUtilization \
  --dimensions Name=Application,Value=manufacturing-analytics-processor-dev \
  --statistics Average \
  --start-time $(date -u -d '30 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300
```

### View Logs

```bash
# Flink application logs
aws logs tail /aws/kinesis-analytics/manufacturing-analytics-processor-dev --follow

# Filter for errors
aws logs filter-log-events \
  --log-group-name /aws/kinesis-analytics/manufacturing-analytics-processor-dev \
  --filter-pattern "ERROR"
```

## Managing Flink Application

### Check Application Status

```bash
aws kinesisanalyticsv2 describe-application \
  --application-name manufacturing-analytics-processor-dev \
  --query 'ApplicationDetail.ApplicationStatus'
```

### Start Application

```bash
aws kinesisanalyticsv2 start-application \
  --application-name manufacturing-analytics-processor-dev \
  --run-configuration '{}'
```

### Stop Application

```bash
aws kinesisanalyticsv2 stop-application \
  --application-name manufacturing-analytics-processor-dev
```

### Create Snapshot

```bash
aws kinesisanalyticsv2 create-application-snapshot \
  --application-name manufacturing-analytics-processor-dev \
  --snapshot-name backup-$(date +%Y%m%d-%H%M%S)
```

### List Snapshots

```bash
aws kinesisanalyticsv2 list-application-snapshots \
  --application-name manufacturing-analytics-processor-dev
```

## Scaling Resources

### Scale Kinesis Shards

```bash
# Update shard count
aws kinesis update-shard-count \
  --stream-name manufacturing-analytics-sensor-data-dev \
  --target-shard-count 4 \
  --scaling-type UNIFORM_SCALING
```

Or update in Terraform:
```hcl
# terraform/terraform.tfvars
kinesis_shard_count = 4
```

Then apply:
```bash
terraform apply
```

### Scale Flink Parallelism

Update `terraform/modules/flink/main.tf`:
```hcl
parallelism_configuration {
  parallelism = 4  # Increase from 2
}
```

Then apply:
```bash
terraform apply
```

## Testing Data Pipeline

### End-to-End Test

1. **Start Producer**:
```bash
python sensor_data_producer.py --stream-name manufacturing-analytics-sensor-data-dev
```

2. **Check Kinesis**:
```bash
aws kinesis get-records \
  --shard-iterator $(aws kinesis get-shard-iterator \
    --stream-name manufacturing-analytics-sensor-data-dev \
    --shard-id shardId-000000000000 \
    --shard-iterator-type LATEST \
    --query 'ShardIterator' \
    --output text) \
  --limit 5
```

3. **Verify Flink Processing**:
```bash
aws logs tail /aws/kinesis-analytics/manufacturing-analytics-processor-dev --follow
```

4. **Query Timestream**:
```bash
aws timestream-query query \
  --query-string "SELECT COUNT(*) as record_count FROM \"manufacturing-analytics-db-dev\".\"manufacturing-analytics-metrics-dev\" WHERE time > ago(5m)"
```

5. **View in Grafana**: Open dashboard at http://localhost:3000

### Performance Testing

Generate high load:
```bash
# Run multiple producers in parallel
for i in {1..5}; do
  python sensor_data_producer.py \
    --stream-name manufacturing-analytics-sensor-data-dev \
    --batch-size 100 \
    --interval 0.1 &
done
```

Monitor performance:
```bash
# Watch CloudWatch metrics
watch -n 5 'aws cloudwatch get-metric-statistics \
  --namespace AWS/Kinesis \
  --metric-name IncomingRecords \
  --dimensions Name=StreamName,Value=manufacturing-analytics-sensor-data-dev \
  --statistics Sum \
  --start-time $(date -u -d "5 minutes ago" +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60'
```

## Backup and Recovery

### Create Backup

```bash
# Export Timestream data (last 24 hours)
aws timestream-query query \
  --query-string "SELECT * FROM \"manufacturing-analytics-db-dev\".\"manufacturing-analytics-metrics-dev\" WHERE time > ago(24h)" \
  --output json > backup-$(date +%Y%m%d).json
```

### Replay Data from Kinesis

If Flink failed and you need to reprocess:
```bash
# Stop Flink application
aws kinesisanalyticsv2 stop-application \
  --application-name manufacturing-analytics-processor-dev

# Start from specific timestamp or LATEST/TRIM_HORIZON
aws kinesisanalyticsv2 start-application \
  --application-name manufacturing-analytics-processor-dev \
  --run-configuration '{
    "ApplicationRestoreConfiguration": {
      "ApplicationRestoreType": "RESTORE_FROM_CUSTOM_SNAPSHOT",
      "SnapshotName": "your-snapshot-name"
    }
  }'
```

## Cleanup

### Stop All Services

```bash
# Stop producer (Ctrl+C)

# Stop Flink
aws kinesisanalyticsv2 stop-application \
  --application-name manufacturing-analytics-processor-dev

# Destroy infrastructure
cd terraform
terraform destroy
```

## Tips and Tricks

### Reduce Costs in Development
- Use fewer shards (1-2)
- Shorter retention periods
- Stop Flink when not in use

### Debug Data Issues
- Check producer logs for send errors
- View Kinesis metrics for throttling
- Check Flink logs for processing errors
- Query Timestream for data gaps

### Optimize Query Performance
- Use appropriate time ranges
- Limit result set size
- Use BIN() for time aggregations
- Create appropriate indexes via dimensions

### Monitor Data Freshness
```sql
SELECT 
  MAX(time) as latest_data,
  DATE_DIFF('second', MAX(time), now()) as seconds_old
FROM "manufacturing-analytics-db-dev"."manufacturing-analytics-metrics-dev"
```
