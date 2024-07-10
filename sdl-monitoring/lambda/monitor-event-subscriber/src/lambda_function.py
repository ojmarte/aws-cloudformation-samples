import json
import boto3
import os
import requests
from datetime import datetime

s3 = boto3.client('s3')

def lambda_handler(event, context):
    teams_webhook_url = os.environ['TEAMS_WEBHOOK_URL']
    s3_bucket = os.environ['MONITOR_S3']
    monitor_db = os.environ['MONITOR_DATABASE']
    monitor_table = os.environ['MONITOR_TABLE']
    
    # Process each SNS message
    for record in event['Records']:
        sns_message = record['Sns']['Message']
        message_json = json.loads(sns_message)
        detail = message_json['detail']
        
        state = detail.get('state')
        job_name = detail.get('jobName', 'N/A')
        crawler_name = detail.get('crawlerName', 'N/A')
        timestamp = detail.get('timestamp', str(datetime.now()))
        
        # Create a notification message
        if job_name != 'N/A':
            notification_message = f"Glue Job '{job_name}' has reached state: {state}"
        elif crawler_name != 'N/A':
            notification_message = f"Glue Crawler '{crawler_name}' has reached state: {state}"
        else:
            notification_message = f"Unknown state change detected: {state}"
        
        # Send the message to Microsoft Teams
        payload = {
            "text": notification_message
        }
        
        response = requests.post(teams_webhook_url, json=payload)
        
        # Log the message to S3
        log_entry = {
            "state": state,
            "job_name": job_name,
            "crawler_name": crawler_name,
            "timestamp": timestamp,
            "message": notification_message
        }
        
        s3.put_object(
            Bucket=s3_bucket,
            Key=f"{monitor_db}/{monitor_table}/{timestamp}.json",
            Body=json.dumps(log_entry)
        )
    
    return {
        'statusCode': 200,
        'body': json.dumps('Notification sent to Microsoft Teams and log saved to S3')
    }
