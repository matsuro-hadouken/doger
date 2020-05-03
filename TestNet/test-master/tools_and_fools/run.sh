#!/bin/bash

# Copyright (C) 2020 Matsuro Hadouken <matsuro-hadouken@protonmail.com>

# This file is free software; as a special exception the author gives
# unlimited permission to copy and/or distribute it, with or without
# modifications, as long as this notice is preserved.

# PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND

# *** TEST NET ***

# Run daemon according provided configuration.

# Requirements: masternode private_key and external_ip set in $COIN_NAME.conf.

# Have fun !

# NO ROOT , $COIN_NAME should be provided with -u

# docker exec -u dogecash -it MASTER run.sh

COIN_NAME='dogecash'

CONTAINER_NAME='MASTER'

DAEMON_CONFIG="/home/$COIN_NAME/.$COIN_NAME/$COIN_NAME.conf"

CONFIG_D="-daemon -testnet -conf=$DAEMON_CONFIG -datadir=/home/$COIN_NAME/.$COIN_NAME"
DAEMON=/usr/local/bin/"$COIN_NAME"d

DAEMON_PID=$(pidof "$COIN_NAME"d)
numba='^[0-9]+$'

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if ! [[ $EUID -ne 0 ]]; then
    echo && echo -e "${RED}WARNING: $0 should NOT be run as root.${NC}" && echo
    echo -e "docker exec ${RED}-u $COIN_NAME${NC} -it MASTER run.sh" && echo
    exit 1
fi

echo
read -rp "CHECK CONTAINER NAME !!! Ctrl-C to stop or any key to continue."

if [ ! -f /home/$COIN_NAME/.$COIN_NAME/$COIN_NAME.conf ]; then
    echo "ERROR: $COIN_NAME.conf file does not exist."
    exit 1
fi

if ! grep -q 'masternodeprivkey' $DAEMON_CONFIG; then

    {
        echo '' && echo "No masternode private key found in $COIN_NAME.conf" && echo
        echo 'Build configuration:' && echo ''
        echo "docker exec -u 0 -it $CONTAINER_NAME $COIN_NAME.sh" && echo
        echo "docker exec -u 0 -it $CONTAINER_NAME config.sh" && echo

        read -rp "Start as seeder ? Ctrl-C to stop or any key to continue."

        sed -i '/masternode=/d' $DAEMON_CONFIG
    }

fi

if ! grep -q 'externalip' $DAEMON_CONFIG; then

    {
        echo && echo "No externalip found in $COIN_NAME.conf" && echo
        echo 'Build configuration first:' && echo
        echo "docker exec -u 0 -it $CONTAINER_NAME $COIN_NAME.sh" && echo
        echo "docker exec -u 0 -it $CONTAINER_NAME config.sh" && echo

        exit 1
    }

fi

if [[ $DAEMON_PID =~ $numba ]]; then

    echo && echo "ERROR: $COIN_NAME daemon is already running." && echo
    echo 'Use wipe.sh stop' && echo

    exit 1

fi

echo && echo 'TEST-NET deploy ...' && echo
echo 'To check logs:' && echo
echo "docker exec -it $CONTAINER_NAME tail -f /home/dogecash/.dogecash/testnet4/debug.log" && echo

exec $DAEMON "$CONFIG_D"
