#!/usr/bin/env bash
set -e

echo "=== SER5 Setup: System Update ==="
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl htop net-tools ca-certificates gnupg

echo "=== Disabling Sleep (Immich ML requires this) ==="
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

echo "=== Installing Docker Engine + Compose ==="
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER

echo "=== Creating Docker Folder Structure ==="
mkdir -p ~/docker/{node-red,immich,traefik}
mkdir -p ~/docker/traefik/dynamic

echo "=== Downloading Node-RED Compose ==="
curl -o ~/docker/node-red/docker-compose.yml \
  https://raw.githubusercontent.com/mike-ser5/ubuntu-ser5-setup/main/node-red/docker-compose.yml

echo "=== Downloading Immich Compose ==="
curl -o ~/docker/immich/docker-compose.yml \
  https://raw.githubusercontent.com/mike-ser5/ubuntu-ser5-setup/main/immich/docker-compose.yml

echo "=== Downloading Traefik Compose ==="
curl -o ~/docker/traefik/docker-compose.yml \
  https://raw.githubusercontent.com/mike-ser5/ubuntu-ser5-setup/main/traefik/docker-compose.yml

echo "=== Downloading Traefik Dynamic Configs ==="
curl -o ~/docker/traefik/dynamic/node-red.yml \
  https://raw.githubusercontent.com/mike-ser5/ubuntu-ser5-setup/main/traefik/dynamic/node-red.yml

curl -o ~/docker/traefik/dynamic/immich.yml \
  https://raw.githubusercontent.com/mike-ser5/ubuntu-ser5-setup/main/traefik/dynamic/immich.yml

curl -o ~/docker/traefik/dynamic/dashboard.yml \
  https://raw.githubusercontent.com/mike-ser5/ubuntu-ser5-setup/main/traefik/dynamic/dashboard.yml

echo "=== Running TrueNAS Mount Script (if present) ==="
if curl --output /dev/null --silent --head --fail \
  https://raw.githubusercontent.com/mike-ser5/ubuntu-ser5-setup/main/mounts.sh; then
    bash <(curl -s https://raw.githubusercontent.com/mike-ser5/ubuntu-ser5-setup/main/mounts.sh)
else
    echo "No mounts.sh found — skipping TrueNAS mounts."
fi

echo "=== Starting Traefik ==="
cd ~/docker/traefik && docker compose up -d

echo "=== Starting Node-RED ==="
cd ~/docker/node-red && docker compose up -d

echo "=== Starting Immich ==="
cd ~/docker/immich && docker compose up -d

echo "=== SER5 Setup Complete ==="
echo "Node-RED: https://node-red.cobblestone"
echo "Immich:   https://immich.cobblestone"
echo "Traefik:  https://traefik.cobblestone"
