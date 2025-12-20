# Grafana Dashboard Configuration

## Overview
This directory contains Grafana dashboard configurations for visualizing real-time manufacturing metrics from Amazon Timestream.

## Setup Instructions

### 1. Install Grafana

#### Option A: Docker
```bash
docker run -d -p 3000:3000 --name=grafana grafana/grafana
```

#### Option B: Local Installation
- macOS: `brew install grafana`
- Ubuntu/Debian: Follow [Grafana installation guide](https://grafana.com/docs/grafana/latest/setup-grafana/installation/)

### 2. Install Timestream Plugin

```bash
grafana-cli plugins install grafana-timestream-datasource
```

Or install from Grafana UI:
1. Go to Configuration → Plugins
2. Search for "Amazon Timestream"
3. Click Install

### 3. Configure AWS Credentials

Grafana needs AWS credentials to access Timestream. Choose one method:

#### Option A: IAM Role (Recommended for EC2)
If running Grafana on EC2, attach the IAM role created by Terraform:
- Role name: `manufacturing-analytics-grafana-dev`

#### Option B: AWS Credentials File
Configure `~/.aws/credentials`:
```ini
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
```

#### Option C: Environment Variables
```bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_REGION=us-east-1
```

### 4. Add Timestream Data Source

1. Log in to Grafana (default: http://localhost:3000, admin/admin)
2. Go to Configuration → Data Sources
3. Click "Add data source"
4. Select "Amazon Timestream"
5. Configure:
   - **Name**: Timestream
   - **Auth Provider**: AWS SDK Default or EC2 IAM Role
   - **Default Region**: us-east-1
   - **Default Database**: manufacturing-analytics-db-dev
   - **Default Table**: manufacturing-analytics-metrics-dev
6. Click "Save & Test"

Or use the provided `datasource.yaml` for provisioning:
```bash
cp datasource.yaml /etc/grafana/provisioning/datasources/
```

### 5. Import Dashboard

#### Option A: Import from JSON
1. In Grafana, go to Dashboards → Import
2. Upload `dashboards/manufacturing-metrics.json`
3. Select the Timestream data source
4. Click Import

#### Option B: Provision Dashboard
```bash
cp dashboards/manufacturing-metrics.json /etc/grafana/provisioning/dashboards/
```

## Dashboard Panels

The Manufacturing Analytics dashboard includes:

### 1. Average Temperature by Machine
- **Type**: Time series
- **Metric**: temperature_celsius
- **Aggregation**: AVG grouped by machine_id
- **Window**: 1-minute bins

### 2. Items Produced by Production Line
- **Type**: Time series
- **Metric**: items_produced
- **Aggregation**: SUM grouped by production_line
- **Window**: 1-minute bins

### 3. Overall Quality Score
- **Type**: Gauge
- **Metric**: quality_score
- **Aggregation**: AVG over last 5 minutes
- **Thresholds**: Green (>95%), Yellow (90-95%), Red (<90%)

### 4. Power Consumption by Line
- **Type**: Time series
- **Metric**: power_kw
- **Aggregation**: AVG grouped by production_line
- **Window**: 1-minute bins

### 5. Vibration Levels by Machine
- **Type**: Time series
- **Metric**: vibration_mms
- **Aggregation**: AVG grouped by machine_id
- **Window**: 1-minute bins
- **Thresholds**: Normal (<0.8), Warning (0.8-1.5), Critical (>1.5)

### 6. Total Downtime
- **Type**: Gauge
- **Metric**: downtime_minutes
- **Aggregation**: SUM over last hour
- **Thresholds**: Green (<5), Yellow (5-10), Red (>10)

## Customization

### Modify Time Range
- Default: Last 15 minutes
- Auto-refresh: 5 seconds
- Adjust in dashboard settings

### Add New Panels
Example Timestream query:
```sql
SELECT 
  machine_id, 
  AVG(measure_value::double) as avg_pressure 
FROM $__database.$__table 
WHERE 
  measure_name = 'pressure_psi' 
  AND time > ago(15m) 
GROUP BY 
  machine_id, 
  BIN(time, 1m) 
ORDER BY time DESC
```

### Alert Configuration
1. Edit panel
2. Go to Alert tab
3. Create alert rule
4. Configure notification channels (email, Slack, PagerDuty, etc.)

## Timestream Query Syntax

### Time Functions
- `ago(15m)` - 15 minutes ago
- `ago(1h)` - 1 hour ago
- `ago(1d)` - 1 day ago

### Aggregation Functions
- `AVG()` - Average
- `SUM()` - Sum
- `MIN()` - Minimum
- `MAX()` - Maximum
- `COUNT()` - Count

### Grouping
- `GROUP BY machine_id` - Group by dimension
- `BIN(time, 1m)` - 1-minute time bins
- `BIN(time, 5m)` - 5-minute time bins

### Type Casting
- `measure_value::double` - Cast to double
- `measure_value::bigint` - Cast to bigint

## Troubleshooting

### Data Source Connection Failed
- Verify AWS credentials
- Check IAM permissions (timestream:Select, timestream:DescribeEndpoints)
- Verify region matches Timestream database

### No Data in Panels
- Verify producer is running and sending data
- Check Flink application is processing records
- Verify Timestream database and table names
- Adjust time range (data may be outside current window)

### Query Errors
- Check measure_name in WHERE clause matches actual data
- Verify type casting (::double vs ::bigint)
- Ensure dimensions exist in data

## Resources
- [Grafana Timestream Plugin Documentation](https://grafana.com/grafana/plugins/grafana-timestream-datasource/)
- [Amazon Timestream Query Language Reference](https://docs.aws.amazon.com/timestream/latest/developerguide/reference.html)
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
