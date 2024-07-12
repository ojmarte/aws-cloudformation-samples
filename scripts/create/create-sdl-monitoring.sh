#!/bin/bash

# Variables
STACK_NAME="sdl-monitoring-stack"
TEMPLATE_FILE="../../sdl-monitoring/template.yaml"
PARAMETERS_FILE="../../sdl-monitoring/parameters.json"

# Check if the template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "Template file $TEMPLATE_FILE does not exist."
  exit 1
fi

# Check if the parameters file exists
if [ ! -f "$PARAMETERS_FILE" ]; then
  echo "Parameters file $PARAMETERS_FILE does not exist."
  exit 1
fi

# Create the stack
echo "Creating stack ${STACK_NAME}..."
aws cloudformation create-stack --stack-name ${STACK_NAME} --template-body file://${TEMPLATE_FILE} --parameters file://${PARAMETERS_FILE} --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND

# Wait for the stack creation to complete
echo "Waiting for stack ${STACK_NAME} to complete..."
aws cloudformation wait stack-create-complete --stack-name ${STACK_NAME}

# Check the status of the stack
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} --query "Stacks[0].StackStatus" --output text)

if [ "$STACK_STATUS" == "CREATE_COMPLETE" ]; then
  echo "Stack ${STACK_NAME} created successfully."
else
  echo "Stack ${STACK_NAME} creation failed with status ${STACK_STATUS}."
fi
