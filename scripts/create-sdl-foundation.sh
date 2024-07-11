#!/bin/bash

# Variables
STACK_NAME="sdl-foundation-stack"
TEMPLATE_FILE="../sdl-foundation/template.yaml"
PARAMETERS_FILE="../sdl-foundation/parameters.json"

LAMBDA_GLUE_CRAWLER_TRIGGER_SRC="../sdl-etl-jobs/lambda/glue-crawler-trigger/src/lambda_function.py"
LAMBDA_GLUE_JOB_TRIGGER_SRC="../sdl-etl-jobs/lambda/glue-job-trigger/src/lambda_function.py"
LAMBDA_MONITOR_EVENT_SRC="../sdl-monitoring/lambda/monitor-event-subscriber/src/lambda_function.py"
GLUE_JOB_SCRIPT_SRC="../sdl-etl-jobs/glue/script/src/glue_job.py"

LAMBDA_GLUE_CRAWLER_TRIGGER_ZIP="../sdl-etl-jobs/lambda/glue-crawler-trigger/src/lambda_function.zip"
LAMBDA_GLUE_JOB_TRIGGER_ZIP="../sdl-etl-jobs/lambda/glue-job-trigger/src/lambda_function.zip"
LAMBDA_MONITOR_EVENT_ZIP="../sdl-monitoring/lambda/monitor-event-subscriber/src/lambda_function.zip"
# LAMBDA_MONITOR_LAYER_ZIP="../sdl-monitoring/lambda/monitor-event-subscriber/src/layer/layer.zip"

UPLOAD_TO_AWS=true

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --no-upload) UPLOAD_TO_AWS=false ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Zip the Lambda function and Glue script
zip -j $LAMBDA_GLUE_CRAWLER_TRIGGER_ZIP $LAMBDA_GLUE_CRAWLER_TRIGGER_SRC
zip -j $LAMBDA_GLUE_JOB_TRIGGER_ZIP $LAMBDA_GLUE_JOB_TRIGGER_SRC
zip -j $LAMBDA_MONITOR_EVENT_ZIP $LAMBDA_MONITOR_EVENT_SRC

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

# Conditionally upload the Lambda function and Glue script to the S3 bucket
if [ "$UPLOAD_TO_AWS" = true ]; then
    aws s3 cp $LAMBDA_GLUE_CRAWLER_TRIGGER_ZIP s3://$BUCKET_NAME/lambda/glue-crawler-trigger/src/lambda_function.zip
    aws s3 cp $LAMBDA_GLUE_JOB_TRIGGER_ZIP s3://$BUCKET_NAME/lambda/glue-job-trigger/src/lambda_function.zip
    aws s3 cp $LAMBDA_MONITOR_EVENT_ZIP s3://$BUCKET_NAME/lambda/monitor-event-subscriber/src/lambda_function.zip
    aws s3 cp $GLUE_JOB_SCRIPT_SRC s3://$BUCKET_NAME/glue/script/src/glue_job.py
    # aws s3 cp $LAMBDA_MONITOR_LAYER_ZIP s3://$BUCKET_NAME/lambda/monitor-event-subscriber/src/layer/layer.zip
    echo "Lambda functions and Glue script uploaded to S3 bucket."
else
    echo "Skipping upload to S3 bucket as per user request."
fi

rm -f $LAMBDA_GLUE_CRAWLER_TRIGGER_ZIP
rm -f $LAMBDA_GLUE_JOB_TRIGGER_ZIP
rm -f $LAMBDA_MONITOR_EVENT_ZIP
rm -f $LAMBDA_MONITOR_LAYER_ZIP
