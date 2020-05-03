#!/bin/bash

# Copyright (C) 2020 Matsuro Hadouken <matsuro-hadouken@protonmail.com>

# This file is free software; as a special exception the author gives
# unlimited permission to copy and/or distribute it, with or without
# modifications, as long as this notice is preserved.

# PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND

# *** TEST NET ***

### THIS TOOL IS FOR ADVANCED USERS ONLY ###
### PLEASE READ ALL INSTRUCTIONS: ##########

# Script will wipe things, depends on your needs.

# available commands:

# wipe.sh stop          - stop daemon
# wipe.sh data          - remove all chain and database data
# wipe.sh wallet        - remove wallet.dat ( becareful )
# wipe.sh config        - remove everything from config, including private node key ( becareful )

# If you wipe config this will make node malfunctional, so run config.sh to recreate.
# As best solution running dogecash.sh is the recommended way to go.

# This will only work as container root user:'
# docker exec -u 0 -it $CONTAINER_NAME wipe.sh [option1] [option2] ...

COIN_NAME='dogecash'

CONTAINER_NAME='MASTER'

DAEMON_CONFIG="/home/$COIN_NAME/.$COIN_NAME/$COIN_NAME.conf"
CONFIG_HEADER="/home/$COIN_NAME/header.txt"

TestNetDATA=/home/"$COIN_NAME"/."$COIN_NAME"/testnet4

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo && echo -e "${RED}WARNING: $0 must be run as root.${NC}" && echo
    echo -e "docker exec ${RED}-u 0${NC} -it MASTER wipe.sh" && echo
    exit 1
fi

if [ -z "$1" ]; then

    echo && echo 'Parameters missing !' && echo
    echo -e "${RED}THIS TOOLSET IS FOR ADVANCED USERS ONLY${NC}" && echo
    echo 'Awailable parameters:' && echo

    echo 'wipe.sh stop          - stop daemon'
    echo 'wipe.sh data          - remove all chain and database data'
    echo 'wipe.sh wallet        - remove wallet.dat ( becareful )'
    echo 'wipe.sh config        - remove everything from config, including private node key ( becareful )'

    echo && echo 'Run only as root user:' && echo
    echo "docker exec -u 0 -it $CONTAINER_NAME wipe.sh [option1] [option2] ..." && echo

    exit 1

fi

function stop() {

    echo
    echo "Killing $COIN_NAME daemon ..."
    echo

    DAEMON_PID=$(pidof "$COIN_NAME"d)

    numba='^[0-9]+$'

    if ! [[ $DAEMON_PID =~ $numba ]]; then

        echo && echo 'No numba PID return, such possible daemon dead already.' && echo

    else

        kill -2 "$DAEMON_PID" && sleep 5

    fi
}

function data() {

    echo && echo "All data about to get ..." && echo

    DAEMON_PID=$(pidof "$COIN_NAME"d)

    numba='^[0-9]+$'

    if [[ $DAEMON_PID =~ $numba ]]; then

        echo && echo "ERROR: $COIN_NAME daemon is online."
        echo && echo 'Use <stop> to kill it first !' && echo

        exit 1

    fi

    rm -rf $TestNetDATA

    sleep 1

    echo && echo "... successfully wiped, no such more data." && echo

    ls -lah /home/"$COIN_NAME"/."$COIN_NAME"/

    echo

}

function wallet() {

    if [ ! -f $TestNetDATA/wallet.dat ]; then

        echo && echo "No wallet.dat found in $TestNetDATA" && echo
        ls -lah /home/"$COIN_NAME"/."$COIN_NAME"/ && echo '' && sleep 2

        exit 1

    fi

    echo && echo "Removing wallet.dat for $COIN_NAME ..." && echo
    echo 'You still can change your mind with Ctrl + C' && sleep 10 && echo

    rm -f $TestNetDATA/wallet.dat

    echo && echo 'walle.dat deleted.' && echo

    ls -lah $TestNetDATA && echo

    sleep 1

}

function config() {

    echo && echo "Wiping $COIN_NAME.conf ..." && echo
    cat "$CONFIG_HEADER" >"$DAEMON_CONFIG"

    echo
    cat $DAEMON_CONFIG
    echo

}

echo
read -rp "THIS WILL KILL WORKING PEER, CHECK CONTAINER NAME !!! Ctrl-C to stop or any key to continue."

$1
$2
$3
$4
$5
$6

chown -R $COIN_NAME:$COIN_NAME /home/"$COIN_NAME"/."$COIN_NAME"/*
