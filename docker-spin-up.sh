# Create the shared network first if not already made
docker network create soc-net

# Start Wazuh
cd ./wazuh-docker/single-node
sudo docker compose up -d
cd ../../n8n-docker
sudo docker compose up -d



