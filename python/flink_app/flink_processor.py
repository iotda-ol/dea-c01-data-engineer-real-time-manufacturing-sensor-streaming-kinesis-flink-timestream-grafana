#!/usr/bin/env python3
"""
Apache Flink Application for Manufacturing Sensor Data Processing
Processes streaming data from Kinesis and writes to Timestream
"""

import json
import logging
from datetime import datetime
from typing import Dict, List
import boto3
from botocore.exceptions import ClientError

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class SensorDataProcessor:
    """
    Processes sensor data and performs aggregations
    Note: This is a Python reference implementation. For production with
    Amazon Managed Service for Apache Flink, use Java/Scala or PyFlink
    """
    
    def __init__(self, timestream_db: str, timestream_table: str, region: str = 'us-east-1'):
        self.timestream_db = timestream_db
        self.timestream_table = timestream_table
        self.timestream_write = boto3.client('timestream-write', region_name=region)
        self.buffer = []
        self.buffer_size = 100
        
    def parse_sensor_record(self, record_data: str) -> Dict:
        """Parse JSON sensor record"""
        try:
            return json.loads(record_data)
        except json.JSONDecodeError as e:
            logger.error(f"Error parsing JSON: {e}")
            return None
    
    def transform_to_timestream_record(self, sensor_data: Dict) -> List[Dict]:
        """Transform sensor data to Timestream records"""
        if not sensor_data:
            return []
        
        current_time = str(int(datetime.utcnow().timestamp() * 1000))
        
        # Common dimensions
        dimensions = [
            {'Name': 'sensor_id', 'Value': sensor_data['sensor_id']},
            {'Name': 'machine_id', 'Value': sensor_data['machine_id']},
            {'Name': 'production_line', 'Value': sensor_data['production_line']},
            {'Name': 'status', 'Value': sensor_data['status']}
        ]
        
        # Create multiple measure records
        records = []
        
        # Temperature measurement
        records.append({
            'Dimensions': dimensions,
            'MeasureName': 'temperature_celsius',
            'MeasureValue': str(sensor_data['measurements']['temperature_celsius']),
            'MeasureValueType': 'DOUBLE',
            'Time': current_time
        })
        
        # Pressure measurement
        records.append({
            'Dimensions': dimensions,
            'MeasureName': 'pressure_psi',
            'MeasureValue': str(sensor_data['measurements']['pressure_psi']),
            'MeasureValueType': 'DOUBLE',
            'Time': current_time
        })
        
        # Vibration measurement
        records.append({
            'Dimensions': dimensions,
            'MeasureName': 'vibration_mms',
            'MeasureValue': str(sensor_data['measurements']['vibration_mms']),
            'MeasureValueType': 'DOUBLE',
            'Time': current_time
        })
        
        # Power measurement
        records.append({
            'Dimensions': dimensions,
            'MeasureName': 'power_kw',
            'MeasureValue': str(sensor_data['measurements']['power_kw']),
            'MeasureValueType': 'DOUBLE',
            'Time': current_time
        })
        
        # Production metrics
        records.append({
            'Dimensions': dimensions,
            'MeasureName': 'items_produced',
            'MeasureValue': str(sensor_data['production']['items_produced']),
            'MeasureValueType': 'BIGINT',
            'Time': current_time
        })
        
        records.append({
            'Dimensions': dimensions,
            'MeasureName': 'quality_score',
            'MeasureValue': str(sensor_data['production']['quality_score']),
            'MeasureValueType': 'DOUBLE',
            'Time': current_time
        })
        
        records.append({
            'Dimensions': dimensions,
            'MeasureName': 'downtime_minutes',
            'MeasureValue': str(sensor_data['production']['downtime_minutes']),
            'MeasureValueType': 'BIGINT',
            'Time': current_time
        })
        
        return records
    
    def write_to_timestream(self, records: List[Dict]) -> bool:
        """Write records to Amazon Timestream"""
        if not records:
            return False
        
        try:
            result = self.timestream_write.write_records(
                DatabaseName=self.timestream_db,
                TableName=self.timestream_table,
                Records=records
            )
            logger.info(f"Successfully wrote {len(records)} records to Timestream")
            return True
        except ClientError as e:
            logger.error(f"Error writing to Timestream: {e}")
            return False
    
    def process_record(self, record_data: str):
        """Process a single record"""
        sensor_data = self.parse_sensor_record(record_data)
        if sensor_data:
            timestream_records = self.transform_to_timestream_record(sensor_data)
            self.buffer.extend(timestream_records)
            
            # Flush buffer if it reaches the threshold
            if len(self.buffer) >= self.buffer_size:
                self.flush_buffer()
    
    def flush_buffer(self):
        """Flush buffered records to Timestream"""
        if self.buffer:
            logger.info(f"Flushing {len(self.buffer)} records to Timestream")
            self.write_to_timestream(self.buffer)
            self.buffer = []
    
    def calculate_aggregations(self, records: List[Dict]) -> Dict:
        """
        Calculate aggregations for manufacturing analytics
        This is a simplified version - in production Flink, use windowing functions
        """
        if not records:
            return {}
        
        # Group by production line
        line_metrics = {}
        for record in records:
            line = record.get('production_line')
            if line not in line_metrics:
                line_metrics[line] = {
                    'total_items': 0,
                    'avg_quality': 0,
                    'total_downtime': 0,
                    'count': 0
                }
            
            line_metrics[line]['total_items'] += record.get('production', {}).get('items_produced', 0)
            line_metrics[line]['avg_quality'] += record.get('production', {}).get('quality_score', 0)
            line_metrics[line]['total_downtime'] += record.get('production', {}).get('downtime_minutes', 0)
            line_metrics[line]['count'] += 1
        
        # Calculate averages
        for line, metrics in line_metrics.items():
            if metrics['count'] > 0:
                metrics['avg_quality'] = metrics['avg_quality'] / metrics['count']
        
        return line_metrics


