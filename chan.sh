#!/usr/bin/env bash

# ~~~ check if a command is available on the system ~~~
check_command() {
    command -v "$1" >/dev/null 2>&1
}

# ~~~ check if socat is installed, if not, install it ~~~
if ! check_command socat; then
    echo "socat is not installed. Installing..."
    if check_command apt; then
        sudo apt update
        sudo apt install -y socat
    elif check_command yum; then
        sudo yum update
        sudo yum install -y socat
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
    if check_command apt-get; then
        sudo apt-get update
        sudo apt-get install -y curl
    elif check_command yum; then
        sudo yum update
        sudo yum install -y curl
    elif check_command brew; then
        brew install curl
    else
        echo "Fuck, unable to install curl. Please install it manually."
        exit 1
    fi
else
    echo "yaay! curl is already installed."
fi

# ~~~ ask for the target and proxy server configuration ~~~
read -p "Enable SSL/TLS (HTTPS) support? (y/n): " enable_ssl
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
trap 'kill $(jobs -p)' SIGINT

# ~~~ wait for the proxy server to start ~~~
sleep 1

# ~~~ perform your web testing by making requests through the proxy ~~~
#echo "Performing a test request through the proxy..."
#curl -x "$proxy_host:$proxy_port" http://localhost

# ~~~ kill the proxy server ~~~
echo "Kill the proxy server..."
kill $(jobs -p)
