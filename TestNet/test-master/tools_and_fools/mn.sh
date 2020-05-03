#!/bin/bash

# Copyright (C) 2020 Matsuro Hadouken <matsuro-hadouken@protonmail.com>

# This file is free software; as a special exception the author gives
# unlimited permission to copy and/or distribute it, with or without
# modifications, as long as this notice is preserved.

# PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND

# *** TEST NET ***

# Private key manager. ADD key , CHANGE key , REMOVE key

# To change or add key:

# docker exec -u 0 -it $CONTAINER_NAME mn.sh <PRIVATE_KEY>

# To remove key:

# docker exec -u 0 -it $CONTAINER_NAME mn.sh <seed>

COIN_NAME='dogecash'

CONTAINER_NAME='MASTER'

DAEMON_CONFIG="/home/$COIN_NAME/.$COIN_NAME/$COIN_NAME.conf"

numba='^[0-9]+$'
DAEMON_PID=$(pidof "$COIN_NAME"d)

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo && echo -e "${RED}WARNING: $0 must be run as root.${NC}" && echo
    echo -e "docker exec ${RED}-u 0${NC} -it $CONTAINER_NAME mn.sh" && echo
    exit 1
fi

if [ -z "$1" ]; then

    echo
    echo -e "${RED}Not enough parameters:${NC}" && echo
    echo 'docker exec -t MASTER mn.sh <MASTERNODE_PRIVATE_KEY>' && echo
    echo 'To remove key and convert node to seeder use:' && echo
    echo -e "docker exec -t MASTER mn.sh ${GREEN}seed${NC}" && echo

    exit 1
fi

if ! grep -q 'rpcpassword' $DAEMON_CONFIG; then
    {
        echo && echo -e "${RED}No data in $COIN_NAME.conf${NC}"
        echo && echo 'Setup peer first, here is no point to add or remove operation with empty configuration file.' && echo

        exit 1
    }

fi

if [ "$1" == 'seed' ]; then
    {
        echo && echo -e "${RED}This will remove existing key from $COIN_NAME.conf${NC}" && echo

        cat $DAEMON_CONFIG | grep 'masternodeprivkey=' && echo
        cat $DAEMON_CONFIG | grep 'masternode=' && echo

        sleep 2

        read -rp "Ctrl-C to stop or any key to continue."

        echo

        sed -i '/masternodeprivkey=/d' $DAEMON_CONFIG
        sed -i '/masternode=/d' $DAEMON_CONFIG

        echo -e "${GREEN}####################### $COIN_NAME.conf #####################${NC}" && echo
        cat $DAEMON_CONFIG && echo
        echo -e "${GREEN}#############################################################${NC}" && echo

        exit 1

    }
fi

if grep -q 'masternodeprivkey=' $DAEMON_CONFIG; then
    {
        echo && echo -e "${RED}Masternode private key present in $COIN_NAME.conf${NC}" && echo

        cat $DAEMON_CONFIG | grep 'masternodeprivkey=' && echo
        echo -e "${GREEN}New private key:${NC}" && echo
        echo "masternodeprivkey=$1" && echo

        read -rp "Replace private key ? Ctrl-C to stop or any key to continue."

        sed -i '/masternodeprivkey=/d' $DAEMON_CONFIG
        sed -i '/masternode=/d' $DAEMON_CONFIG

    }

else

    echo && echo -e "${GREEN}DogeCash Shapeshifter:${NC}" && echo
    echo -e "${GREEN}Converting seeder to masternode, private key will be add to $COIN_NAME.conf${NC}" && echo

    read -rp "Ctrl-C to stop or any key to continue."

fi

function daemon_kill() {

    if ! [[ $DAEMON_PID =~ $numba ]]; then

        echo '' && echo 'Cheking if daemon is running ...'

        sleep 1

        echo '' && echo 'No numba PID return, such possible daemon dead, good.' && echo

    else

        echo '' && echo -e "${RED}Daemon online, destroy ...${NC}"

        kill -2 "$DAEMON_PID"

        sleep 5

        echo '' && echo -e "${GREEN}Daemon dead, such much fun, continue ...${NC}" && echo ''

    fi

}

daemon_kill

echo "masternodeprivkey=$1" >>$DAEMON_CONFIG
echo 'masternode=1' >>$DAEMON_CONFIG

echo -e "${GREEN}####################### $COIN_NAME.conf #####################${NC}" && echo
cat $DAEMON_CONFIG && echo
echo -e "${GREEN}#############################################################${NC}" && echo

echo "Please review your $COIN_NAME masternode configuration for $CONTAINER_NAME deploy." && echo
echo "To start $COIN_NAME masternode use this command this:" && echo
echo "docker exec -u $COIN_NAME -it $CONTAINER_NAME run.sh" && echo
