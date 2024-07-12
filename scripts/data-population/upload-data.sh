#!/bin/bash

# Define the bucket name
BUCKET_NAME="my-org-devops-dev-landing-bucket"

# Define the local directory containing the JSON files
LOCAL_DIR="../../data"

# Loop through each JSON file in the directory and upload it to the S3 bucket
for FILE in $LOCAL_DIR/*.json; do
    # Extract the base file name (without the directory)
    FILE_NAME=$(basename $FILE)
    
    # Upload the file to the S3 bucket
    aws s3 cp $FILE s3://$BUCKET_NAME/$FILE_NAME
    
    # Check if the upload was successful
    if [ $? -eq 0 ]; then
        echo "Successfully uploaded $FILE_NAME to s3://$BUCKET_NAME/"
    else
        echo "Failed to upload $FILE_NAME"
    fi
done
