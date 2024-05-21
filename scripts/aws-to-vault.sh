#!/bin/bash

# This script for demo purposes.
# Use caution when dealing with production secrets.

AWSRegion="us-east-2"
VaultMount="kv"

# color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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
        echo -n "Adding secret: $Path"
        Resp=$(aws secretsmanager get-secret-value --region $AWSRegion --query 'SecretString' --output json --secret-id $Path | jq -r)
        vault kv put $VaultMount/$Path $(jq -r 'to_entries | map("\(.key)=\(.value)") | join(" ")' <<< $Resp) > /dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            echo -e " - ${GREEN}SUCCESS${NC}"
        else
            echo -e " - ${RED}FAILED${NC}"
        fi
    done

    if [[ $NextToken == "null" ]]; then
        break
    fi
done
