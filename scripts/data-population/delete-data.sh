#!/bin/bash

# Define the bucket name
BUCKET_NAME="my-org-devops-dev-landing-bucket"

# Define the local directory containing the JSON files
LOCAL_DIR="../data"

# Loop through each JSON file in the directory and delete the corresponding file from the S3 bucket
for FILE in $LOCAL_DIR/*.json; do
    # Extract the base file name (without the directory)
    FILE_NAME=$(basename $FILE)
    
    # Delete the file from the S3 bucket
    aws s3 rm s3://$BUCKET_NAME/$FILE_NAME
    
    # Check if the deletion was successful
    if [ $? -eq 0 ]; then
        echo "Successfully deleted $FILE_NAME from s3://$BUCKET_NAME/"
    else
        echo "Failed to delete $FILE_NAME"
    fi
done
