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

echo "=== Creating Traefik Network ==="
docker network create traefik || echo "Traefik network already exists"

echo "=== Running TrueNAS Mount Script (if present) ==="
if curl --output /dev/null --silent --head --fail \
  https://raw.githubusercontent.com/mike-ser5/ubuntu-ser5-setup/main/mounts.sh; then
    bash <(curl -s https://raw.githubusercontent.com/mike-ser5/ubuntu-ser5-setup/main/mounts.sh)
else
    echo "No mounts.sh found — skipping TrueNAS mounts."
fi

echo "=== Starting Traefik ==="
cd ~/ubuntu-ser5-setup/traefik
docker compose up -d

echo "=== Starting Immich ==="
cd ~/ubuntu-ser5-setup/immich
docker compose up -d

echo "=== Starting Node-RED ==="
cd ~/ubuntu-ser5-setup/node-red
docker compose up -d

echo "=== SER5 Setup Complete ==="
echo "Node-RED: http://node-red.cobblestone"
echo "Immich:   http://immich.cobblestone"
echo "Traefik:  http://traefik.cobblestone"
