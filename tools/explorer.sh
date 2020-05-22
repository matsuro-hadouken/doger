#!/bin/bash

# check last finalized block on explorer and compare to daemon

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

COIN_NAME='dogecash'

EXPLORER_WEB='https://explorer.dogec.io/'
EXPLORER_API='https://explorer.dogec.io/api/v2'

NODE_NAME=$1
numba='^[0-9]+$'

function SyncCheck() {

    echo && echo -e "${GREEN}Waiting for $COIN_NAME explorer ...${NC}" && echo

    LFB=$(curl -s --max-time 20 --connect-timeout 40 $EXPLORER_API | jq '.blockbook | .bestHeight')

    if ! [[ $LFB =~ $numba ]]; then

        echo && echo -e "${RED}FATAL ERROR:${NC} Please check if explorer online, if not report to developers." && echo

        echo $EXPLORER_WEB && echo

        exit 1

    fi

    sleep 1

    echo -e "Current $COIN_NAME network last finalized block: $LFB" && echo
    echo && echo -e "${RED}Next step take unknown amount of time, patience required for decentralized magic.${NC}" && echo

    echo "Waiting for container to follow, please wait ..." && echo

    while true; do

        CONTAINER_HEIGHT=$(docker exec -u "$COIN_NAME" -it "$MASTER_CONTAINER_NAME" "$COIN_NAME"-cli getblockcount)

        if [[ $CONTAINER_HEIGHT =~ $LFB ]]; then

            break

        fi

        sleep 5

    done

}
