import json
import logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    event_received_at = datetime.now().isoformat()
    logger.info(f'Event received at: {event_received_at}')
    logger.info(f'Received event: {json.dumps(event, indent=2)}')

    if event.get('Success'):
        logger.info("Success")
        context.callbackWaitsForEmptyEventLoop = False
        return {
            'statusCode': 200,
            'body': json.dumps('Success')
        }
    else:
        logger.info("Failure")
        context.callbackWaitsForEmptyEventLoop = False
        raise Exception("Failure from event, Success = false, I am failing!")
