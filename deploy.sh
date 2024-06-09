#!/bin/bash

# Call updateTerraform.sh to generate key and update variables.tf
./scripts/updateVariables.sh

# Check if the previous script ran successfully
if [ $? -eq 0 ]; then
  echo "Successfully updated variables.tf"

  # Change directory to the terraform configuration directory
  cd ./terraform || exit

  # Run Terraform commands in PowerShell
  powershell.exe -Command "
    terraform init;
    terraform apply -auto-approve;
  "
else
  echo "Failed to update variables.tf. Exiting."
  exit 1
fi