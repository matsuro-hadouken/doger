#!/bin/bash

# Docker installation, Debian and Ubuntu

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

COIN_NAME='dogecash'

START_SRT='https://raw.githubusercontent.com/matsuro-hadouken/doger/master/tools/start.sh'

function if_Root() {

    if [ "$(id -u)" != "0" ]; then
        echo && echo -e "${RED}This script must be run as root.${NC}" 1>&2 && echo
        exit 1
    fi
}

function annotation() {

    clear && echo

    cat <<EOL

DogeCash Docker Installer:

Debian and Ubuntu x86_64 only supported, If you on different OS,
then use DuckDuckGo.com, search for instruction on how to install
docker for your distribution.

EOL

    echo
    read -rp 'Ctrl-C to stop or any key to continue.'

}

function requirements() {

    echo && echo -e "${GREEN}Checking and install required packages ...${NC}" && echo

    REQUIRED_PKG="jq"

    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG | grep "install ok installed")
    echo Checking for $REQUIRED_PKG: $PKG_OK

    if [ "" = "$PKG_OK" ]; then
        echo "No $REQUIRED_PKG installed. Setting up $REQUIRED_PKG."
        apt-get --yes install $REQUIRED_PKG
    fi

    REQUIRED_PKG="git"

    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG | grep "install ok installed")
    echo Checking for $REQUIRED_PKG: $PKG_OK

    if [ "" = "$PKG_OK" ]; then
        echo "No $REQUIRED_PKG installed. Setting up $REQUIRED_PKG."
        apt-get --yes install $REQUIRED_PKG
    fi

    REQUIRED_PKG="curl"

    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG | grep "install ok installed")
    echo Checking for $REQUIRED_PKG: $PKG_OK

    if [ "" = "$PKG_OK" ]; then
        echo "No $REQUIRED_PKG installed. Setting up $REQUIRED_PKG."
        apt-get --yes install $REQUIRED_PKG
    fi

    REQUIRED_PKG="wget"

    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG | grep "install ok installed")
    echo Checking for $REQUIRED_PKG: $PKG_OK

    if [ "" = "$PKG_OK" ]; then
        echo "No $REQUIRED_PKG installed. Setting up $REQUIRED_PKG."
        apt-get --yes install $REQUIRED_PKG
    fi

}

function environment() {

    mkdir -p $HOME/"$COIN_NAME"-utils
    rm -f $HOME/"$COIN_NAME"-utils/*

    cd $HOME/"$COIN_NAME"-utils || exit 1

    echo && echo -e "${GREEN}Pulling utility scripts from GitHub ...${NC}" && echo

    wget --no-check-certificate "$START_SRT" -q --show-progress --progress=bar:force 2>&1

    chmod -R 700 $HOME/"$COIN_NAME"-utils/

    echo

}

function if_Docker() {

    if [ -x "$(command -v docker)" ]; then

        echo -e "${GREEN}Docker is already installed on your system.${NC}" && echo

        docker -v || exit 1

        echo && echo 'Check for updates if neccessary.' && echo

        success

    fi

    if ! uname -m | grep -q 'x86_64'; then

        {
            echo -e "${RED}ERROR: Designed for x86_64 architecture.${NC}"
            exit 1
        }

    fi

}

function debian_installation() {

    read -rp "Docker Debian installation. Ctrl-C to stop or any key to continue."

    sudo apt-get update

    sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common gnupg2

    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

    sudo apt-get update

    sudo apt-get -y install docker-ce

    echo

    docker -v || exit 1

    echo && echo -e "${GREEN}Docker successfully installed on your system.${NC}" && echo

}

function ubuntu_installation() {

    read -rp "Docker Ubuntu installaton. Ctrl-C to stop or any key to continue."

    sudo apt-get update

    sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common gnupg2

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    sudo apt-get update

    sudo apt-get -y install docker-ce

    echo

    docker -v || exit 1

    echo && echo -e "${GREEN}Docker successfully installed on your system.${NC}" && echo

}

function distro() {

    if (awk -F= '/^NAME/{print $2}' /etc/os-release | grep -q -o Debian); then

        debian_installation

    fi

    if (awk -F= '/^NAME/{print $2}' /etc/os-release | grep -q -o Ubuntu); then

        ubuntu_installation

    else

        echo && echo -e "${RED}You using different operation system which are not supported by this installation script.${NC}" && echo

        exit 1

    fi

}

function success() {

    echo && echo -e "go to utils directory ${GREEN}cd $HOME/"$COIN_NAME"-utils/${NC} and start installation by ${GREEN}./start.sh${NC}" && echo

    exit 0
}

if_Root

annotation

requirements

environment

if_Docker

clear

sleep 3

distro

success
