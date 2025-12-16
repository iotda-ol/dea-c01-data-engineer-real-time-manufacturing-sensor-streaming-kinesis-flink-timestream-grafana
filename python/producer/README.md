# Manufacturing Sensor Data Producer

## Overview

This Python application simulates manufacturing sensor data and streams it to Amazon Kinesis Data Streams. It generates realistic sensor readings from multiple production lines, machines, and sensors.

## Features

- **Realistic Data Generation**: Gaussian distribution with occasional anomalies
- **Multiple Entities**: 10 sensors, 5 machines, 3 production lines
- **Batch Processing**: Configurable batch size for efficient streaming
- **Error Handling**: Robust error handling and retry logic
- **Monitoring**: Built-in logging and metrics

## Installation

```bash
pip install -r requirements.txt
```

## Usage

### Basic Usage

```bash
python sensor_data_producer.py \
  --stream-name manufacturing-analytics-sensor-data-dev \
  --region us-east-1
```

### All Options

```bash
python sensor_data_producer.py \
  --stream-name <STREAM_NAME> \
  --region <AWS_REGION> \
  --interval <SECONDS> \
  --batch-size <NUM_RECORDS> \
  --debug
```

## Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `--stream-name` | Kinesis stream name | - | Yes |
| `--region` | AWS region | us-east-1 | No |
| `--interval` | Seconds between batches | 1.0 | No |
| `--batch-size` | Records per batch | 10 | No |
| `--debug` | Enable debug logging | False | No |

## Data Schema

### Sample Record

```json
{
  "sensor_id": "SENSOR-005",
  "machine_id": "MACHINE-03",
  "production_line": "LINE-B",
  "timestamp": "2024-01-15T14:30:45.123Z",
  "measurements": {
    "temperature_celsius": 78.45,
    "pressure_psi": 102.3,
    "vibration_mms": 0.48,
    "power_kw": 51.2
  },
  "production": {
    "items_produced": 98,
    "quality_score": 95.8,
    "downtime_minutes": 1
  },
  "status": "OPERATIONAL"
}
```

### Field Descriptions

#### Identifiers
- `sensor_id`: Unique sensor identifier (SENSOR-001 to SENSOR-010)
- `machine_id`: Machine identifier (MACHINE-01 to MACHINE-05)
- `production_line`: Production line (LINE-A, LINE-B, LINE-C)
- `timestamp`: ISO 8601 timestamp with milliseconds

#### Measurements
- `temperature_celsius`: Temperature in Celsius (mean: 75°C, std: 5°C)
- `pressure_psi`: Pressure in PSI (mean: 100 PSI, std: 10 PSI)
- `vibration_mms`: Vibration in mm/s (mean: 0.5 mm/s, std: 0.1 mm/s)
- `power_kw`: Power consumption in kilowatts (mean: 50 kW, std: 8 kW)

#### Production Metrics
- `items_produced`: Number of items produced (80-120 per reading)
- `quality_score`: Quality percentage (mean: 95%, std: 3%)
- `downtime_minutes`: Minutes of downtime (0-5 minutes)

#### Status
- `OPERATIONAL`: Normal operation (temperature < 100°C)
- `WARNING`: High temperature detected (temperature >= 100°C)

## Data Patterns

### Normal Operation
- Values follow Gaussian distribution
- Correlated metrics (higher production = higher power)
- Realistic variance

### Anomalies
- 5% chance of anomalies
- High temperature (+10 to +30°C)
- High vibration (+0.5 to +1.5 mm/s)
- Automatic status change to WARNING

## AWS Credentials

The producer uses boto3 and requires AWS credentials. Configure using one of:

### Option 1: Environment Variables
```bash
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_REGION=us-east-1
```

### Option 2: AWS Credentials File
```bash
aws configure
```

### Option 3: IAM Role (EC2)
Attach the IAM role created by Terraform:
- Role: `manufacturing-analytics-producer-dev`

## Performance

### Throughput
- Default: 10 records/second (batch_size=10, interval=1.0)
- Max tested: ~10,000 records/second (multiple instances)

### Resource Usage
- CPU: Low (~5% per instance)
- Memory: ~50 MB per instance
- Network: ~10 KB/s per 10 records/second

## Monitoring

### Logs
The producer outputs logs to stdout:
```
2024-01-15 10:00:00 - INFO - Starting continuous data generation...
2024-01-15 10:00:01 - INFO - Successfully sent 10 records to stream
2024-01-15 10:00:01 - INFO - Total records sent: 10
```

### Debug Mode
Enable with `--debug` flag for detailed information:
```
2024-01-15 10:00:01 - DEBUG - Sent record: SENSOR-001 - Shard: shardId-000000000000
```

### CloudWatch Metrics
Optionally, publish custom metrics:
```python
cloudwatch = boto3.client('cloudwatch')
cloudwatch.put_metric_data(
    Namespace='ManufacturingProducer',
    MetricData=[{
        'MetricName': 'RecordsSent',
        'Value': records_sent,
        'Unit': 'Count'
    }]
)
```

## Troubleshooting

### Error: "Stream not found"
- Verify stream name is correct
- Check if stream exists: `aws kinesis describe-stream --stream-name <name>`

### Error: "Access Denied"
- Verify AWS credentials are configured
- Check IAM permissions include `kinesis:PutRecord` and `kinesis:PutRecords`

### Error: "ProvisionedThroughputExceededException"
- Reduce batch size or increase interval
- Increase Kinesis shard count
- Check CloudWatch metrics for throttling

### High CPU Usage
- Reduce batch size
- Increase interval between batches
- Run fewer concurrent producers

## Examples

### Low-Volume Testing
```bash
python sensor_data_producer.py \
  --stream-name test-stream \
  --interval 5.0 \
  --batch-size 5
```

### High-Volume Load Test
```bash
# Run 10 producers in parallel
for i in {1..10}; do
  python sensor_data_producer.py \
    --stream-name test-stream \
    --batch-size 100 \
    --interval 0.5 &
done
```

### Production Simulation
```bash
python sensor_data_producer.py \
  --stream-name production-stream \
  --region us-east-1 \
  --batch-size 50 \
  --interval 1.0 \
  > producer.log 2>&1 &
```

## Customization

### Add New Sensors
Edit `SensorDataGenerator.__init__`:
```python
self.sensor_ids = [f"SENSOR-{i:03d}" for i in range(1, 21)]  # 20 sensors
```

### Add New Measurements
Edit `SensorDataGenerator.generate_sensor_reading`:
```python
"measurements": {
    "temperature_celsius": temperature,
    "humidity_percent": random.gauss(45, 5),  # New metric
    # ... other measurements
}
```

### Change Anomaly Rate
Edit `SensorDataGenerator.generate_sensor_reading`:
```python
if random.random() < 0.10:  # 10% anomaly rate instead of 5%
    # Generate anomaly
```

## Testing

### Unit Tests
```python
# test_producer.py
import unittest
from sensor_data_producer import SensorDataGenerator

class TestSensorDataGenerator(unittest.TestCase):
    def setUp(self):
        self.generator = SensorDataGenerator()
    
    def test_generate_reading(self):
        reading = self.generator.generate_sensor_reading()
        self.assertIn('sensor_id', reading)
        self.assertIn('measurements', reading)
        self.assertGreater(reading['measurements']['temperature_celsius'], 0)

if __name__ == '__main__':
    unittest.main()
```

## Dependencies

- `boto3`: AWS SDK for Python
- `botocore`: Low-level AWS service client
- Python 3.8+

## License

MIT License - See LICENSE file for details
