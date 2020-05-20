#!/bin/bash

# Docker installation, Debian and Ubuntu

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

function check_condition() {

    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}This script must be run as root.${NC}" 1>&2
        exit 1
    fi

    if [ -x "$(command -v docker)" ]; then

        echo -e "${GREEN}Docker is already installed on your system.${NC}" && echo

        docker -v || exit 1

        echo && echo 'Check for updates if neccessary.' && echo

        exit 1

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

check_condition

clear

cat <<EOL

DogeCash Docker Installer:

Debian and Ubuntu x86_64 only supported, If you on different OS,
then use DuckDuckGo.com, search for instruction on how to install
docker for your distribution.

EOL

sleep 3

distro
