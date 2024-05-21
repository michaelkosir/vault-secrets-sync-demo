#!/bin/bash

# This script for demo purposes.
# Use caution when dealing with production secrets.
# This script FORCE DELETES.

AWSRegion="us-east-2"
SecretPrefix="vault/"

# Confirm deletion
read -p "CONFIRM: This script will force delete AWS Secrets with prefix: $SecretPrefix (y/N): " confirmation
if [[ $confirmation != "y" && $confirmation != "Y" ]]; then
  exit 0
fi

NextToken=""
while : ; do
    if [[ -z $NextToken ]]; then
        Resp=$(aws secretsmanager list-secrets --region $AWSRegion --output json)
    else
        Resp=$(aws secretsmanager list-secrets --region $AWSRegion --output json --starting-token $NextToken)
    fi

    Paths=$(echo $Resp | jq -r '.SecretList[] | .Name')
    NextToken=$(echo $Resp | jq -r '.NextToken')

    for Path in $Paths; do
        if [[ $Path == "$SecretPrefix"* ]]; then
            echo "Removing secret: $Path"
            aws secretsmanager delete-secret --region $AWSRegion --force-delete-without-recovery --secret-id $Path 
        fi
    done

    if [[ $NextToken == "null" ]]; then
        break
    fi
done
