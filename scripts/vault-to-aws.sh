#!/bin/bash

# This script for demo purposes.
# Use caution when dealing with production secrets.

Destination="demo-use2-templated" # the name of the destination configured in Vault
VaultMount="kv"
VaultParentPath=""

iterate() {
    local Path=$1
    Resp=$(vault kv list -format=json $Path 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        return
    fi

    echo $Resp | jq -r '.[]' | while read -r Item; do
        FullPath=$Path$Item
        if [[ $Item != */ ]]; then
            echo "Syncing secret: $FullPath"
            SecretName="${FullPath#$VaultMount/}"
            vault write sys/sync/destinations/aws-sm/$Destination/associations/set mount=$VaultMount secret_name=$SecretName
        else
            iterate $FullPath
        fi
    done
}

# Start the DFS from the Parent Path
iterate "$VaultMount/$VaultParentPath"
