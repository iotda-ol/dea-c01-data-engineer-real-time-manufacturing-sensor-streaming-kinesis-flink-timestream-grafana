# Flink Application for Manufacturing Analytics

## Overview
This directory contains the Apache Flink application for processing manufacturing sensor data in real-time.

## Implementation Notes

### Python Reference Implementation
The `flink_processor.py` file provides a Python reference implementation for testing and understanding the data flow. It demonstrates:
- Reading from Kinesis Data Streams
- Transforming sensor data
- Writing to Amazon Timestream
- Basic aggregation logic

### Production Deployment
For production use with **Amazon Managed Service for Apache Flink**, you should:

1. **Use Java/Scala or PyFlink**: Amazon Managed Service for Apache Flink supports:
   - Apache Flink Java (recommended for production)
   - Apache Flink Scala
   - PyFlink (Python API for Flink)

2. **Build JAR file**: For Java/Scala applications:
   ```bash
   mvn clean package
   ```

3. **Upload to S3**: Upload the JAR to the S3 bucket created by Terraform:
   ```bash
   aws s3 cp target/flink-app.jar s3://your-flink-artifacts-bucket/
   ```

4. **Configure in Terraform**: The Terraform configuration expects the JAR at:
   - S3 Key: `flink-app.jar`

## Key Features

### Data Processing Pipeline
1. **Ingestion**: Read from Kinesis Data Streams
2. **Transformation**: Parse JSON and enrich data
3. **Aggregation**: Calculate metrics per production line, machine, sensor
4. **Storage**: Write to Amazon Timestream

### Windowing (Production)
In production Flink applications, implement:
- Tumbling windows (e.g., 1-minute aggregations)
- Sliding windows (e.g., 5-minute rolling average)
- Session windows (e.g., group by production session)

### Example Aggregations
- Average temperature per machine (1-minute window)
- Total items produced per production line (5-minute window)
- Quality score trends (15-minute window)
- Anomaly detection (standard deviation thresholds)

## Testing Locally

Run the Python reference implementation:

```bash
python flink_processor.py \
  --stream-name manufacturing-analytics-sensor-data-dev \
  --timestream-db manufacturing-analytics-db-dev \
  --timestream-table manufacturing-analytics-metrics-dev \
  --region us-east-1
```

## Production Java Example Structure

```
src/main/java/
├── StreamingJob.java           # Main Flink application
├── deserializers/
│   └── SensorDataDeserializer.java
├── operators/
│   ├── AggregationFunction.java
│   └── TimestreamSink.java
└── models/
    └── SensorData.java
```

## Resources
- [Amazon Managed Service for Apache Flink Developer Guide](https://docs.aws.amazon.com/kinesisanalytics/latest/java/what-is.html)
- [Apache Flink Documentation](https://flink.apache.org/)
- [PyFlink Documentation](https://nightlies.apache.org/flink/flink-docs-master/docs/dev/python/overview/)
