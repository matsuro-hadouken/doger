#!/bin/bash

# check last finalized block on explorer and compare to $1 daemon

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

COIN_NAME='dogecash'

UPDATE_INTERVAL=5

EXPLORER_WEB='https://explorer.dogec.io/'
EXPLORER_API='https://explorer.dogec.io/api/v2'

NODE_NAME=$1
numba='^[0-9]+$'

function checkArguments() {

    if [ -z "$NODE_NAME" ]; then

        echo && echo -e "${RED}ERROR: Not enough arguments.${NC}" && echo
        echo -e "${GREEN}explorer.sh [NODE_NAME]${NC}" && echo
        echo 'Example: ./explorer.sh MASTER'
        echo 'Example: ./explorer.sh SLAVE_3' && echo

        exit 1

    fi

}

function SyncCheck() {

    echo && echo -e "${CYAN}Information will be updated automatically.${NC}"

    echo && echo -e "${GREEN}Waiting for $COIN_NAME explorer ...${NC}" && echo

    LFB=$(curl -s --max-time 20 --connect-timeout 40 $EXPLORER_API | jq '.blockbook | .bestHeight')

    if ! [[ $LFB =~ $numba ]]; then

        echo && echo -e "${RED}FATAL ERROR:${NC} Please check if explorer online, if not report to developers." && echo

        echo $EXPLORER_WEB && echo

        exit 1

    fi

    sleep 1

    while true; do

        LFB=$(curl -s --max-time 20 --connect-timeout 40 $EXPLORER_API | jq '.blockbook | .bestHeight')
        CONTAINER_HEIGHT=$(docker exec -u "$COIN_NAME" -it $NODE_NAME "$COIN_NAME"-cli getblockcount)

        echo -e "Explorer block:  $LFB"
        echo -e "Container block: $CONTAINER_HEIGHT"

        echo && echo "Ctrl-C to exit." && echo -e "\e[5A"

        sleep $UPDATE_INTERVAL

    done

    echo

}

checkArguments

SyncCheck
