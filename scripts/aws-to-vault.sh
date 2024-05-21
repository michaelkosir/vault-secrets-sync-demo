#!/bin/bash

# This script for demo purposes.
# Use caution when dealing with production secrets.

AWSRegion="us-east-2"
VaultMount="kv"

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
        echo "Adding secret: $Path"
        Resp=$(aws secretsmanager get-secret-value --region $AWSRegion --query 'SecretString' --output json --secret-id $Path | jq -r)
        vault kv put $VaultMount/$Path $(jq -r 'to_entries | map("\(.key)=\(.value)") | join(" ")' <<< $Resp)
    done

    if [[ $NextToken == "null" ]]; then
        break
    fi
done
