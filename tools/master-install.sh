#!/bin/bash

# *** DOGECASH MASTER ONELINER ***

# Copyright (C) 2020 Matsuro Hadouken <matsuro-hadouken@protonmail.com>

# This file is free software; as a special exception the author gives
# unlimited permission to copy and/or distribute it, with or without
# modifications, as long as this notice is preserved.

# PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND

COIN_NAME='dogecash'

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then

    echo && echo -e "${RED}ERROR: $0 must be run as root.${NC}" && echo

    exit 1
fi # CHECK ROOT

function ifDocker() {

    if ! [ -x "$(command -v docker)" ]; then

        echo -e "${RED}ERROR: Need to install docker first.${NC}" && echo

        echo "Run this command:"

        echo 'wget -O - https://raw.githubusercontent.com/matsuro-hadouken/doger/master/docker-install.sh | bash'

        exit 1

    fi
} # CHECK IF DOCKER INSTALLED

COIN_NAME='dogecash'
COIN_PORT='56740'

MASTER_CONTAINER_NAME='MASTER'
EXPLORER_WEB='https://explorer.dogec.io/'
EXPLORER_API='https://explorer.dogec.io/api/v2'

COLLATERAL_AMOUNT="500000000000"
COLLATERAL_PRITY='5000'
TIKER='DOGEC'

confirmations_need=3
rotten_tomato=99 # to old transaction, possible collateral lost ( staking, human factor ... )

LFB="unknown"
CONTAINER_HEIGHT="0"

MASTER_CONTAINER_HUB='dogecash/no-prompt-main-master_x64'

re='^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}'
re+='0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))$'
numba='^[0-9]+$'

IPv4_STRING='(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'

function Annotation() {

    clear

    echo && echo -e "${RED}PLEASE READ:${NC}" && echo

    echo -e "${RED}This script is designed for a clean install on Debian or Ubuntu.${NC}."
    echo -e "${RED}It will destroy any other docker data of yours.${NC}" && echo

    echo -e "${GREEN}Advanced users please setup everything manualy according appropriate instruction.${NC}" && echo

    read -rp "Continue ? Ctrl-C to stop or any key to continue."

    clear

    echo && echo -e "${GREEN}Welcome to DogeCash dungeon, lets get started!${NC}" && echo
    echo -e "To become guardian of DogeCash universe every node owner shall attain strong desire." && echo
    echo -e "Open desktop wallet, go to ${GREEN}RECEIVE${NC} tab and create new address." && echo
    echo -e "${CYAN}If you have collateral transaction ID, script also can manage.${NC}" && echo
    echo -e "${RED}Acceptable inputs are:${NC}" && echo
    echo -e "   ${RED}*${NC} Empry Address or"
    echo -e "   ${RED}*${NC} Collateral address with excat $COLLATERAL_PRITY $TIKER or"
    echo -e "   ${RED}*${NC} Collateral transaction ID" && echo
} # ANNOTATION & DOCUMENTATION

function ReadWhatever() { # Assume our user is a dog, we need to return positive collateral TX no meter the cost. Challenge accepted.

    echo

    while true; do # trying to decrease explorer load as much as possible:

        read -rp 'Paste here and press enter: ' user_input

        reference=$(echo "$user_input" | grep -v "^[a-zA-Z0-9 ]*$")

        if [ -n "$reference" ] || [ "${#user_input}" -ne 34 ] && [ "${#user_input}" -ne 64 ]; then # test for bogus

            echo && echo -e "${RED}ERROR: Bogus detected !${NC}" && echo
            echo -e "Seriously, we can only accept collateral ${RED}TX ID${NC} or ${RED}wallet address${NC}, try harder." && echo

        else # if user provide something what theoretially can have sense particle, then:

            if [ "${#user_input}" -eq 34 ]; then # if looks like input:

                echo && echo -e "${GREEN}Using address: $user_input${NC}" && echo

                echo "Validating user input ..." && echo

                CheckBalance $user_input #                            <<< send check balance ...

                echo -e "${GREEN}... OK${NC}" && echo # << Success indicator, address 100% valid and have coolateral amount.

                setterm -cursor on

                sleep 1 && echo 'Looking for transaction ID ...'

                GetTXFromInput $user_input # send input to function, trying to get TX ( explorer )

                if [ "${#collateral_txid}" = 64 ]; then # if we manage to get TX from function somewhere:

                    echo && echo -e "Received transaction ID: ${GREEN}$collateral_txid${NC}"

                    WaitConfirmations # check for confirmations

                    setterm -cursor on

                    break # we got TX, we got enough confirmations , continue without error

                else

                    clear && sleep 1

                    echo && echo -e "${RED}ERROR: TX for $user_input does not return, please try again.${NC}" && echo
                    echo 'This can be explorer error or network glitch.' && echo

                    sleep 6

                fi

            else # If we believe user provide TX, then:

                echo && echo -e "${GREEN}Using transaction ID: $user_input${NC}"

                collateral_txid=$user_input

                WaitConfirmations

                setterm -cursor on

                break # we got TX, we got enough confirmations , continue without error

            fi

        fi

    done

} # MAIN INPUT FUNCTION

