#!/bin/bash

# Variables
STACK_NAME="sdl-data-lake-stack"
TEMPLATE_FILE="../sdl-etl-jobs/template.yaml"
PARAMETERS_FILE="../sdl-etl-jobs/parameters.json"

# Create the CloudFormation stack
aws cloudformation create-stack --stack-name $STACK_NAME --template-body file://$TEMPLATE_FILE --parameters file://$PARAMETERS_FILE --capabilities CAPABILITY_NAMED_IAM

# Wait for the stack to be created
aws cloudformation wait stack-create-complete --stack-name $STACK_NAME

# Check the stack status
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].StackStatus" --output text)

if [ "$STACK_STATUS" == "CREATE_COMPLETE" ]; then
    echo "Stack $STACK_NAME created successfully."
else
    echo "Failed to create stack $STACK_NAME. Status: $STACK_STATUS"
fi
