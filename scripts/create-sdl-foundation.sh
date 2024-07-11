#!/bin/bash

# Variables
STACK_NAME="sdl-foundation-stack"
TEMPLATE_FILE="../sdl-foundation/template.yaml"
PARAMETERS_FILE="../sdl-foundation/parameters.json"

LAMBDA_GLUE_TRIGGER_FUNCTION_SRC="../sdl-etl-jobs/lambda/glue-trigger-function/src/lambda_function.py"
LAMBDA_MONITOR_EVENT_SRC="../sdl-monitoring/lambda/monitor-event-subscriber/src/lambda_function.py"
GLUE_JOB_SCRIPT_SRC="../sdl-etl-jobs/glue/script/src/glue_job.py"

LAMBDA_GLUE_TRIGGER_FUNCTION_ZIP="../sdl-etl-jobs/lambda/glue-trigger-function/src/lambda_function.zip"
LAMBDA_MONITOR_EVENT_ZIP="../sdl-monitoring/lambda/monitor-event-subscriber/src/lambda_function.zip"
GLUE_JOB_SCRIPT_ZIP="../sdl-etl-jobs/glue/script/src/glue_job.zip"
# LAMBDA_MONITOR_LAYER_ZIP="../sdl-monitoring/lambda/monitor-event-subscriber/src/layer/layer.zip"

# Zip the Lambda function and Glue script
zip -j $LAMBDA_GLUE_TRIGGER_FUNCTION_ZIP $LAMBDA_GLUE_TRIGGER_FUNCTION_SRC
zip -j $LAMBDA_MONITOR_EVENT_ZIP $LAMBDA_MONITOR_EVENT_SRC
zip -j $GLUE_JOB_SCRIPT_ZIP $GLUE_JOB_SCRIPT_SRC

# Create the CloudFormation stack to create the S3 bucket
aws cloudformation create-stack --stack-name $STACK_NAME --template-body file://$TEMPLATE_FILE --parameters file://$PARAMETERS_FILE --capabilities CAPABILITY_NAMED_IAM

# Wait for the stack to be created
aws cloudformation wait stack-create-complete --stack-name $STACK_NAME

# Get the S3 bucket name from the CloudFormation stack outputs
BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='oLambdaGlueS3BucketName'].OutputValue" --output text)

# Check if the bucket name is retrieved
if [ -z "$BUCKET_NAME" ]; then
    echo "Failed to retrieve S3 bucket name from stack outputs."
    exit 1
fi

echo "S3 bucket created: $BUCKET_NAME"

# Upload the Lambda function and Glue script to the S3 bucket
aws s3 cp $LAMBDA_GLUE_TRIGGER_FUNCTION_ZIP s3://$BUCKET_NAME/lambda/glue-trigger-function/src/lambda_function.zip
aws s3 cp $LAMBDA_MONITOR_EVENT_ZIP s3://$BUCKET_NAME/lambda/monitor-event-subscriber/src/lambda_function.zip
aws s3 cp $GLUE_JOB_SCRIPT_ZIP s3://$BUCKET_NAME/glue/script/src/glue_job.zip
# aws s3 cp $LAMBDA_MONITOR_LAYER_ZIP s3://$BUCKET_NAME/lambda/monitor-event-subscriber/src/layer/layer.zip

echo "Lambda functions and Glue script uploaded to S3 bucket."

rm -f $LAMBDA_GLUE_TRIGGER_FUNCTION_ZIP
rm -f $LAMBDA_MONITOR_EVENT_ZIP
rm -f $GLUE_JOB_SCRIPT_ZIP
rm -f $LAMBDA_MONITOR_LAYER_ZIP
