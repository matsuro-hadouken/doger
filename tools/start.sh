#!/bin/bash

# *** DOGECASH MASTER ONELINER ***

# Copyright (C) 2020 Matsuro Hadouken <matsuro-hadouken@protonmail.com>

# This file is free software; as a special exception the author gives
# unlimited permission to copy and/or distribute it, with or without
# modifications, as long as this notice is preserved.

# PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND

if [[ $EUID -ne 0 ]]; then

    echo && echo -e "${RED}WARNING: $0 must be run as root.${NC}" && echo

    exit 1
fi

COIN_NAME='dogecash'
MASTER_CONTAINER_NAME='MASTER'

LFB="unknown"
CONTAINER_HEIGHT="0"

MASTER_CONTAINER_HUB='dogecash/no-prompt-main-master_x64'
SLAVE_CONTAINER_HUB='dogecash/no-prompt-main-slave_x64'

numba='^[0-9]+$'

EXPLORER_URL='https://explorer.dogec.io/api/v2'

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

function annotation() {

    clear && echo

    echo && echo -e "${RED}PLEASE READ:${NC}" && echo

    echo "We about to start $MASTER_CONTAINER_NAME node container for $COIN_NAME" && echo

    echo "Script build for begginers and required naked VPS server with only docker installed,"
    echo "please use docker-install.sh first from $COIN_NAME docker repository." && echo

    echo -e "${RED}All images and containers will be wiped from this VPS, if you already have docker${NC}"
    echo -e "${RED}containers or images on your system it will be no way to recover them.${NC}" && echo

    echo -e "${GREEN}Advanced users please setup everything manualy according appropriate instruction.${NC}" && echo

    read -rp "Continue ? Ctrl-C to stop or any key to continue."

    echo

}

function inputs() {

    read -p 'Masternode private key: ' PRIVAT_KEY
    echo
    read -p 'VPS esternal IP: ' EXTERNAL_IP

    echo

    echo -e "${RED}Private key:${NC} $PRIVAT_KEY"
    echo -e "${RED}External IP address:${NC} $EXTERNAL_IP"

    echo

    read -rp "Is this correct ? Ctrl-C to stop or any key to continue."

}

function install_MASTER() {

    echo -e "${RED}Stopping active containers and removing all docker data ...${NC}" && echo && sleep 2

    docker container stop "$(docker container list -qa)"

    sleep 3

    docker system prune -a -f

    sleep 1

    docker volume prune -f

    sleep 1

    docker container prune -f

    sleep 3

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

function wait_for_sync() {

    while ! [[ $LFB =~ $numba ]]; do

        LFB=$(curl -s $EXPLORER_URL | jq '.blockbook | .bestHeight')

        echo && echo "Waiting for $COIN_NAME explorer replay."

        sleep 1

    done

    echo -e "Netwrok last finalized block: $LFB"
    echo "Waiting for container to follow." && echo

    while true; do

        LFB=$(curl -s $EXPLORER_URL | jq '.blockbook | .bestHeight')

        CONTAINER_HEIGHT=$(docker exec -u "$COIN_NAME" -it "$MASTER_CONTAINER_NAME" "$COIN_NAME"-cli getblockcount)

        if [[ $CONTAINER_HEIGHT =~ $LFB ]]; then

            break

        fi

        sleep 3

    done

}

function successs() {

    echo && echo -e "${GREEN}Container syncronized with network.${NC}" && echo
    echo -e "${GREEN}Netwrok last finalized block:${NC} $LFB"
    echo -e "${GREEN}Container best height:${NC}        $CONTAINER_HEIGHT" && echo

    echo -e "${GREEN}Masternode can be started from desktop wallet, done.${NC}" && echo
    echo -e "${RED}If this node get online, you will never ever need to run this script again.${NC}" && echo
    echo -e "${GREEN}Good luck.${NC}" && echo

}

annotation

inputs

install_MASTER

wait_for_sync

successs
