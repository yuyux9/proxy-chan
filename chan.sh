#!/usr/bin/env bash

#~BY YUYU FROM 893CREW~

# ----------------------------------
#-COLORZ-
# ----------------------------------
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'

# ~~~ check if a command is available on the system ~~~
check_command() {
    command -v "$1" >/dev/null 2>&1
}

# ~~~ check if socat is installed, if not, install it ~~~
if ! check_command socat; then
    printf "${RED}socat is not installed. Installing...${NOCOLOR}"
    if check_command apt; then
        #sudo apt update
        sudo apt install socat -y 2>/dev/null &
pid=$! # Process Id of the previous running command

spin='-\|/'

i=0
while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\r${spin:$i:1}" " "
  sleep .1
done
    elif check_command yum; then
        #sudo yum update
        sudo yum install -y socat 2>/dev/null &
pid=$! # Process Id of the previous running command

spin='-\|/'

i=0
while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\r${spin:$i:1}" " "
  sleep .1
done
  printf "${GREEN}Successful!${NOCOLOR}"
  echo " "
  echo 'Now you have socat.'
    else
        printf "${RED}Fuck, unable to install socat. Please install it manually.${NOCOLOR}"
        exit 1
    fi
else
    printf "${GREEN}yaay! socat is already installed.${NOCOLOR}"
fi

echo " "

# ~~~ check if curl is installed, if not, install it ~~~
if ! check_command curl; then
    printf "${RED}curl is not installed. Installing...${NOCOLOR}"
    if check_command apt; then
        #sudo apt update
        sudo apt install -qq -y curl 2>/dev/null &
pid=$! # Process Id of the previous running command

spin='-\|/'

i=0
while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\r${spin:$i:1}" " "
  sleep .1
done
  printf "${GREEN}Successful!${NOCOLOR}"
  echo " "
  echo 'Now you have curl.'
    elif check_command yum; then
        sudo yum update
        sudo yum install -y curl 2>/dev/null &
pid=$! # Process Id of the previous running command

spin='-\|/'

i=0
while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\r${spin:$i:1}" " "
  sleep .1
done
    else
        printf "${RED}Fuck, unable to install curl. Please install it manually.${NOCOLOR}"
        exit 1
    fi
else
    printf "${GREEN}yaay! curl is already installed.${NOCOLOR}"
fi

echo " "

# ~~~ ask for the target and proxy server configuration ~~~
read -p "Enable SSL/TLS (HTTPS) support? (y/n): " enable_ssl
read -p "Enter the proxy host: " proxy_host
read -p "Enter the proxy port: " proxy_port
read -p "Enter the target host: " target_host
read -p "Enter the target port: " target_port

echo " "

if [[ $enable_ssl =~ ^[Yy]$ ]]; then
    # ~~~ generate a self-signed SSL certificate ~~~
    openssl req -x509 -newkey rsa:4096 -sha256 -nodes -keyout key.pem -out cert.pem -days 365 -subj "/CN=$target_host"

    # ~~~ start the proxy server with SSL/TLS support ~~~
    echo "Starting the proxy server on $proxy_host:$proxy_port with SSL/TLS support..."
    socat OPENSSL-LISTEN:$proxy_port,cert=cert.pem,key=key.pem,fork PROXY:$target_host:$target_port,proxyport=$proxy_port &
else
    # ~~~ start the proxy server without SSL/TLS support ~~~
    echo "Starting the proxy server on $proxy_host:$proxy_port without SSL/TLS support..."
    socat TCP-LISTEN:$proxy_port,fork PROXY:$target_host:$target_port,proxyport=$proxy_port &
fi

echo " "

 # ~~~ store the process ID (PID) of the proxy server ~~~
    proxy_pid=$!

    # ~~~ capture Ctrl+C to kill the proxy server ~~~
    trap 'echo "Killing the proxy server..." && kill $proxy_pid; exit' SIGINT

    # ~~~ wait for the proxy server to start ~~~
    sleep 1
    
    while :
    do
        printf "${GREEN}Proxy server running. Press Ctrl+C to stop.${NOCOLOR}"
        sleep 1
    done
done
