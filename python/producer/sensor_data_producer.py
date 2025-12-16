#!/usr/bin/env python3
"""
Manufacturing Sensor Data Producer
Generates and streams simulated sensor data to Amazon Kinesis Data Streams
"""

import json
import time
import random
import argparse
import logging
from datetime import datetime, timezone
from typing import Dict, List
import boto3
from botocore.exceptions import ClientError

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class SensorDataGenerator:
    """Generates realistic manufacturing sensor data"""
    
    def __init__(self):
        self.sensor_ids = [f"SENSOR-{i:03d}" for i in range(1, 11)]
        self.machine_ids = [f"MACHINE-{i:02d}" for i in range(1, 6)]
        self.production_lines = ["LINE-A", "LINE-B", "LINE-C"]
        
    def generate_sensor_reading(self) -> Dict:
        """Generate a single sensor reading"""
        sensor_id = random.choice(self.sensor_ids)
        machine_id = random.choice(self.machine_ids)
        production_line = random.choice(self.production_lines)
        
        # Simulate realistic sensor values with some anomalies
        temperature = random.gauss(75, 5)  # Mean 75°C, std dev 5
        pressure = random.gauss(100, 10)    # Mean 100 PSI, std dev 10
        vibration = random.gauss(0.5, 0.1)  # Mean 0.5 mm/s, std dev 0.1
        
        # Occasionally generate anomalies (5% chance)
        if random.random() < 0.05:
            temperature += random.uniform(10, 30)
            vibration += random.uniform(0.5, 1.5)
        
        # Power consumption correlated with production
        power_kw = random.gauss(50, 8)
        
        # Production metrics
        items_produced = random.randint(80, 120)
        quality_score = random.gauss(95, 3)  # Mean 95%, std dev 3%
        quality_score = max(0, min(100, quality_score))  # Clamp to 0-100
        
        return {
            "sensor_id": sensor_id,
            "machine_id": machine_id,
            "production_line": production_line,
            "timestamp": datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z'),
            "measurements": {
                "temperature_celsius": round(temperature, 2),
                "pressure_psi": round(pressure, 2),
                "vibration_mms": round(vibration, 3),
                "power_kw": round(power_kw, 2)
            },
            "production": {
                "items_produced": items_produced,
                "quality_score": round(quality_score, 2),
                "downtime_minutes": random.randint(0, 5)
            },
            "status": "OPERATIONAL" if temperature < 100 else "WARNING"
        }


class KinesisProducer:
    """Streams sensor data to Amazon Kinesis Data Streams"""
    
    def __init__(self, stream_name: str, region: str = 'us-east-1'):
        self.stream_name = stream_name
        self.kinesis_client = boto3.client('kinesis', region_name=region)
        self.generator = SensorDataGenerator()
        
    def send_record(self, data: Dict) -> bool:
        """Send a single record to Kinesis"""
        try:
            response = self.kinesis_client.put_record(
                StreamName=self.stream_name,
                Data=json.dumps(data),
                PartitionKey=data['sensor_id']
            )
            logger.debug(f"Sent record: {data['sensor_id']} - Shard: {response['ShardId']}")
            return True
        except ClientError as e:
            logger.error(f"Error sending record to Kinesis: {e}")
            return False
    
    def send_batch(self, batch_size: int = 10) -> int:
        """Send a batch of records to Kinesis"""
        records = []
        for _ in range(batch_size):
            data = self.generator.generate_sensor_reading()
            records.append({
                'Data': json.dumps(data),
                'PartitionKey': data['sensor_id']
            })
        
        try:
            response = self.kinesis_client.put_records(
                StreamName=self.stream_name,
                Records=records
            )
            
            failed_count = response['FailedRecordCount']
            success_count = batch_size - failed_count
            
            if failed_count > 0:
                logger.warning(f"Failed to send {failed_count} out of {batch_size} records")
            
            logger.info(f"Successfully sent {success_count} records to {self.stream_name}")
            return success_count
        except ClientError as e:
            logger.error(f"Error sending batch to Kinesis: {e}")
            return 0
    
    def run_continuous(self, interval: float = 1.0, batch_size: int = 10):
        """Run continuous data generation"""
        logger.info(f"Starting continuous data generation to stream: {self.stream_name}")
        logger.info(f"Interval: {interval}s, Batch size: {batch_size}")
        
        records_sent = 0
        try:
            while True:
                sent = self.send_batch(batch_size)
                records_sent += sent
                logger.info(f"Total records sent: {records_sent}")
                time.sleep(interval)
        except KeyboardInterrupt:
            logger.info(f"\nStopping producer. Total records sent: {records_sent}")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description='Manufacturing Sensor Data Producer for Kinesis'
    )
    parser.add_argument(
        '--stream-name',
        required=True,
        help='Name of the Kinesis Data Stream'
    )
    parser.add_argument(
        '--region',
        default='us-east-1',
        help='AWS region (default: us-east-1)'
    )
    parser.add_argument(
        '--interval',
        type=float,
        default=1.0,
        help='Interval between batches in seconds (default: 1.0)'
    )
    parser.add_argument(
        '--batch-size',
        type=int,
        default=10,
        help='Number of records per batch (default: 10)'
    )
    parser.add_argument(
        '--debug',
        action='store_true',
        help='Enable debug logging'
    )
    
    args = parser.parse_args()
    
    if args.debug:
        logger.setLevel(logging.DEBUG)
    
    producer = KinesisProducer(args.stream_name, args.region)
    producer.run_continuous(args.interval, args.batch_size)


if __name__ == '__main__':
    main()
