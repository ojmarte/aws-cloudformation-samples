#!/bin/bash

# Variables
STACK_NAME="simple-data-lake-setup"

# Function to empty an S3 bucket
empty_bucket() {
  BUCKET_NAME=$1
  echo "Emptying bucket: $BUCKET_NAME"
  aws s3 rm s3://$BUCKET_NAME --recursive
}

# Get the list of buckets to be deleted
LANDING_BUCKET=$(aws cloudformation describe-stack-resource --stack-name $STACK_NAME --logical-resource-id rLandingBucket --query "StackResourceDetail.PhysicalResourceId" --output text)
PROCESSED_BUCKET=$(aws cloudformation describe-stack-resource --stack-name $STACK_NAME --logical-resource-id rProcessedBucket --query "StackResourceDetail.PhysicalResourceId" --output text)

# Empty the buckets
empty_bucket $LANDING_BUCKET
empty_bucket $PROCESSED_BUCKET

# Delete the CloudFormation stack
aws cloudformation delete-stack --stack-name $STACK_NAME

# Wait for the stack to be deleted
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME

# Check the stack deletion status
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].StackStatus" --output text 2>&1)

if [[ $STACK_STATUS == *"does not exist"* ]]; then
    echo "Stack $STACK_NAME deleted successfully."
else
    echo "Failed to delete stack $STACK_NAME. Status: $STACK_STATUS"
fi
