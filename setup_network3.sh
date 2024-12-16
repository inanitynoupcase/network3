#!/bin/bash

# Check input parameters
if [ -z "$1" ]; then
  echo "Please provide an email as: ./setup_network3.sh <email>"
  exit 1
fi

EMAIL=$1

# 1. Install Docker and Docker Compose
install_docker() {
  echo "Installing Docker..."
  wget -q https://get.docker.com/ -O docker.sh
  sudo sh docker.sh

  echo "Installing Docker Compose..."
  sudo apt-get update
  sudo apt-get install -y docker-compose-plugin
}

# Check if Docker is already installed
if ! command -v docker &> /dev/null; then
  install_docker
else
  echo "Docker is already installed."
fi

# 2. Create directory and docker-compose.yml file
WORKDIR=~/network3
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# 3. Create docker-compose.yml file
cat > docker-compose.yml <<EOF
version: '3.3'

services:
  network3-1:
    image: aron666/network3-ai
    container_name: network3-1
    environment:
      - EMAIL=$EMAIL
    ports:
      - 8080:8080/tcp
    volumes:
      - "/root/network3/docker/wireguard:/usr/local/etc/wireguard"
    healthcheck:
      test: curl -fs http://localhost:8080/ || exit 1
      interval: 30s
      timeout: 5s
      retries: 5
      start_period: 30s
    privileged: true
    devices:
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
    restart: always

  autoheal:
    restart: always
    image: willfarrell/autoheal
    container_name: autoheal
    environment:
      - AUTOHEAL_CONTAINER_LABEL=all
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
EOF

# 4. Set permissions for the directory
sudo chmod -R 755 "$WORKDIR"

# 5. Start Network3 node
echo "Starting Network3 node..."
docker compose up -d

# 6. Check container status
docker compose ps

echo "Done. Network3 node has been installed and started."
