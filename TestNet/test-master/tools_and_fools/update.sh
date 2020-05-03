#!/bin/bash

# Copyright (C) 2020 Matsuro Hadouken <matsuro-hadouken@protonmail.com>

# This file is free software; as a special exception the author gives
# unlimited permission to copy and/or distribute it, with or without
# modifications, as long as this notice is preserved.

# PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND

# *** TEST NET ***

# Update daemon binaries with latest release from GitHub

# Run only as root: docker exec -u 0 -it $CONTAINER_NAME update.sh

COIN_NAME='dogecash'

CONTAINER_NAME='MASTER'

DAEMON="$COIN_NAME"d
CLIENT="$COIN_NAME"-cli

CLIENT_URL="https://www.dropbox.com/s/88pmplwjxq9fuwe/$CLIENT"
DAEMON_URL="https://www.dropbox.com/s/nkk35skdukc7ow5/$DAEMON"

DAEMON_CONFIG="/home/$COIN_NAME/.$COIN_NAME/$COIN_NAME.conf"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo && echo -e "${RED}WARNING: $0 must be run as root.${NC}" && echo
    echo -e "docker exec ${RED}-u 0${NC} -it MASTER update.sh" && echo
    exit 1
fi

echo && echo -e "${GREEN}Using provided download path:${NC}" && echo
echo $CLIENT_URL
echo $DAEMON_URL
echo

numba='^[0-9]+$'
DAEMON_PID=$(pidof "$COIN_NAME"d)

echo
read -rp 'PLEASE CHECK CONTAINER NAME! Ctrl-C to stop or any key to continue.'

function get_latest_release() {

    mkdir -p /home/"$COIN_NAME"/Update

    cd /home/"$COIN_NAME"/Update || exit 1

    rm -rf /home/"$COIN_NAME"/Update/*

    echo

    echo && echo -e "${GREEN}Connecting to $COIN_NAME Dropbox. This can take a while ...${NC}" && echo

    wget --no-check-certificate "$DAEMON_URL" -q --show-progress --progress=bar:force 2>&1

    if [[ "$?" != 0 ]]; then
        echo -e "${RED}ERROR: Download failed, check Dropbox availability.${NC}" && exit 1
    fi

    echo

    wget --no-check-certificate "$CLIENT_URL" -q --show-progress --progress=bar:force 2>&1

    if [[ "$?" != 0 ]]; then
        echo -e "${RED}ERROR: Download failed, check Dropbox availability.${NC}" && exit 1
    fi

    echo && echo -e "${GREEN}Setting up permissions ...${NC}" && echo && sleep 2

    chown -R $COIN_NAME:$COIN_NAME /home/"$COIN_NAME"/*

}

function daemon_kill() {

    if ! [[ $DAEMON_PID =~ $numba ]]; then

        echo && echo 'Cheking if daemon is running ...'

        sleep 1

        echo && echo 'No numba PID return, such possible daemon dead, good.'

    else

        echo && echo -e "${RED}Daemon online, destroy ...${NC}"

        kill -2 "$DAEMON_PID"

        sleep 5

        echo && echo -e "${GREEN}Daemon dead, such much fun, continue ...${NC}" && echo

    fi

}

get_latest_release

daemon_kill

if [ ! -f /home/$COIN_NAME/Update/"$COIN_NAME"d ] || [ ! -f /home/$COIN_NAME/Update/"$COIN_NAME"-cli ]; then

    echo && echo -e "${RED}ERROR: Failed to update $COIN_NAME daemon.${NC}" && echo
    echo "Such "$COIN_NAME"d or "$COIN_NAME"-cli lost on the way or even both." && echo
    echo 'Cleaning bogus, try again, it can be fixed already.' && echo

    rm -rf /home/"$COIN_NAME"/Update/*

    chown -R $COIN_NAME:$COIN_NAME /home/"$COIN_NAME"/*

    exit 1

else

    chown -R $COIN_NAME:$COIN_NAME /home/"$COIN_NAME"/*

    echo && echo -e "${GREEN}$DAEMON and $CLIENT successfuly downloaded.${NC}" && echo

    ls -lah /home/"$COIN_NAME"/Update/ && echo

fi

chmod +x /home/"$COIN_NAME"/Update/*

cd /usr/local/bin/ || exit 1

rm -f $DAEMON $CLIENT

echo && echo "Moving $DAEMON and $CLIENT" && echo

mv /home/"$COIN_NAME"/Update/$COIN_NAME* /usr/local/bin/

rm -f /home/"$COIN_NAME"/Update/*

chown -R $COIN_NAME:$COIN_NAME /usr/local/bin/*

echo -e "${GREEN}$COIN_NAME TEST-NET daemon updated.${NC}" && echo

dogecashd --version | grep 'DogeCash Core Daemon version'
dogecash-cli --version | grep 'DogeCash Core RPC client version' && echo

if ! grep -q 'masternodeprivkey=' $DAEMON_CONFIG; then

    echo -e "${RED}No masternode private key found in $COIN_NAME.conf${NC}" && echo
    echo "docker exec -u 0 -it $CONTAINER_NAME dogecash.sh" && echo

    echo 'To configure peer as a dummy seeder use:'
    echo -e "docker exec -u 0 -it $CONTAINER_NAME ${GREEN}dogecash.sh seed${NC}" && echo

else

    echo "Please review your $COIN_NAME masternode configuration for $CONTAINER_NAME deploy." && echo

    echo "To start $COIN_NAME masternode use this command:" && echo
    echo "docker exec -u $COIN_NAME -it $CONTAINER_NAME run.sh" && echo

fi

echo -e "${GREEN}####################### $COIN_NAME.conf #####################${NC}" && echo
cat $DAEMON_CONFIG
echo -e "${GREEN}#############################################################${NC}" && echo
