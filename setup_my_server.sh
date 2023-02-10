#!/bin/bash
set -e
HC='\033[1;32m'
NC='\033[0m'
echo "Setting up the server..."
read -e -p " [?] Enter your domain or subdomain: " MYDOMAIN
MYDOMAIN=$(echo "$MYDOMAIN" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
[[ -z "$MYDOMAIN" ]] && { echo "Error: Domain URL is needed."; exit 1; }

echo -e "\n$HC+$NC Checking IP <=> Domain..."
apt update
apt-get install -y dnsutils
RESIP=$(dig +short "$MYDOMAIN" | grep '^[.0-9]*$' || echo 'NONE')
SRVIP=$(curl -qs http://checkip.amazonaws.com  | grep '^[.0-9]*$' || echo 'NONE')

if [ "$RESIP" = "$SRVIP" ]; then
    echo -e "\n$HC+$NC $RESIP => $MYDOMAIN is valid."
else
    echo -e "\033[1;31m -- Error: \033[0m Server IP is $HC$SRVIP$NC but '$MYDOMAIN' resolves to \033[1;31m$RESIP$NC\n"
    echo -e "If you have just updated the DNS record, wait a few minutes and then try again. \n"
    exit;
fi

PANEL_USER=$(cat /dev/urandom | tr -dc '[:alpha:]' | fold -w ${1:-12} | head -n 1)
PANEL_PORT=$(shuf -i 2023-64999 -n1)
PANEL_PASS=$(cat /dev/urandom | tr -dc '[:alpha:]0-9' | fold -w ${1:-40} | head -n 1)

echo "Setting up the TLS..."
apt-get install -y certbot
certbot certonly --standalone -d $MYDOMAIN --register-unsafely-without-email --non-interactive --agree-tos
cp -r /etc/letsencrypt ./cert/

echo "building container..."
apt install -y docker docker-compose
docker-compose up -d --build
echo "setting up finished now you can get to your panel from $MYDOMAIN:54321 ----- username: admin and password: admin you should change this setting in panel settings"
