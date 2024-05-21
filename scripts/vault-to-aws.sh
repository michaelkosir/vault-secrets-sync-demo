#!/bin/bash

# This script for demo purposes.
# Use caution when dealing with production secrets.

Destination="demo-use2-templated" # the name of the destination configured in Vault
VaultMount="kv"
VaultParentPath="demo/"

# color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

iterate() {
    local Path=$1
    Resp=$(vault kv list -format=json $Path 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        return
    fi

    echo $Resp | jq -r '.[]' | while read -r Item; do
        FullPath=$Path$Item
        if [[ $Item != */ ]]; then
            echo -n "Syncing secret: $FullPath"
            SecretName="${FullPath#$VaultMount/}"
            Output=$(vault write -format=json sys/sync/destinations/aws-sm/$Destination/associations/set mount=$VaultMount secret_name=$SecretName)
            jq .data.associated_secrets <<< $Output | grep -e "\"secret_name\": \"$SecretName\"" -A 1 | grep SYNCED > /dev/null
            if [[ $? -eq 0 ]]; then
                echo -e " - ${GREEN}SUCCESS${NC}"
            else
                echo -e " - ${RED}FAILED${NC}"
            fi
        else
            iterate $FullPath
        fi
    done
}

# Start the DFS from the Parent Path
iterate "$VaultMount/$VaultParentPath"
