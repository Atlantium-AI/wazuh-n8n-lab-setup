#!/usr/bin/env bash
set -euo pipefail

# 0) Create the shared network
docker network create soc-net

# 1) Kernel setting required by OpenSearch
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee /etc/sysctl.d/99-wazuh.conf >/dev/null
sudo sysctl --system

# 2) Get Wazuh (single-node) at a known-good version
git clone https://github.com/wazuh/wazuh-docker.git -b v4.12.0
cd wazuh-docker/single-node

# 3) Generate Indexer certs
docker compose -f generate-indexer-certs.yml run --rm generator

# 4) Bring up Wazuh stack
docker compose up -d

# 5) Attach Wazuh services to the shared network
for s in wazuh.manager wazuh.indexer wazuh.dashboard; do
  docker network connect soc-net "single-node-$s-1"
done

# 6) Spin up n8n (expects ../../n8n-docker to exist and contain your compose file)
cd ../../n8n-docker
docker compose up -d


