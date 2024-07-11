#!/bin/bash

# Variables
STACK_NAME="sdl-data-lake-stack"
TEMPLATE_FILE="../sdl-etl-jobs/template.yaml"
PARAMETERS_FILE="../sdl-etl-jobs/parameters.json"

# Update the CloudFormation stack
aws cloudformation update-stack --stack-name $STACK_NAME --template-body file://$TEMPLATE_FILE --parameters file://$PARAMETERS_FILE --capabilities CAPABILITY_NAMED_IAM

# Wait for the stack to be updated
aws cloudformation wait stack-update-complete --stack-name $STACK_NAME

# Check the stack status
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].StackStatus" --output text)

if [ "$STACK_STATUS" == "UPDATE_COMPLETE" ]; then
    echo "Stack $STACK_NAME updated successfully."
else
    echo "Failed to update stack $STACK_NAME. Status: $STACK_STATUS"
fi
