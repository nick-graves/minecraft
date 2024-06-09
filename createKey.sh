#!/bin/bash

# Variables
KEY_NAME="test" # Replace with your desired key name
KEY_FILE="${KEY_NAME}.pem"


# Generate the key pair
aws ec2 create-key-pair --key-name "$KEY_NAME" --query 'KeyMaterial' --output text > "$KEY_FILE"

# Check if the key pair was created successfully
if [ $? -eq 0 ]; then
  echo "Key pair $KEY_NAME created and saved to $KEY_FILE"

  # Change permissions of the key file
  chmod 400 "$KEY_FILE"
  echo "Permissions for $KEY_FILE set to 400"
else
  echo "Failed to create key pair"
fi
# End script