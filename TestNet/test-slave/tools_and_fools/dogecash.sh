#!/bin/bash

# *** DOGECASH ONELINER ***

# Copyright (C) 2020 Matsuro Hadouken <matsuro-hadouken@protonmail.com>

# This file is free software; as a special exception the author gives
# unlimited permission to copy and/or distribute it, with or without
# modifications, as long as this notice is preserved.

# PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND

# TestNet configuration script.

# docker exec -u 0 -it $CONTAINER_NAME $COIN_NAME.sh <MASTERNODE_PRIVATE_KEY>

# For seeder: docker exec -u 0 -it $CONTAINER_NAME $COIN_NAME.sh <seed>

COIN_NAME='dogecash'

CONTAINER_NAME='SLAVE_NAME'

TestNetDATA=/home/"$COIN_NAME"/."$COIN_NAME"/testnet4

DAEMON_CONFIG="/home/$COIN_NAME/.$COIN_NAME/$COIN_NAME.conf"

CONFIG_HEADER="/home/$COIN_NAME/header.txt"

numba='^[0-9]+$'
DAEMON_PID=$(pidof "$COIN_NAME"d)

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo && echo -e "${RED}WARNING: $0 must be run as root.${NC}" && echo
    echo -e "docker exec ${RED}-u 0${NC} -it MASTER update.sh" && echo
    exit 1
fi

if [ -z "$1" ]; then

    echo && echo -e "${RED}ERROR: Not enough parameters.${NC}" && echo
    echo -e "docker exec -u 0 -it $CONTAINER_NAME $COIN_NAME.sh ${RED}PRIV_KEY${NC}" && echo
    echo -e "${GREEN}For seeder mode:${NC} docker exec -u 0 -it $CONTAINER_NAME $COIN_NAME.sh ${RED}seed${NC}" && echo

    exit 1
fi

echo
read -rp "CHECK CONTAINER NAME !!! Ctrl-C to stop or any key to continue."

if [ ! -f $DAEMON_CONFIG ]; then
    touch $DAEMON_CONFIG
fi

function daemon_kill() {

    if ! [[ $DAEMON_PID =~ $numba ]]; then

        echo && echo 'Cheking if daemon is running ...'

        sleep 1

        echo && echo 'No numba PID return, such possible daemon dead, good.' && echo

    else

        echo && echo -e "${RED}Daemon online, destroy ...${NC}"

        kill -2 "$DAEMON_PID"

        sleep 5

        echo && echo -e "${GREEN}Daemon dead, such much fun, continue ...${NC}" && echo

    fi

}

function rpc_add() {

    if ! grep -q 'rpcuser' $DAEMON_CONFIG; then

        RPCUSER="dozecaze"

        {
            echo
            echo "rpcuser=${RPCUSER}"

        } >>$DAEMON_CONFIG
    fi

    if ! grep -q 'rpcpassword' $DAEMON_CONFIG; then

        RPCPASSWORD=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

        {
            echo "rpcpassword=${RPCPASSWORD}"

        } >>$DAEMON_CONFIG

    fi

    if ! grep -q 'rpcport=' $DAEMON_CONFIG; then

        {

            echo
            echo "rpcport=$(shuf -i 10000-60000 -n 1)"
            echo

        } >>$DAEMON_CONFIG
    fi
}

function pre_clean() {

    echo "WIPING ALL DATA, NO JOKE !"
    echo

    sleep 2

    rm -rf $TestNetDATA

    echo && echo 'Successfully wiped everything ! ( well not really, check: )' && echo
    ls -lah /home/"$COIN_NAME"/."$COIN_NAME"/
    echo

    sleep 1
}

chown -R $COIN_NAME:$COIN_NAME /home/"$COIN_NAME"/*

daemon_kill

cat "$CONFIG_HEADER" >"$DAEMON_CONFIG"

rpc_add

if ! [ "$1" == 'seed' ]; then
    {
        echo "masternodeprivkey=$1" >>$DAEMON_CONFIG
        echo 'masternode=1' >>$DAEMON_CONFIG
        cat $DAEMON_CONFIG | grep 'masternodeprivkey=' && echo
    }
else

    echo && echo -e "${RED}Peer running in a seeder mode${NC}" && echo && sleep 2

fi

pre_clean

echo -e "${GREEN}####################### $COIN_NAME.conf #####################${NC}" && echo
cat $DAEMON_CONFIG
echo -e "${GREEN}#############################################################${NC}" && echo

echo "Please review your $COIN_NAME masternode configuration for $CONTAINER_NAME deploy." && echo
echo "To start $COIN_NAME masternode use this command this:" && echo
echo "docker exec -u $COIN_NAME -it $CONTAINER_NAME run.sh" && echo
