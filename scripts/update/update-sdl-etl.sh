#!/bin/bash

# Variables
STACK_NAME="sdl-data-lake-stack"
TEMPLATE_FILE="../sdl-etl-jobs/template.yaml"
PARAMETERS_FILE="../sdl-etl-jobs/parameters.json"
CHANGE_SET_NAME="$STACK_NAME-change-set"

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

echo "Updated Successfully"