#!/bin/bash

# Variables
STACK_NAME="sdl-foundation-stack"
TEMPLATE_FILE="../sdl-foundation/template.yaml"
PARAMETERS_FILE="../sdl-foundation/parameters.json"
CHANGE_SET_NAME="$STACK_NAME-change-set"

LAMBDA_GLUE_CRAWLER_TRIGGER_SRC="../sdl-etl-jobs/lambda/glue-crawler-trigger/src/lambda_function.py"
LAMBDA_GLUE_JOB_TRIGGER_SRC="../sdl-etl-jobs/lambda/glue-job-trigger/src/lambda_function.py"
LAMBDA_MONITOR_EVENT_SRC="../sdl-monitoring/lambda/monitor-event-subscriber/src/lambda_function.py"
GLUE_JOB_SCRIPT_SRC="../sdl-etl-jobs/glue/script/src/glue_job.py"

LAMBDA_GLUE_CRAWLER_TRIGGER_ZIP="../sdl-etl-jobs/lambda/glue-crawler-trigger/src/lambda_function.zip"
LAMBDA_GLUE_JOB_TRIGGER_ZIP="../sdl-etl-jobs/lambda/glue-job-trigger/src/lambda_function.zip"
LAMBDA_MONITOR_EVENT_ZIP="../sdl-monitoring/lambda/monitor-event-subscriber/src/lambda_function.zip"
LAMBDA_MONITOR_LAYER_ZIP="../sdl-monitoring/lambda/monitor-event-subscriber/src/layer/layer.zip"

# Zip the Lambda function and Glue script
zip -j $LAMBDA_GLUE_CRAWLER_TRIGGER_ZIP $LAMBDA_GLUE_CRAWLER_TRIGGER_SRC
zip -j $LAMBDA_GLUE_JOB_TRIGGER_ZIP $LAMBDA_GLUE_JOB_TRIGGER_SRC
zip -j $LAMBDA_MONITOR_EVENT_ZIP $LAMBDA_MONITOR_EVENT_SRC

# Get the S3 bucket name from the CloudFormation stack outputs
BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='oLambdaGlueS3BucketName'].OutputValue" --output text)

# Check if the bucket name is retrieved
if [ -z "$BUCKET_NAME" ]; then
    echo "Failed to retrieve S3 bucket name from stack outputs."
    exit 1
fi

echo "S3 bucket: $BUCKET_NAME"

# Delete all objects from the S3 bucket
aws s3 rm s3://$BUCKET_NAME --recursive

# Upload the Lambda function and Glue script to the S3 bucket
aws s3 cp $LAMBDA_GLUE_CRAWLER_TRIGGER_ZIP s3://$BUCKET_NAME/lambda/glue-crawler-trigger/src/lambda_function.zip
aws s3 cp $LAMBDA_GLUE_JOB_TRIGGER_ZIP s3://$BUCKET_NAME/lambda/glue-job-trigger/src/lambda_function.zip
aws s3 cp $LAMBDA_MONITOR_EVENT_ZIP s3://$BUCKET_NAME/lambda/monitor-event-subscriber/src/lambda_function.zip
aws s3 cp $LAMBDA_MONITOR_LAYER_ZIP s3://$BUCKET_NAME/layer/monitor-event-subscriber/src/layer.zip
aws s3 cp $GLUE_JOB_SCRIPT_SRC s3://$BUCKET_NAME/glue/script/src/glue_job.py

echo "Lambda functions and Glue script uploaded to S3 bucket."

rm -f $LAMBDA_GLUE_CRAWLER_TRIGGER_ZIP
rm -f $LAMBDA_GLUE_JOB_TRIGGER_ZIP
rm -f $LAMBDA_MONITOR_EVENT_ZIP
# rm -f $LAMBDA_MONITOR_LAYER_ZIP

# Create a change set
aws cloudformation create-change-set --stack-name $STACK_NAME --template-body file://$TEMPLATE_FILE --parameters file://$PARAMETERS_FILE --capabilities CAPABILITY_NAMED_IAM --change-set-name $CHANGE_SET_NAME

# Wait for the change set to be created
aws cloudformation wait change-set-create-complete --change-set-name $CHANGE_SET_NAME --stack-name $STACK_NAME

# Describe the change set to check for changes
CHANGE_SET_STATUS=$(aws cloudformation describe-change-set --change-set-name $CHANGE_SET_NAME --stack-name $STACK_NAME --query 'Status' --output text)
EXECUTION_STATUS=$(aws cloudformation describe-change-set --change-set-name $CHANGE_SET_NAME --stack-name $STACK_NAME --query 'ExecutionStatus' --output text)

# Check if the change set has changes
if [[ "$CHANGE_SET_STATUS" == "CREATE_COMPLETE" && "$EXECUTION_STATUS" == "AVAILABLE" ]]; then
    echo "Changes detected. Executing update..."
    aws cloudformation execute-change-set --change-set-name $CHANGE_SET_NAME --stack-name $STACK_NAME
else
    echo "No changes detected. Deleting change set..."
    aws cloudformation delete-change-set --change-set-name $CHANGE_SET_NAME --stack-name $STACK_NAME
fi
