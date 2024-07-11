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
    job_name = f"{pOrg}-{pDomain}-{pEnvironment}-GlueJob"

    try:
        # Start Glue Crawler
        glue_client.start_crawler(Name=crawler_name)
        logger.info(f"Started crawler: {crawler_name}")
        
        # Wait for Crawler to complete
        waiter = glue_client.get_waiter('crawler_ready')
        waiter.wait(Name=crawler_name)
        logger.info(f"Crawler {crawler_name} completed")
        
        # Start Glue Job
        response = glue_client.start_job_run(JobName=job_name)
        logger.info(f"Started Glue job: {job_name}, response: {response}")
        
        return {
            'statusCode': 200,
            'body': json.dumps('Glue job started successfully')
        }
    
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error starting Glue job: {str(e)}")
        }
