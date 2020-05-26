#!/bin/bash

# *** DOGECASH MASTER ONELINER ***

# Copyright (C) 2020 Matsuro Hadouken <matsuro-hadouken@protonmail.com>

# This file is free software; as a special exception the author gives
# unlimited permission to copy and/or distribute it, with or without
# modifications, as long as this notice is preserved.

# PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then

    echo && echo -e "${RED}WARNING: $0 must be run as root.${NC}" && echo

    exit 1
fi

COIN_NAME='dogecash'
MASTER_CONTAINER_NAME='MASTER'
EXPLORER_WEB='https://explorer.dogec.io/'
EXPLORER_API='https://explorer.dogec.io/api/v2'

confirmations_need=3
rotten_tomato=99 # to old transaction, possible collateral lost ( staking, human factor ... )

LFB="unknown"
CONTAINER_HEIGHT="0"

MASTER_CONTAINER_HUB='dogecash/no-prompt-main-master_x64'

re='^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}'
re+='0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))$'
numba='^[0-9]+$'

function if_Docker() {

    if ! [ -x "$(command -v docker)" ]; then

        echo -e "${RED}ERROR: Need to install docker first.${NC}" && echo

        echo "Run this command:"

        echo 'wget -O - https://raw.githubusercontent.com/matsuro-hadouken/doger/master/docker-install.sh | bash'

        exit 1

    fi
}

function Annotation() {

    clear

    echo && echo -e "${RED}PLEASE READ:${NC}" && echo

    echo -e "${RED}This script is designed for a clean install on Ubuntu 18 or Debian${NC}."
    echo -e "${RED}It will destroy any other docker data of yours.${NC}"

    echo "We about to start $MASTER_CONTAINER_NAME node container for $COIN_NAME" && echo
    echo -e "${RED}All images and containers will be wiped from this VPS, if you already have docker${NC}"
    echo -e "${RED}containers or images on your system it will be no way to recover them.${NC}" && echo
    echo -e "${GREEN}Advanced users please setup everything manualy according appropriate instruction.${NC}" && echo

    read -rp "Continue ? Ctrl-C to stop or any key to continue."

    clear

    echo

}

