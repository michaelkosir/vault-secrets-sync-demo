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
            echo -n "Removing secret: $FullPath"
            SecretName="${FullPath#$VaultMount/}"
            vault write -format=json sys/sync/destinations/aws-sm/$Destination/associations/remove mount=$VaultMount secret_name=$SecretName > /dev/null 2>&1
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

# remove demo secret that was added manually
echo -n "Removing secret: kv/path/to/secret"
vault write -format=json sys/sync/destinations/aws-sm/demo-use2/associations/remove mount=kv secret_name="path/to/secret" > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
    echo -e " - ${GREEN}SUCCESS${NC}"
else
    echo -e " - ${RED}FAILED${NC}"
fi
