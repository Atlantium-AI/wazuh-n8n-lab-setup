#!/usr/bin/env bash
set -euo pipefail
sudo apt install git

# 0) Check and create the shared network if it doesn't exist
if ! sudo docker network ls | grep -q "soc-net"; then
    echo "Creating soc-net network..."
    sudo docker network create soc-net
else
    echo "soc-net network already exists"
fi

# 1) Kernel setting required by OpenSearch
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee /etc/sysctl.d/99-wazuh.conf >/dev/null
sudo sysctl --system

# 2) Get Wazuh (single-node) at a known-good version
if [ ! -d "wazuh-docker" ]; then
    git clone https://github.com/wazuh/wazuh-docker.git -b v4.12.0
fi
cd wazuh-docker/single-node

# 3) Check if containers already exist
if ! docker ps -a | grep -q "single-node-wazuh.manager-1"; then
    # Generate Indexer certs if not already done
    if [ ! -d "./config/wazuh_indexer_ssl_certs" ]; then
        docker compose -f generate-indexer-certs.yml run --rm generator
    fi

    # 4) Bring up Wazuh stack
    docker compose up -d
else
    echo "Wazuh containers already exist"
fi

# 5) Ensure Wazuh services are connected to the shared network
for s in wazuh.manager wazuh.indexer wazuh.dashboard; do
    container_name="single-node-$s-1"
    if ! docker network inspect soc-net | grep -q "$container_name"; then
        echo "Connecting $container_name to soc-net..."
        docker network connect soc-net "$container_name"
    else
        echo "$container_name already connected to soc-net"
    fi
done

# 6) Spin up n8n if not already running
cd ../../n8n-docker
if ! docker ps -a | grep -q "n8n"; then
    docker compose up -d
else
    echo "n8n container already exists"
fi