function collateralIndex() {

    clear

    echo && echo -e "${GREEN}Welcome to DogeCash dungeon, lets get started!${NC}" && echo
    echo -e "To become guardian of DogeCash universe every node owner shall attain strong desire." && echo
    echo -e "Open desktop wallet, go to ${GREEN}RECEIVE${NC} tab and create new address." && echo
    echo -e "From the same  wallet send ${GREEN}exactly 5000 DogeCash${NC} to the address which just been created." && echo
    echo -e "Now go to ${GREEN}HOME${NC} tab, you should see new transaction to your self in a history list." && echo
    echo -e "Open the transaction details and look for ${GREEN}tx ID${NC}, see ?" && echo

    while true; do

        read -rp 'Yes here is my ID: ' collateral_txid

        if [[ "$collateral_txid" =~ ^[0-9]+$ ]] || [[ "$collateral_txid" =~ ^[a-zA-Z]+$ ]] || [[ "$collateral_txid" =~ ['!@#$%^&*()_+ '] ]]; then

            echo && echo -e "${RED}ERROR: Invalid TX ID, please try again.${NC}" && echo

        else

            break

        fi

    done

    collateral_index=$(curl -s --max-time 15 --connect-timeout 20 https://explorer.dogec.io/api/v2/tx/"$collateral_txid" | jq '.vout' | grep 'value' | head -1 | tr -d '"value": ,')

    if ! [[ $collateral_index =~ $numba ]]; then

        clear

        echo && echo -e "${RED}ERROR: Please, double check ID you provide.${NC}" && echo
        echo "Search in explorer for your transaction, if explorer offline report to developers." && echo

        echo $EXPLORER_WEB && echo

        sleep 1

        setterm -cursor on

        exit 1

    fi

    if ! [[ $collateral_index =~ '500000000000' ]]; then

        collateral_index='1'

    else

        collateral_index='0'

    fi

    # confirmations check

    setterm -cursor off

    confirmations=$(curl -s --max-time 15 --connect-timeout 20 https://explorer.dogec.io/api/v2/tx/"$collateral_txid" | jq '.' | grep '"confirmations":' | tr -d 'confirmats":  ,')

    if ! [[ $confirmations =~ $numba ]]; then

        echo && echo -e "${RED}ERROR: Please check if explorer online, if not, then report to developers.${NC}" && echo

        echo $EXPLORER_WEB && echo

        sleep 1

        setterm -cursor on

        exit 1

    fi

    if ! [[ $confirmations -gt $confirmations_need ]]; then

        echo && echo -e "${GREEN}Waiting for at least $confirmations_need confirmations ...${NC}" && echo

        until [[ $confirmations -gt $confirmations_need ]]; do

            confirmations=$(curl -s --max-time 15 --connect-timeout 20 https://explorer.dogec.io/api/v2/tx/"$collateral_txid" | jq '.' | grep '"confirmations":' | tr -d 'confirmats":  ,')

            echo -ne "Confirmed: $confirmations time.\\r"

            sleep 10

        done

        echo "Such fast block chain!" && echo

    else

        if [[ $confirmations -ge $rotten_tomato ]]; then

            echo && echo -e "${CYAN}WARNING: $confirmations confirmtions, transaction is to old, we suggest to make a new one.${NC}"

        else

            echo && echo -e "${GREEN}Transaction confirmed $confirmations times, which is more then enough.${NC}"
        fi

    fi

    setterm -cursor on

    echo && echo -e "Collateral transaction ID: ${RED}$collateral_txid${NC}" && echo
    echo -e "Collateral Index: ${RED}$collateral_index${NC}" && echo
    echo -e "Confirmed: ${RED}$confirmations${NC}"

    sleep 2

}

function Inputs() {

    echo && echo -e "${GREEN}Now we need to generate masternode private key.${NC}" && echo
    echo -e "Open desktop wallet, paste this command in to console ${RED}createmasternodekey${NC} and press enter." && echo

    while true; do

        read -rp 'Masternode private key: ' PRIVAT_KEY

        short=${PRIVAT_KEY:0:2}

        if [[ $short =~ 56 ]] || [[ $short =~ 57 ]]; then

            break

        else

            echo && echo -e "${RED}Invalid private key format, try again.${NC}" && echo

        fi

    done

    echo && echo -e "Trying to get external IP from couple of services ..." && echo

    amazon_aws=$(curl -s --max-time 10 --connect-timeout 15 https://checkip.amazonaws.com) || amazon_aws='dead pipe'
    ifconfig_me=$(curl -s --max-time 10 --connect-timeout 15 https://ifconfig.me) || ifconfig_me='dead pipe'
    ident_me=$(curl -s --max-time 10 --connect-timeout 15 https://ident.me) || ident_me='dead pipe'

    echo -e "${GREEN}amazonaws.com report: ${NC} $amazon_aws"
    echo -e "${GREEN}ifconfig.me report:   ${NC} $ifconfig_me"
    echo -e "${GREEN}ident.me report:      ${NC} $ident_me" && echo

    echo -e "${GREEN}Please use${NC} ${RED}IPv4${NC} ${GREEN}from the output above${NC} ${RED}^^${NC}" && echo && sleep 1

    while true; do

        read -rp 'VPS external IP: ' EXTERNAL_IP

        if [[ $EXTERNAL_IP =~ $re ]]; then

            break

        else

            echo && echo -e "${RED}Invalid IPv4 address format, try again.${NC}" && echo

        fi

    done

    echo && echo -e "${RED}Private key:${NC} $PRIVAT_KEY"
    echo -e "${RED}External IP address:${NC} $EXTERNAL_IP"

    echo

    read -rp "Is this correct ? Ctrl-C to stop or any key to continue."

}

function InstallMaster() {

    echo && echo -e "${RED}Stopping active containers and removing all docker data ...${NC}" && echo && sleep 2

    docker container stop "$(docker container list -qa)"

    echo && sleep 3

    docker system prune -a -f

    sleep 1

    docker volume prune -f

    sleep 1

    docker container prune -f

    sleep 2

    # echo && echo -e "${GREEN}Pulling slave image from $COIN_NAME hub ...${NC}" && echo && sleep 2

    # docker pull $SLAVE_CONTAINER_HUB

    echo && echo -e "${GREEN}Pulling master image from $COIN_NAME hub ...${NC}" && echo && sleep 2

    docker pull $MASTER_CONTAINER_HUB

    echo && echo -e "${GREEN}$MASTER_CONTAINER_NAME container deploy, port 56740 should be available from outside.${NC}" && echo

    docker run -it -d -p 56740:56740 --name $MASTER_CONTAINER_NAME "$MASTER_CONTAINER_HUB"

    sleep 3

    docker exec -u 0 -it $MASTER_CONTAINER_NAME dogecash.sh "$PRIVAT_KEY" "$EXTERNAL_IP"

    echo

    read -rp "Start $MASTER_CONTAINER_NAME node ? Ctrl-C to stop or any key to continue."

    docker exec -u $COIN_NAME -it $MASTER_CONTAINER_NAME run.sh

}

function WaitForSync() {

    echo && echo -e "${GREEN}Waiting for $COIN_NAME explorer ...${NC}" && echo

    LFB=$(curl -s --max-time 20 --connect-timeout 40 $EXPLORER_API | jq '.blockbook | .bestHeight')

    if ! [[ $LFB =~ $numba ]]; then

        echo && echo -e "${RED}FATAL ERROR:${NC} Please check if explorer online, if not report to developers." && echo

        echo $EXPLORER_WEB && echo

        exit 1

    fi

    echo -e "${RED}Next step take unknown amount of time, patience required for decentralized magic.${NC}" && echo

    echo "Waiting for container to follow, please wait ..." && echo

    while true; do

        CONTAINER_HEIGHT=$(docker exec -u "$COIN_NAME" -it "$MASTER_CONTAINER_NAME" "$COIN_NAME"-cli getblockcount)

        LFB=$(curl -s --max-time 20 --connect-timeout 40 $EXPLORER_API | jq '.blockbook | .bestHeight')

        CH=${CONTAINER_HEIGHT//[ $'\001'-$'\037']/}

        echo -e "${GREE}Explorer  block:${NC} $LFB"
        echo -e "${GREE}Container block:${NC} $CONTAINER_HEIGHT"

        if [[ "$CH" -ge "$LFB" ]]; then

            break

        fi

        echo -e "\e[3A"

        sleep 5

    done

    echo

}

function InstallationSuccesss() {

    echo && echo -e "${GREEN}Container syncronized with network.${NC}" && echo
    echo -e "${GREEN}Network last finalized block:${NC} $LFB"
    echo -e "${GREEN}Container best height:${NC}        $CONTAINER_HEIGHT" && echo

    echo "Add this line in to your DESKTOP masternode.conf:" && echo

    echo -e "${GREEN}$MASTER_CONTAINER_NAME $EXTERNAL_IP:56740${NC} ${RED}$PRIVAT_KEY${NC} $collateral_txid $collateral_index" && echo

    echo -e "${GREEN}About now, masternode can be started from your desktop computer.${NC}" && echo

    echo -e "${RED}If everything works in the end, you will never ever need to run this script again.${NC}" && echo

    echo -e "${GREEN}Good luck.${NC}" && echo

}

function MasternodeStatus() {

    echo && read -rp "Did you start masternode from your desktop wallet ? Ctrl-C to exit or any key to check status."

    clear

    echo && echo -e "${GREEN}#####################################################${NC}" && echo

    docker exec -it MASTER dogecash-cli getmasternodestatus

    echo && echo -e "${GREEN}#####################################################${NC}" && echo

    while true; do

        echo && read -rp "Check again ? Ctrl-C to exit or any key to continue."

        clear

        echo && echo -e "${GREEN}#####################################################${NC}" && echo

        docker exec -it MASTER dogecash-cli getmasternodestatus

        echo && echo -e "${GREEN}#####################################################${NC}" && echo

    done

}

Annotation

collateralIndex

Inputs

InstallMaster

WaitForSync

InstallationSuccesss

MasternodeStatus
