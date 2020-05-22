#!/bin/bash

# check blockchain info
# blockchain.sh [NODE_NAME]

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

NODE_NAME=$1

function checkArguments() {

    if [ -z "$NODE_NAME" ]; then

        echo && echo -e "${RED}ERROR: Not enough arguments.${NC}" && echo
        echo -e "${GREEN}blockchain.sh [NODE_NAME]${NC}" && echo
        echo 'Example: ./blockchain.sh MASTER'
        echo 'Example: ./blockchain.sh SLAVE_3' && echo

        exit 1

    fi

}

function MasternodeStatus() {

    while true; do

        clear

        echo

        data=$(docker exec -it "$NODE_NAME" dogecash-cli getblockchaininfo)

        echo $data | jq

        echo && read -rp "Check again ? Ctrl-C to exit or any key to continue."

    done

}

checkArguments

MasternodeStatus
