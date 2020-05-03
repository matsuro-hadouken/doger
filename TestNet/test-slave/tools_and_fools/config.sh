#!/bin/bash

# *** SLAVE CONFIGURATION ***

# Copyright (C) 2020 Matsuro Hadouken <matsuro-hadouken@protonmail.com>

# This file is free software; as a special exception the author gives
# unlimited permission to copy and/or distribute it, with or without
# modifications, as long as this notice is preserved.

# PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND

# NOT FOR TEST NET, WORK IN PROGRESS.

COIN_NAME='dogecash'

CONTAINER_NAME='SLAVE_NAME'

DEBUG_LOG=/home/"$COIN_NAME"/."$COIN_NAME"/debug.log
DAEMON_CONFIG="/home/$COIN_NAME/.$COIN_NAME/$COIN_NAME.conf"

CONFIG_HEADER="/home/$COIN_NAME/header.txt"

numba='^[0-9]+$'
DAEMON_PID=$(pidof "$COIN_NAME"d)

if [ -z "$1" ]; then

  echo
  echo 'Please provide masternode private key, bye ...'
  echo
  echo "docker exec -u 0 -it $CONTAINER_NAME config.sh <MASTERNODE_PRIVATE_KEY>"
  echo

  exit 1
fi

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

daemon_kill

cat "$CONFIG_HEADER" >"$DAEMON_CONFIG"

rpc_add

echo "masternodeprivkey=$1" >>$DAEMON_CONFIG && echo >>$DAEMON_CONFIG
echo "PRIVATE KEY ADDED TO: $DAEMON_CONFIG" && echo
cat $DAEMON_CONFIG | grep 'masternodeprivkey=' && echo

chown -R $COIN_NAME:$COIN_NAME /home/"$COIN_NAME"/."$COIN_NAME"/*

echo && echo && cat $DAEMON_CONFIG && echo

echo "Please review your $COIN_NAME masternode configuration." && echo
echo "To instantly sync $COIN_NAME masternode run snapshot ( recommended )" && echo
echo "docker exec -u $COIN_NAME -it $CONTAINER_NAME $COIN_NAME.sh PRIV_KEY" && echo
echo 'Or start sync from scratch, ( it will take hours and probably fork in the end )' && echo
echo "docker exec -u $COIN_NAME -it $CONTAINER_NAME run.sh" && echo ''
echo 'Good luck !' && echo
