#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

function inputs() {

    while true; do

        read -p 'Masternode private key: ' PRIVAT_KEY

        short=${PRIVAT_KEY:0:2}

        if [[ $short =~ 56 ]] || [[ $short =~ 57 ]]; then

            break

        else

            echo && echo -e "${RED}Invalid private key format, try again.${NC}" && echo

        fi

    done

    echo "VALIDE KEY"
}

inputs
