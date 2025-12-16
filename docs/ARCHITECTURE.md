# Architecture Overview

## System Architecture

```
┌─────────────────┐
│   Sensors &     │
│   Machines      │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────┐
│   Data Producer (Python)        │
│   - Simulates sensor data       │
│   - 10 sensors, 5 machines      │
│   - 3 production lines          │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│   Amazon Kinesis Data Streams   │
│   - 2 shards (configurable)     │
│   - KMS encryption              │
│   - 24h retention               │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│   Amazon Managed Apache Flink   │
│   - Stream processing           │
│   - Aggregations & transforms   │
│   - Auto-scaling enabled        │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│   Amazon Timestream             │
│   - Time-series database        │
│   - 24h memory retention        │
│   - 90d magnetic retention      │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│   Grafana Dashboards            │
│   - Real-time visualization     │
│   - Alerts & monitoring         │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│   CloudWatch Monitoring         │
│   - Metrics & logs              │
│   - Alarms & notifications      │
└─────────────────────────────────┘
```

## Components

### 1. Data Ingestion Layer

#### Sensor Data Producer
- **Language**: Python 3
- **Function**: Generates simulated manufacturing sensor data
- **Metrics**:
  - Temperature (°C)
  - Pressure (PSI)
  - Vibration (mm/s)
  - Power consumption (kW)
  - Production count
  - Quality score
  - Downtime
- **Features**:
  - 10 sensors across 5 machines
  - 3 production lines
  - Realistic data with occasional anomalies
  - Configurable batch size and interval

#### Amazon Kinesis Data Streams
- **Purpose**: Scalable data ingestion
- **Configuration**:
  - Provisioned capacity mode
  - 2 shards (default, configurable)
  - 24-hour retention
  - Server-side encryption (KMS)
  - Enhanced monitoring enabled
- **Throughput**:
  - Write: 1 MB/sec per shard
  - Read: 2 MB/sec per shard
  - 1000 records/sec per shard

### 2. Stream Processing Layer

#### Amazon Managed Service for Apache Flink
- **Runtime**: Flink 1.18
- **Functions**:
  - Parse and validate JSON records
  - Transform data structures
  - Calculate aggregations
  - Detect anomalies
  - Write to Timestream
- **Configuration**:
  - Auto-scaling enabled
  - 2 parallelism (default)
  - Checkpointing enabled
  - Snapshots enabled
  - Custom monitoring (INFO level)

**Processing Steps**:
1. Read from Kinesis stream
2. Deserialize JSON sensor data
3. Apply transformations
4. Calculate windowed aggregations
5. Write to Timestream

### 3. Storage Layer

#### Amazon Timestream
- **Type**: Time-series database
- **Schema**:
  - **Dimensions**: sensor_id, machine_id, production_line, status
  - **Measures**: temperature, pressure, vibration, power, items_produced, quality_score, downtime
- **Retention**:
  - Memory store: 24 hours (fast queries)
  - Magnetic store: 90 days (cost-effective long-term)
- **Features**:
  - Automatic data tiering
  - Built-in time-series analytics
  - Serverless and auto-scaling
  - KMS encryption

### 4. Visualization Layer

#### Grafana
- **Purpose**: Real-time dashboards and alerting
- **Data Source**: Amazon Timestream plugin
- **Dashboards**:
  - Temperature trends by machine
  - Production metrics by line
  - Quality scores
  - Power consumption
  - Vibration monitoring
  - Downtime tracking
- **Features**:
  - Auto-refresh (5 seconds)
  - Custom time ranges
  - Alert rules
  - Multiple visualizations

### 5. Security & IAM

#### Least Privilege Access
- **Flink Execution Role**:
  - Read from Kinesis stream
  - Write to Timestream
  - CloudWatch logs and metrics
- **Producer Role**:
  - Write to Kinesis stream
  - CloudWatch metrics
- **Grafana Role**:
  - Read-only Timestream access
  - List databases and tables

#### Encryption
- **At Rest**:
  - Kinesis: KMS encryption
  - Timestream: KMS encryption
  - S3: AES-256
- **In Transit**:
  - TLS 1.2+ for all connections
  - HTTPS endpoints

### 6. Monitoring & Observability

#### CloudWatch Dashboards
- Kinesis ingestion metrics
- Flink application health
- Timestream write metrics
- System performance

#### CloudWatch Alarms
- **Kinesis**:
  - High iterator age (>1 minute)
  - Write throttling
  - Read throttling
- **Flink**:
  - Application downtime
  - Checkpoint failures
  - High CPU utilization (>80%)

#### Logs
- Flink application logs (/aws/kinesis-analytics/*)
- CloudWatch log retention: 7 days

## Data Flow

### 1. Ingestion Flow
```
Sensor → Producer → Kinesis Stream
         (JSON)      (Encrypted)
```

### 2. Processing Flow
```
Kinesis → Flink → Timestream
          │
          ├─ Parse JSON
          ├─ Transform
          ├─ Aggregate
          └─ Enrich
```

### 3. Query Flow
```
Timestream → Grafana → User
             (Plugin)   (Dashboard)
```

## Scalability

### Horizontal Scaling
- **Kinesis**: Add more shards
- **Flink**: Increase parallelism
- **Timestream**: Auto-scales

### Vertical Scaling
- **Flink**: Increase KPU (Kinesis Processing Units)

### Performance Targets
- Ingestion: 10,000 records/sec
- Processing latency: <1 second (p99)
- Query latency: <100ms (p95)
- Data retention: 90 days

## Cost Optimization

1. **Kinesis**: Right-size shard count based on throughput
2. **Flink**: Use auto-scaling to optimize KPU usage
3. **Timestream**: Data automatically tiered to magnetic store
4. **CloudWatch**: 7-day log retention
5. **S3**: Lifecycle policy for rejected data (30 days)

## High Availability

- **Kinesis**: Multi-AZ by default
- **Flink**: Automatic failure recovery with checkpoints
- **Timestream**: Multi-AZ replication
- **Snapshots**: Enabled for Flink state

## Disaster Recovery

- **Kinesis**: 24-hour retention allows replay
- **Flink**: Snapshots for point-in-time recovery
- **Timestream**: Continuous backup to magnetic store
- **Infrastructure**: Terraform state for reproducibility
