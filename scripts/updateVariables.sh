#!/bin/bash

# Call createKey.sh
source ./scripts/createKey.sh

# Check if the key was created successfully
if [ $? -eq 0 ]; then
  # Update variables.tf with the new key name and key file path
  cat > terraform/variables.tf <<EOL
variable "key_name" {
  description = "SSH key pair name for EC2 instance"
  type        = string
  default     = "${KEY_NAME}"
}

variable "private_key_path" {
  description = "Path to the private key file"
  type        = string
  default     = "${KEY_FILE}"
}
EOL

  echo "variables.tf updated with new key name and key file path"
else
  echo "Failed to create key pair. variables.tf not updated."
fi
# End script