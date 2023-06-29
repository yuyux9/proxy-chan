#!/usr/bin/env bash

# ~~~ check if a command is available on the system ~~~
check_command() {
    command -v "$1" >/dev/null 2>&1
}

# ~~~ check if pv is installed, if not, install it ~~~
if ! check_command pv; then
    echo "pv is not installed. Installing..."
    if check_command apt; then
        sudo apt update
        sudo apt install -qq -y pv >/dev/null
    elif check_command yum; then
        sudo yum update
        sudo yum install -y pv >/dev/null
    else
        echo "Fuck, unable to install pv. Please install it manually."
        exit 1
    fi
else
    echo "yaay! pv is already installed."
fi

# ~~~ check if socat is installed, if not, install it ~~~
if ! check_command socat; then
    echo "socat is not installed. Installing..."
    if check_command apt; then
        sudo apt update
        sudo apt install -qq -y socat | pv -l >/dev/null
    elif check_command yum; then
        sudo yum update
        sudo yum install -y socat | pv -l >/dev/null
    else
        echo "Fuck, unable to install socat. Please install it manually."
        exit 1
    fi
else
    echo "yaay! socat is already installed."
fi

# ~~~ check if curl is installed, if not, install it ~~~
if ! check_command curl; then
    echo "curl is not installed. Installing..."
    if check_command apt; then
        sudo apt update
        sudo apt install -qq -y curl | pv -l >/dev/null
    elif check_command yum; then
        sudo yum update
        sudo yum install -y curl | pv -l >/dev/null
    else
        echo "Fuck, unable to install curl. Please install it manually."
        exit 1
    fi
else
    echo "yaay! curl is already installed."
fi

# ~~~ ask for the target and proxy server configuration ~~~
read -p "Enable SSL/TLS (HTTPS) support? (y/n): " enable_ssl
read -p "Enter the proxy host: " proxy_host
read -p "Enter the proxy port: " proxy_port
read -p "Enter the target host: " target_host
read -p "Enter the target port: " target_port
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

    # ~~~ capture Ctrl+C to kill the proxy server ~~~
    trap 'kill $(jobs -p); exit' SIGINT

    # ~~~ wait for the proxy server to start ~~~
    sleep 1
    
    while :
    do
        echo "Proxy server running. Press Ctrl+C to stop."
        sleep 1
    done

    # ~~~ kill the proxy server ~~~
    echo "Killing the proxy server..."
    kill $(jobs -p)
done