function CheckBalance() {

    INPUT_BALANCE=$(curl -s --max-time 15 --connect-timeout 20 $EXPLORER_API/address/"$user_input" | jq .balance | tr -d '"')

    if [[ $INPUT_BALANCE =~ "null" ]]; then # if address doesn't exist

        clear && echo

        echo -e "${RED}ERROR: Address doesn't exist.${NC}" && echo
        echo "Please open explorer web page and check if provided input valid." && echo
        echo "if any issue with explorer, report to developers." && echo

        echo -e "Explorer URL: ${CYAN}$EXPLORER_WEB${NC}" && echo

        exit 1

    fi

    TXS=$(curl -s --max-time 15 --connect-timeout 20 $EXPLORER_API/address/"$user_input" | jq .txs) # get amount of TX

    if [[ $INPUT_BALANCE -eq "$COLLATERAL_AMOUNT" ]] && [[ $TXS -eq "1" ]]; then # Perfect collateral balance.

        DENOMINATION=$(echo $INPUT_BALANCE / 100000000 | jq -nf /dev/stdin)

        echo -ne "${CYAN}Address balance is:${NC} $DENOMINATION $TIKER." && echo

        echo && echo -e "${GREEN}Perfect, absolute collateral input detected.${NC}" && echo

        sleep 1 && return

    fi

    if [[ $INPUT_BALANCE -gt "$COLLATERAL_AMOUNT" ]]; then # error , to much coins on balance, above collateral

        clear && sleep 1

        DENOMINATION=$(echo $INPUT_BALANCE / 100000000 | jq -nf /dev/stdin)

        echo && echo -e "Input balance: ${RED}$DENOMINATION${NC} $TIKER"

        echo && echo -e "${RED}ERROR: Balance is above collateral requirements,${NC} ${CYAN}should be exactly $COLLATERAL_PRITY $TIKER${NC}, ${RED}restarting ...${NC}" && echo

        sleep 8 && clear

        ./"$(basename "$0")" && exit

    fi

    if [[ $INPUT_BALANCE -lt "$COLLATERAL_AMOUNT" ]] && [[ $INPUT_BALANCE -ne "0" ]]; then # error , not enough coins and not empty

        clear && sleep 1

        DENOMINATION=$(echo $INPUT_BALANCE / 100000000 | jq -nf /dev/stdin)

        echo && echo -e "Input balance: ${RED}$DENOMINATION${NC} $TIKER"

        echo && echo -e "${RED}ERROR: Balance is below collateral requirements,${NC} ${CYAN}should be exactly $COLLATERAL_PRITY $TIKER${NC}, ${RED}restarting ...${NC}" && echo

        setterm -cursor on

        sleep 8 && clear

        ./"$(basename "$0")" && exit
    fi

    if [[ $TXS -ne "0" ]]; then # weird address provided

        clear && sleep 1

        echo && echo -e "${RED}ERROR: Provided address been used before, we kindly ask to create a new one.${NC}"

        DENOMINATION=$(echo $INPUT_BALANCE / 100000000 | jq -nf /dev/stdin)

        echo && echo -e "Input balance: ${GREEN}$DENOMINATION${NC} $TIKER"

        echo -e "Amount of transactions on this input: ${RED}$TXS${NC}" && echo

        echo "Restarting script, please try again." && echo

        setterm -cursor on

        sleep 8 && clear

        ./"$(basename "$0")" && exit

    fi

    if [[ $INPUT_BALANCE -eq "0" ]]; then # if empty input

        echo -e "${GREEN}Valid empty input detected, please send exact${NC} ${RED}$COLLATERAL_PRITY $TIKER${NC} ${GREEN}to the address you just provide.${NC}" && echo

        echo -e "${RED}Waiting for transaction ...${NC}" && echo

        setterm -cursor off

        until [[ $INPUT_BALANCE -eq "$COLLATERAL_AMOUNT" ]]; do # loop untill we get exact collateral amount or error

            INPUT_BALANCE=$(curl -s --max-time 15 --connect-timeout 20 $EXPLORER_API/address/"$user_input" | jq .balance | tr -d '"')

            DENOMINATION=$(echo $INPUT_BALANCE / 100000000 | jq -nf /dev/stdin)

            echo -ne "${CYAN}Address balance is:${NC} $DENOMINATION $TIKER.\\r"

            if [[ $INPUT_BALANCE -eq "$COLLATERAL_AMOUNT" ]]; then # sucess collateral arrived

                DENOMINATION=$(echo $INPUT_BALANCE / 100000000 | jq -nf /dev/stdin)

                echo -ne "${CYAN}Address balance is:${NC} $DENOMINATION $TIKER."

                echo && echo -e "${GREEN}Perfect, absolute collateral input detected.${NC}" && echo

                sleep 3 && setterm -cursor on

                break

            fi

            if [[ $INPUT_BALANCE -gt "$COLLATERAL_AMOUNT" ]]; then # to many coins send error

                clear

                echo && echo -e "${RED}Incoming transaction, address balance: $INPUT_BALANCE" && echo

                echo "Such to much $TIKER, should be exactly $COLLATERAL_PRITY $TIKER, restarting everything ..." && echo

                setterm -cursor on

                sleep 8 && clear

                ./"$(basename "$0")" && exit

            fi

            if [[ $INPUT_BALANCE -lt "$COLLATERAL_AMOUNT" ]] && [[ $INPUT_BALANCE -ne "0" ]]; then # not enough send error

                clear

                echo && echo -e "${RED}Incoming transaction, address balance: $INPUT_BALANCE" && echo

                echo "This is not enough $TIKER, should be exactly $COLLATERAL_PRITY $TIKER, restarting everything ..." && echo

                setterm -cursor on

                sleep 8 && clear

                ./"$(basename "$0")" && exit

            fi

            sleep 5 # API request interval

        done

    fi

} # CHECK BALANCE CONDITION

