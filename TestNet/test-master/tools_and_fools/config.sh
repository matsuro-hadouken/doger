#!/bin/bash

# *** TEST NET ***

# Copyright (C) 2020 Matsuro Hadouken <matsuro-hadouken@protonmail.com>

# This file is free software; as a special exception the author gives
# unlimited permission to copy and/or distribute it, with or without
# modifications, as long as this notice is preserved.

# PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND

# NOT FOR TEST NET, WORK IN PROGRESS.

COIN_NAME='dogecash'

CONTAINER_NAME='MASTER'

PEERS_TXT='peers.txt'

PEERS_URL="https://www.dropbox.com/s/s0pdil1rehsy4fu/$PEERS_TXT"

DEBUG_LOG=/home/"$COIN_NAME"/."$COIN_NAME"/debug.log
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

if [ -z "$1" ] || [ -z "$2" ]; then

  echo && echo 'ERROR: Not enough parameters !' && echo
  echo "docker exec -u 0 -it $CONTAINER_NAME config.sh MASTERNODE_PRIV_KEY EXTERNAL_IP" && echo
  echo 'To get IP use <curl ifconfig.m> or <ifconfig>' && echo
  echo 'If this ^^ does not work: [apt install net-tools] or [apt install curl]' && echo

  exit 1

fi

echo
read -rp "CHECK CONTAINER NAME !!! Ctrl-C to stop or any key to continue."

if [ ! -f $DAEMON_CONFIG ]; then
  touch $DAEMON_CONFIG
fi

function daemon_kill() {

  if ! [[ $DAEMON_PID =~ $numba ]]; then

    echo && echo 'Cheking if daemon process is active ...'

    sleep 1

    echo && echo 'No numba PID return, such possible daemon dead, good.' && echo

  else

    echo && echo 'Daemon online, destroy ...'

    kill -2 "$DAEMON_PID"

    sleep 4

    echo && echo 'Daemon dead, such much fun !' && echo

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

function add_peers() {

  echo 'Add top notch peers in to configuration ...' && echo

  sleep 1

  rm -f /home/$COIN_NAME/.$COIN_NAME/peers.txt* 2>/dev/null

  if grep -q 'addnode=' $DAEMON_CONFIG; then

    {
      echo && echo 'Removing old addnode entries ...' && echo

      sleep 1

      sed -i '/addnode=/d' $DAEMON_CONFIG
    }

  fi

  cd /home/$COIN_NAME/.$COIN_NAME/ || exit 1

  wget --no-check-certificate "$PEERS_URL" -q --show-progress --progress=bar:force 2>&1 || echo "ERROR: Connection with dropbox failed."

  cat /home/$COIN_NAME/.$COIN_NAME/$PEERS_TXT >>$DAEMON_CONFIG

  rm -f /home/$COIN_NAME/.$COIN_NAME/$PEERS_TXT* 2>/dev/null

}

daemon_kill

cat "$CONFIG_HEADER" >"$DAEMON_CONFIG"

rpc_add

echo "masternodeprivkey=$1" >>$DAEMON_CONFIG && echo >>$DAEMON_CONFIG
echo "PRIVATE KEY ADDED TO: $DAEMON_CONFIG" && echo
cat $DAEMON_CONFIG | grep 'masternodeprivkey=' && echo
echo "externalip=$2" >>$DAEMON_CONFIG && echo >>$DAEMON_CONFIG
cat $DAEMON_CONFIG | grep 'externalip=' && echo

add_peers

chown -R $COIN_NAME:$COIN_NAME /home/"$COIN_NAME"/."$COIN_NAME"/*

echo && echo && cat $DAEMON_CONFIG && echo

echo "Please review your $COIN_NAME masternode configuration." && echo
echo "To instantly sync $COIN_NAME masternode run snapshot ( recommended )" && echo
echo "docker exec -u $COIN_NAME -it $CONTAINER_NAME $COIN_NAME.sh PRIV_KEY EXTERNAL_IP" && echo
echo 'Or start sync from scratch, ( it will take hours and probably fork in the end )' && echo
echo "docker exec -u $COIN_NAME -it $CONTAINER_NAME run.sh" && echo
echo 'Good luck !' && echo
