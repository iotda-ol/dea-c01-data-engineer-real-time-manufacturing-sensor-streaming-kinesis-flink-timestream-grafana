# Real-Time Manufacturing Analytics Platform

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-1.0+-purple.svg)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Kinesis%20%7C%20Flink%20%7C%20Timestream-orange.svg)](https://aws.amazon.com/)
[![Python](https://img.shields.io/badge/Python-3.8+-blue.svg)](https://www.python.org/)

## Overview

This repository implements a **production-ready, real-time analytics platform** for manufacturing sensor data using AWS services. The platform demonstrates best practices for the **AWS Certified Data Engineer - Associate (DEA-C01)** certification.

### Key Features

- 🚀 **Real-Time Streaming**: Sub-second latency data ingestion with Amazon Kinesis Data Streams
- 🔄 **Stream Processing**: Transformation and aggregation using Amazon Managed Service for Apache Flink
- 📊 **Time-Series Storage**: Purpose-built storage with Amazon Timestream
- 📈 **Live Visualization**: Real-time dashboards with Grafana
- 🔒 **Security First**: IAM least privilege, KMS encryption, comprehensive monitoring
- 🏗️ **Infrastructure as Code**: Complete Terraform automation
- 📉 **Cost Optimized**: Auto-scaling, data tiering, right-sizing

### Architecture

```
Sensors → Python Producer → Kinesis Streams → Flink Processing → Timestream → Grafana
                                    ↓
                              CloudWatch Monitoring
```

### What's Included

- **Terraform Infrastructure**: Modular, reusable AWS infrastructure
- **Python Data Producer**: Realistic sensor data simulation
- **Flink Application**: Reference implementation for stream processing
- **Grafana Dashboards**: Pre-built visualization templates
- **Comprehensive Documentation**: Architecture, deployment, and best practices
- **Security Configuration**: IAM roles, KMS encryption, least privilege access
- **Monitoring & Alerting**: CloudWatch dashboards and alarms

## Quick Start

### Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.0
- AWS CLI >= 2.0
- Python 3.8+

### 1. Clone and Initialize

```bash
git clone https://github.com/iotda-ol/dea-c01-data-engineer-real-time-manufacturing-sensor-streaming-kinesis-flink-timestream-grafana.git
cd dea-c01-data-engineer-real-time-manufacturing-sensor-streaming-kinesis-flink-timestream-grafana
```

### 2. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform apply
```

### 3. Start Data Producer

```bash
cd ../python/producer
pip install -r requirements.txt
python sensor_data_producer.py \
  --stream-name manufacturing-analytics-sensor-data-dev \
  --region us-east-1
```

### 4. Set Up Grafana

See [grafana/README.md](grafana/README.md) for detailed setup instructions.

## Project Structure

```
.
├── terraform/                 # Infrastructure as Code
│   ├── main.tf               # Root Terraform configuration
│   ├── variables.tf          # Input variables
│   ├── outputs.tf            # Output values
│   └── modules/              # Reusable Terraform modules
│       ├── kinesis/          # Kinesis Data Streams
│       ├── flink/            # Managed Flink application
│       ├── timestream/       # Timestream database and table
│       ├── iam/              # IAM roles and policies
│       └── monitoring/       # CloudWatch alarms and dashboards
├── python/                   # Python applications
│   ├── producer/             # Sensor data generator
│   └── flink_app/           # Flink processing logic (reference)
├── grafana/                  # Grafana configuration
│   ├── dashboards/          # Dashboard JSON definitions
│   ├── datasource.yaml      # Timestream data source config
│   └── README.md            # Grafana setup guide
├── docs/                     # Documentation
│   ├── ARCHITECTURE.md      # System architecture details
│   ├── DEPLOYMENT.md        # Deployment guide
│   └── DEA-C01-BEST-PRACTICES.md  # AWS best practices
└── README.md                # This file
```

## Components

### Data Ingestion
- **Amazon Kinesis Data Streams**: Scalable data ingestion with 2 shards, KMS encryption, 24h retention

### Stream Processing
- **Amazon Managed Service for Apache Flink**: Real-time processing with auto-scaling, checkpointing, and monitoring

### Storage
- **Amazon Timestream**: Time-series database with automatic tiering (24h memory, 90d magnetic storage)

### Visualization
- **Grafana**: Real-time dashboards with 6 pre-built panels for manufacturing metrics

### Security
- **IAM Roles**: Least privilege access for Flink, Producer, and Grafana
- **KMS Encryption**: At-rest encryption for Kinesis and Timestream
- **TLS/HTTPS**: In-transit encryption for all communications

### Monitoring
- **CloudWatch**: 6+ alarms for proactive monitoring (iterator age, throttling, CPU, checkpoints)
- **Custom Dashboard**: Pre-configured metrics for all components
- **SNS Notifications**: Email alerts for critical issues

## Metrics Tracked

- **Temperature**: °C by machine
- **Pressure**: PSI by sensor
- **Vibration**: mm/s for predictive maintenance
- **Power Consumption**: kW by production line
- **Production Count**: Items produced per line
- **Quality Score**: Percentage by machine
- **Downtime**: Minutes of inactive time

## AWS Services Used

| Service | Purpose |
|---------|---------|
| Amazon Kinesis Data Streams | Real-time data ingestion |
| Amazon Managed Service for Apache Flink | Stream processing and transformations |
| Amazon Timestream | Time-series data storage |
| AWS IAM | Access control and security |
| AWS KMS | Encryption key management |
| Amazon S3 | Application artifacts and rejected data |
| Amazon CloudWatch | Monitoring, logging, and alerting |
| Amazon SNS | Alarm notifications |

## Cost Estimation

**Development Environment** (us-east-1, per month):
- Kinesis Data Streams (2 shards): ~$30
- Managed Flink (2 KPU): ~$150
- Timestream (1 GB storage): ~$1-5
- CloudWatch: ~$5-10
- S3: <$1
- **Total**: ~$186-196/month

Adjust resources for production workloads.

## Documentation

- 📖 [Architecture Overview](docs/ARCHITECTURE.md) - System design and data flow
- 🚀 [Deployment Guide](docs/DEPLOYMENT.md) - Step-by-step deployment instructions
- ✅ [DEA-C01 Best Practices](docs/DEA-C01-BEST-PRACTICES.md) - AWS certification best practices
- 📊 [Grafana Setup](grafana/README.md) - Dashboard configuration guide
- 🔧 [Flink Application](python/flink_app/README.md) - Processing logic details

## AWS DEA-C01 Exam Topics Covered

This implementation demonstrates key concepts for the AWS Certified Data Engineer - Associate exam:

- ✅ **Domain 1**: Data Ingestion and Transformation (streaming with Kinesis and Flink)
- ✅ **Domain 2**: Data Store Management (Timestream for time-series data)
- ✅ **Domain 3**: Data Operations and Support (monitoring, IaC, automation)
- ✅ **Domain 4**: Data Security and Governance (IAM, KMS, encryption, least privilege)

See [DEA-C01-BEST-PRACTICES.md](docs/DEA-C01-BEST-PRACTICES.md) for detailed explanations.

## Best Practices Implemented

### Streaming
- Partition key strategy for even distribution
- Backpressure management
- Exactly-once processing semantics
- Late data handling with watermarks
- Stateful processing with checkpoints

### Security
- Least privilege IAM policies
- KMS encryption at rest
- TLS 1.2+ in transit
- No hardcoded credentials
- Resource tagging for governance

### Reliability
- Multi-AZ deployment
- Automatic failover
- 24h data retention for replay
- Snapshot-based recovery
- Comprehensive monitoring

### Cost Optimization
- Auto-scaling enabled
- Data tiering (hot/cold storage)
- Right-sized resources
- 7-day log retention
- Lifecycle policies

## Customization

### Adjust Kinesis Throughput
```hcl
# terraform/variables.tf
variable "kinesis_shard_count" {
  default = 4  # Increase for higher throughput
}
```

### Modify Retention Periods
```hcl
# terraform/variables.tf
variable "timestream_memory_retention_hours" {
  default = 48  # Extend for longer hot data access
}
```

### Add Custom Metrics
Edit `python/producer/sensor_data_producer.py` to add new sensor measurements.

## Troubleshooting

See [DEPLOYMENT.md](docs/DEPLOYMENT.md#troubleshooting) for common issues and solutions.

## Contributing

This is a reference implementation. Feel free to fork and customize for your use case.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Resources

- [AWS Kinesis Documentation](https://docs.aws.amazon.com/kinesis/)
- [Amazon Managed Flink Documentation](https://docs.aws.amazon.com/kinesisanalytics/)
- [Amazon Timestream Documentation](https://docs.aws.amazon.com/timestream/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS DEA-C01 Exam Guide](https://aws.amazon.com/certification/certified-data-engineer-associate/)
- [Grafana Timestream Plugin](https://grafana.com/grafana/plugins/grafana-timestream-datasource/)

## Support

For issues and questions:
1. Check the [documentation](docs/)
2. Review [troubleshooting guide](docs/DEPLOYMENT.md#troubleshooting)
3. Open an issue in this repository

## Acknowledgments

This implementation follows AWS Well-Architected Framework principles and DEA-C01 exam best practices.