class KinesisConsumer:
    """
    Simple Kinesis consumer for testing
    Note: For production, use Amazon Managed Service for Apache Flink
    """
    
    def __init__(self, stream_name: str, processor: SensorDataProcessor, region: str = 'us-east-1'):
        self.stream_name = stream_name
        self.processor = processor
        self.kinesis_client = boto3.client('kinesis', region_name=region)
        
    def process_shard(self, shard_id: str):
        """Process records from a single shard"""
        # Get shard iterator
        shard_iterator = self.kinesis_client.get_shard_iterator(
            StreamName=self.stream_name,
            ShardId=shard_id,
            ShardIteratorType='LATEST'
        )['ShardIterator']
        
        logger.info(f"Processing shard: {shard_id}")
        
        while True:
            try:
                response = self.kinesis_client.get_records(
                    ShardIterator=shard_iterator,
                    Limit=100
                )
                
                records = response['Records']
                if records:
                    logger.info(f"Processing {len(records)} records from shard {shard_id}")
                    for record in records:
                        data = record['Data'].decode('utf-8')
                        self.processor.process_record(data)
                
                # Update shard iterator
                shard_iterator = response['NextShardIterator']
                
                if not shard_iterator:
                    logger.info(f"Shard {shard_id} closed")
                    break
                    
            except Exception as e:
                logger.error(f"Error processing shard {shard_id}: {e}")
                break


def main():
    """
    Main entry point
    This is a reference implementation for testing.
    For production, deploy as Amazon Managed Service for Apache Flink application
    """
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Flink Processor for Manufacturing Sensor Data'
    )
    parser.add_argument('--stream-name', required=True, help='Kinesis stream name')
    parser.add_argument('--timestream-db', required=True, help='Timestream database name')
    parser.add_argument('--timestream-table', required=True, help='Timestream table name')
    parser.add_argument('--region', default='us-east-1', help='AWS region')
    
    args = parser.parse_args()
    
    processor = SensorDataProcessor(
        args.timestream_db,
        args.timestream_table,
        args.region
    )
    
    consumer = KinesisConsumer(args.stream_name, processor, args.region)
    
    # Get list of shards
    kinesis_client = boto3.client('kinesis', region_name=args.region)
    response = kinesis_client.describe_stream(StreamName=args.stream_name)
    shards = response['StreamDescription']['Shards']
    
    logger.info(f"Found {len(shards)} shards in stream {args.stream_name}")
    
    # Process first shard (in production, process all shards in parallel)
    if shards:
        consumer.process_shard(shards[0]['ShardId'])


if __name__ == '__main__':
    main()