function GetTXFromInput() { # call utility ( not finished, work in progress )

    INPUT_BALANCE=$(curl -s --max-time 15 --connect-timeout 20 $EXPLORER_API/address/$user_input | jq .balance | tr -d '"')

    if ! [[ "$INPUT_BALANCE" =~ "500000000000" ]]; then

        echo && echo 'ERROR: We need new address with exact 5000 DogeCash as collateral balance, please try again.' && echo

        ReadWhatever # send back for the input

    else

        collateral_txid=$(curl -s --max-time 15 --connect-timeout 20 $EXPLORER_API/address/$user_input | jq -r .txids | tr -d ' []"' | grep -Ev "^$")

    fi

} # GET TRANSACTION ID FROM PROVIDED 'ADDRESS'

function WaitConfirmations() {

    setterm -cursor off

    confirmations=$(curl -s --max-time 15 --connect-timeout 20 $EXPLORER_API/tx/"$collateral_txid" | jq '.' | grep '"confirmations":' | tr -d 'confirmats":  ,')

    if ! [[ $confirmations =~ $numba ]]; then

        echo && echo -e "${RED}ERROR: Possible invalid transaction ID, please double check on explorer.${NC}" && echo
        echo "If explorer offline, report to developers." && echo

        echo $EXPLORER_WEB && echo

        sleep 1

        setterm -cursor on

        exit 1

    fi

    if ! [[ $confirmations -gt $confirmations_need ]]; then

        echo && echo -e "${GREEN}Waiting for at least $confirmations_need confirmations ...${NC}" && echo

        until [[ $confirmations -gt $confirmations_need ]]; do

            confirmations=$(curl -s --max-time 15 --connect-timeout 20 $EXPLORER_API/tx/"$collateral_txid" | jq '.' | grep '"confirmations":' | tr -d 'confirmats":  ,')

            echo -ne "Confirmed: $confirmations time.\\r"

            sleep 6

        done

        echo "Such fast block chain!" && echo

    else

        if [[ $confirmations -ge $rotten_tomato ]]; then

            echo && echo -e "${CYAN}WARNING:${NC} $confirmations confirmations, transaction slightly old, maybe is a good idea to recreate."

            CollateralIndex

        else

            echo && echo -e "Transaction confirmed ${GREEN}$confirmations${NC} times, which is more then enough."

            CollateralIndex

        fi

    fi

    setterm -cursor on

} # CHECK OR WAIT FOR CONFIRMATIONS

