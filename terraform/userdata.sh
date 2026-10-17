#!/bin/bash
set -e

# Update packages
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release git

# Setup 2GB Swap using dd (never fails on ext4/gp3)
dd if=/dev/zero of=/swapfile bs=1M count=2048
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# Install Docker & Docker Compose Plugin
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# Clone Repository
cd /home/ubuntu
git clone https://github.com/tb-repo/E-CommerceStore.git app
cd /home/ubuntu/app

# Build backend services first, then frontend to prevent any build contention
docker compose build user-service product-service cart-service order-service
docker compose build frontend

# Launch all services
docker compose up -d