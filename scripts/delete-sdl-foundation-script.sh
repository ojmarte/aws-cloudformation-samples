#!/bin/bash

# Variables
STACK_NAME="foundation-stack"

# Get the S3 bucket name from the CloudFormation stack outputs
BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='oLambdaGlueS3BucketName'].OutputValue" --output text)

# Check if the bucket name is retrieved
if [ -z "$BUCKET_NAME" ]; then
    echo "Failed to retrieve S3 bucket name from stack outputs."
    exit 1
fi

echo "S3 bucket to be deleted: $BUCKET_NAME"

# Delete all objects from the S3 bucket
aws s3 rm s3://$BUCKET_NAME --recursive

# Delete the CloudFormation stack
aws cloudformation delete-stack --stack-name $STACK_NAME

# Wait for the stack to be deleted
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME

echo "CloudFormation stack deleted and S3 bucket cleaned up."
