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

  # Export the key name and key file as environment variables
  export KEY_NAME="$KEY_NAME"
  export KEY_FILE="$(pwd)/$KEY_FILE"

  if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
    KEY_FILE=$(wslpath -m "$KEY_FILE")
  fi
  
else
  echo "Failed to create key pair"
  exit 1
fi
# End script