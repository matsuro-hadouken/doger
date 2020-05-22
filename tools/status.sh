#!/bin/bash

# check masternode status
# check_masternode_status.sh [NODE_NAME]

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

NODE_NAME=$1

function checkArguments() {

    if [ -z "$NODE_NAME" ]; then

        echo && echo -e "${RED}ERROR: Not enough arguments.${NC}" && echo
        echo -e "${GREEN}check_masternode_status.sh [NODE_NAME]${NC}" && echo
        echo 'Example: ./check_masternode_status.sh MASTER'
        echo 'Example: ./check_masternode_status.sh SLAVE_3' && echo

        exit 1

    fi

}

function MasternodeStatus() {

    while true; do

        clear

        echo

        docker exec -it "$NODE_NAME" dogecash-cli getmasternodestatus

        echo && read -rp "Check again ? Ctrl-C to exit or any key to continue."

        echo

    done

}

checkArguments

MasternodeStatus
