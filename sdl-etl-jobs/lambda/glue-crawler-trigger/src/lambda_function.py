import os
import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    glue_client = boto3.client('glue')

    pOrg = os.getenv('pOrg')
    pDomain = os.getenv('pDomain')
    pEnvironment = os.getenv('pEnvironment')

    if not pOrg or not pDomain or not pEnvironment:
        error_message = "Missing one or more required environment variables: pOrg, pDomain, pEnvironment"
        logger.error(error_message)
        return {
            'statusCode': 400,
            'body': json.dumps(error_message)
        }

    crawler_name = f"{pOrg}-{pDomain}-{pEnvironment}-GlueCrawler"

    try:
        # Check Crawler status
        response = glue_client.get_crawler(Name=crawler_name)
        crawler_state = response['Crawler']['State']
        
        if crawler_state == 'READY':
            # Start Glue Crawler
            glue_client.start_crawler(Name=crawler_name)
            logger.info(f"Started crawler: {crawler_name}")
            
            return {
                'statusCode': 200,
                'body': json.dumps(f"Crawler {crawler_name} started successfully")
            }
        else:
            logger.warning(f"Crawler {crawler_name} is currently {crawler_state} and cannot be started.")
            return {
                'statusCode': 400,
                'body': json.dumps(f"Crawler {crawler_name} is currently {crawler_state} and cannot be started.")
            }
    
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error starting Glue crawler: {str(e)}")
        }
