#!/bin/bash

# Variables
STACK_NAME="sdl-foundation-stack"
TEMPLATE_FILE="../sdl-foundation/template.yaml"
PARAMETERS_FILE="../sdl-foundation/parameters.json"
LAMBDA_ETL_TASK_SRC="../sdl-etl-jobs/lambda/etl-task/src/lambda_function.py"
LAMBDA_SUCCESS_SRC="../sdl-etl-jobs/lambda/success/src/lambda_function.py"
LAMBDA_FAIL_SRC="../sdl-etl-jobs/lambda/fail/src/lambda_function.py"
LAMBDA_MONITOR_EVENT_SRC="../sdl-monitoring/lambda/monitor-event-subscriber/src/lambda_function.py"
LAMBDA_LOG_FORWARDER_SRC="../sdl-monitoring/lambda/log-forwarder/src/lambda_function.py"
GLUE_JOB_SUCCESS_SRC="../sdl-etl-jobs/glue/glue-scripts/src/glue_job_success.py"
GLUE_JOB_FAIL_SRC="../sdl-etl-jobs/glue/glue-scripts/src/glue_job_fail.py"
LAMBDA_ETL_TASK_ZIP="../sdl-etl-jobs/lambda/etl-task/src/lambda_function.zip"
LAMBDA_SUCCESS_ZIP="../sdl-etl-jobs/lambda/success/src/lambda_function.zip"
LAMBDA_FAIL_ZIP="../sdl-etl-jobs/lambda/fail/src/lambda_function.zip"
LAMBDA_MONITOR_EVENT_ZIP="../sdl-monitoring/lambda/monitor-event-subscriber/src/lambda_function.zip"
LAMBDA_LOG_FORWARDER_ZIP="../sdl-monitoring/lambda/log-forwarder/src/lambda_function.zip"
GLUE_JOB_SUCCESS_ZIP="../sdl-etl-jobs/glue/glue-scripts/src/glue_job_success.zip"
GLUE_JOB_FAIL_ZIP="../sdl-etl-jobs/glue/glue-scripts/src/glue_job_fail.zip"
LAMBDA_MONITOR_LAYER_ZIP="../sdl-monitoring/lambda/monitor-event-subscriber/src/layer/layer.zip"

# Zip the Lambda function and Glue script
zip -j $LAMBDA_ETL_TASK_ZIP $LAMBDA_ETL_TASK_SRC
zip -j $LAMBDA_SUCCESS_ZIP $LAMBDA_SUCCESS_SRC
zip -j $LAMBDA_FAIL_ZIP $LAMBDA_FAIL_SRC
zip -j $LAMBDA_MONITOR_EVENT_ZIP $LAMBDA_MONITOR_EVENT_SRC
zip -j $GLUE_JOB_SUCCESS_ZIP $GLUE_JOB_SUCCESS_SRC
zip -j $GLUE_JOB_FAIL_ZIP $GLUE_JOB_FAIL_SRC
zip -j $LAMBDA_LOG_FORWARDER_ZIP $LAMBDA_LOG_FORWARDER_SRC

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
aws s3 cp $LAMBDA_ETL_TASK_ZIP s3://$BUCKET_NAME/lambda/etl-task/src/lambda_function.zip
aws s3 cp $LAMBDA_SUCCESS_ZIP s3://$BUCKET_NAME/lambda/success/src/lambda_function.zip
aws s3 cp $LAMBDA_FAIL_ZIP s3://$BUCKET_NAME/lambda/fail/src/lambda_function.zip
aws s3 cp $LAMBDA_MONITOR_EVENT_ZIP s3://$BUCKET_NAME/lambda/monitor-event-subscriber/src/lambda_function.zip
aws s3 cp $GLUE_JOB_SUCCESS_ZIP s3://$BUCKET_NAME/glue/glue-scripts/src/glue_job_success.zip
aws s3 cp $GLUE_JOB_FAIL_ZIP s3://$BUCKET_NAME/glue/glue-scripts/src/glue_job_fail.zip
aws s3 cp $LAMBDA_LOG_FORWARDER_ZIP s3://$BUCKET_NAME/lambda/log-forwarder/src/lambda_function.zip
aws s3 cp $LAMBDA_MONITOR_LAYER_ZIP s3://$BUCKET_NAME/lambda/monitor-event-subscriber/src/layer.zip

echo "Lambda functions and Glue script uploaded to S3 bucket."

rm -f $LAMBDA_ETL_TASK_ZIP
rm -f $LAMBDA_SUCCESS_ZIP
rm -f $LAMBDA_FAIL_ZIP
rm -f $LAMBDA_MONITOR_EVENT_ZIP
rm -f $GLUE_JOB_SUCCESS_ZIP
rm -r $GLUE_JOB_FAIL_ZIP
rm -f $LAMBDA_LOG_FORWARDER_ZIP
rm -f $LAMBDA_MONITOR_LAYER_ZIP

# Output the S3 paths
echo "Uploaded files:"
echo "Lambda ETL Task: s3://$BUCKET_NAME/lambda/etl-task/src/lambda_function.zip"
echo "Lambda Monitor Event Subscriber: s3://$BUCKET_NAME/lambda/monitor-event-subscriber/src/lambda_function.zip"
echo "Lambda Log Forwarder: s3://$BUCKET_NAME/lambda/log-forwarder/src/lambda_function.zip"
echo "Lambda Monitor Layer: s3://$BUCKET_NAME/lambda/monitor-event-subscriber/src/layer.zip"
