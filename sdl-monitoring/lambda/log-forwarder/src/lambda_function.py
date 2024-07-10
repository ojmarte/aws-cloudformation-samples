import json
import boto3

client = boto3.client('events')

def lambda_handler(event, context):
    for record in event['records']:
        response = client.put_events(
            Entries=[
                {
                    'Source': 'aws.logs',
                    'DetailType': 'Glue Job/Crawler Log',
                    'Detail': json.dumps(record),
                    'EventBusName': 'default'
                }
            ]
        )
    return {
        'statusCode': 200,
        'body': json.dumps('Logs forwarded to EventBridge')
    }
