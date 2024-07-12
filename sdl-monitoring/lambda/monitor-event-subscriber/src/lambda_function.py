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
    
    # Function to send a message to Microsoft Teams
    def send_teams_message(title, message, status_emoji):
        payload = {
            "title": title,
            "text": f"{status_emoji} **{title}**\n\n{message}"
        }
        try:
            response = requests.post(teams_webhook_url, json=payload)
            if response.status_code != 200:
                alert_message = {
                    "text": f"Error {response.status_code}: Failed to send notification. Event details: {json.dumps(event)}"
                }
                requests.post(teams_webhook_url, json=alert_message)
        except requests.exceptions.RequestException as e:
            alert_message = {
                "text": f"Exception: {str(e)}. Event details: {json.dumps(event)}"
            }
            requests.post(teams_webhook_url, json=alert_message)
            
    
    # Check if the event contains 'Records'
    if 'Records' not in event:
        error_message = 'Invalid event format: Missing "Records" key'
        send_teams_message("Error", error_message, "❌")
        return {
            'statusCode': 400,
            'body': json.dumps(error_message)
        }
    
    # Process each SNS message
    for record in event['Records']:
        sns_message = record['Sns']['Message']
        message_json = json.loads(sns_message)
        detail = message_json['detail']

        if 'detail' not in message_json:
            error_message = 'Invalid message format: Missing "detail" key'
            send_teams_message("Error", error_message, "❌")
            continue
        
        state = detail.get('state')
        job_name = detail.get('jobName', 'N/A')
        crawler_name = detail.get('crawlerName', 'N/A')
        timestamp = detail.get('timestamp', str(datetime.now()))
        
        # Create a notification message
        if job_name != 'N/A':
            title = f"Glue Job '{job_name}' State Change"
            notification_message = f"Glue Job '{job_name}' has reached state: {state} at {timestamp}"
        elif crawler_name != 'N/A':
            title = f"Glue Crawler '{crawler_name}' State Change"
            notification_message = f"Glue Crawler '{crawler_name}' has reached state: {state} at {timestamp}"
        else:
            title = "Unknown State Change Detected"
            notification_message = f"Unknown state change detected: {state} at {timestamp}"
        
        # Determine the status emoji based on the state
        if state in ["SUCCEEDED", "Succeeded"]:
            status_emoji = "✅"
        elif state in ["FAILED", "Failed", "TIMEOUT", "STOPPED"]:
            status_emoji = "❌"
        else:
            status_emoji = "ℹ️"
        
        # Send the message to Microsoft Teams
        send_teams_message(title, notification_message, status_emoji)
        
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
            Key=f"{monitor_db}/{monitor_table}/{timestamp}-{context.aws_request_id}.json",
            Body=json.dumps(log_entry)
        )
    
    return {
        'statusCode': 200,
        'body': json.dumps('Notification sent to Microsoft Teams and log saved to S3')
    }
