import json
import boto3
import os

def lambda_handler(event, context):
    s3_client = boto3.client('s3')
    
    landing_bucket = os.environ['LANDING_BUCKET']
    processed_bucket = os.environ['PROCESSED_BUCKET']
    region = os.environ['REGION']
    
    # Example: List objects in the landing bucket
    response = s3_client.list_objects_v2(Bucket=landing_bucket)
    files = [item['Key'] for item in response.get('Contents', [])]
    
    # Example: Read and process each file
    for file_key in files:
        file_obj = s3_client.get_object(Bucket=landing_bucket, Key=file_key)
        file_content = file_obj['Body'].read().decode('utf-8')
        
        # Process the file content (this example simply uppercases the content)
        processed_content = file_content.upper()
        
        # Write the processed content to the processed bucket
        s3_client.put_object(
            Bucket=processed_bucket,
            Key=f'processed/{file_key}',
            Body=processed_content
        )
    
    return {
        'statusCode': 200,
        'body': json.dumps(f'Processed {len(files)} files')
    }
