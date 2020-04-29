#!/bin/bash

# Docker installation, Debian and Ubuntu

function check_condition() {

    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root." 1>&2
        exit 1
    fi

    if [ -x "$(command -v docker)" ]; then

        echo 'Docker is already installed on your system.'
        echo 'Check for updates if neccessary.'
        echo ''

        exit 1

    fi

    if ! uname -m | grep -q 'x86_64'; then

        {

            echo 'ERROR: Designed for x86_64 architecture.'

            exit 1

        }

    fi

}

clear

cat <<EOL

DogeCash Docker Installer:

Debian and Ubuntu x86_64 only supported, If you on different OS,
then use DuckDuckGo search for instruction on how to install
docker for your distribution.

EOL

sleep 3

function debian_installation() {

    read -rp "Docker Debian installation. Ctrl-C to stop or any key to continue."

    sudo apt-get update

    sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common

    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

    sudo apt-get update

    sudo apt-get -y install docker-ce

    docker -v || exit 1

}

function ubuntu_installation() {

    read -rp "Docker Ubuntu installaton. Ctrl-C to stop or any key to continue."

    sudo apt-get update

    sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    sudo apt-get update

    sudo apt-get -y install docker-ce

    docker -v || exit 1

}

check_condition

awk -F= '/^NAME/{print $2}' /etc/os-release | grep Debian

if [ $? == 0 ]; then
    {
        debian_installation
    }
else
    ubuntu_installation
fi