function CollateralIndex() {

    collateral_index=$(curl -s --max-time 15 --connect-timeout 20 $EXPLORER_API/tx/"$collateral_txid" | jq '.vout' | grep 'value' | head -1 | tr -d '"value": ,')

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

    echo && echo -e "${GREEN}     ALL DATA VALID !${NC}"
    echo -e "${CYAN}--------------------------${NC}"
    echo -e "Collateral transaction ID: ${RED}$collateral_txid${NC}"
    echo -e "Collateral Index: ${RED}$collateral_index${NC}                ${GREEN}^^${NC} If you provide TX as input still time to double check"
    echo -e "Confirmed: ${RED}$confirmations${NC}"
   
    echo -e "${CYAN}--------------------------${NC}"

    sleep 2

} # GET COLLATERAL INDEX '0 || 1'

function ReadMasternodePrivateKey() {

    echo && echo -e "${GREEN}Now we should generate masternode private key.${NC}" && echo
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

} # READ MASTERNODE PRIVATE KEY

function ReadExternalIP() {

    echo && echo -e "Trying to get external IP from couple of services ..." && echo

    amazon_aws=$(curl -s --max-time 10 --connect-timeout 15 https://checkip.amazonaws.com) || amazon_aws='dead pipe'
    ifconfig_me=$(curl -s --max-time 10 --connect-timeout 15 https://ifconfig.me) || ifconfig_me='dead pipe'
    ident_me=$(curl -s --max-time 10 --connect-timeout 15 https://ident.me) || ident_me='dead pipe'

    echo -e "${GREEN}amazonaws.com report: ${NC} $amazon_aws"
    echo -e "${GREEN}ifconfig.me report:   ${NC} $ifconfig_me"
    echo -e "${GREEN}ident.me report:      ${NC} $ident_me" && echo

    echo -e "${GREEN}Using${NC} ${RED}IPv4${NC} ${GREEN}from the output above${NC} ${RED}^^${NC}" && sleep 1

    array=($amazon_aws $ifconfig_me $ident_me)

    remove=(dead pipe) #s

    for target in "${remove[@]}"; do
        for i in "${!array[@]}"; do
            if [[ ${array[i]} = $target ]]; then
                unset 'array[i]'
            fi
        done
    done

    EXTERNAL_IP=$(echo "${array[@]}" | awk '{for(i=1;i<=NF;i++) print $i}' | awk '!x[$0]++' | grep -E -o $IPv4_STRING | head -n 1)

    if ! [[ $EXTERNAL_IP =~ $re ]]; then

        echo -e "${RED}Can't get external VPS IP automatically, only manual input possible." && echo

        while true; do

            read -rp 'VPS external IP: ' EXTERNAL_IP

            ipv4_check=$(echo $EXTERNAL_IP | grep -E -o $IPv4_STRING)

            if [[ $EXTERNAL_IP =~ $re ]]; then

                break

            else

                echo && echo -e "${RED}Invalid IPv4 address format, try again.${NC}" && echo

            fi

        done
    fi

} # READ EXTERNAL IP

function PrintInputs() {

    echo && echo -e "${RED}Private key:${NC} $PRIVAT_KEY"
    echo -e "${RED}External IP address:${NC} $EXTERNAL_IP"

    echo

    read -rp "Is this correct ? Ctrl-C to stop or any key to continue."

} # PRINT COLLECTED DATA

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

} # INSTALL NODE

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

} # WAIT FOR NODE SYNC

function InstallationSuccessPrint() {

    echo && echo -e "${GREEN}Container syncronized with network.${NC}" && echo
    echo -e "${GREEN}Network last finalized block:${NC} $LFB"
    echo -e "${GREEN}Container best height:${NC}        $CONTAINER_HEIGHT" && echo

    echo "Add this line in to your DESKTOP masternode.conf:" && echo

    echo -e "${GREEN}$MASTER_CONTAINER_NAME $EXTERNAL_IP:$COIN_PORT${NC} ${RED}$PRIVAT_KEY${NC} $collateral_txid $collateral_index" && echo

    echo -e "${GREEN}About now, masternode can be started from your desktop computer.${NC}" && echo

    echo -e "${RED}If everything works in the end, you will never ever need to run this script again.${NC}" && echo

    echo -e "${GREEN}Good luck.${NC}" && echo

} # PRINT BLAH IF INSTALLATION SUCCEED

function MasternodeStatusCheck() {

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

} # CHECK IF NODE STARTED AND FULLY FUNCTIONAL

ifDocker

Annotation

ReadWhatever

ReadMasternodePrivateKey

ReadExternalIP

PrintInputs

InstallMaster

WaitForSync

InstallationSuccessPrint

MasternodeStatusCheck
