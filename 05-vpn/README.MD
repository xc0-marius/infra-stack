# Docker with docker-compose plugin (Docker installation guide) or Docker with docker-compose version 2 or higher
# jq - install with sudo apt install jq or sudo yum install jq
# curl - install with sudo apt install curl or sudo yum install curl

# Run Quick Start script in stack folder
curl -fsSL https://github.com/netbirdio/netbird/releases/latest/download/getting-started.sh | bash

# Generated Files:
# The script generates the following files:
# Docker Compose configuration with all services
docker-compose.yml
# Combined server configuration (management, signal, relay, STUN)
config.yaml
# Environment variables for the dashboard container
dashboard.env
# Environment variables for the proxy container (only when proxy is enabled)
proxy.env

# For options 2-4, additional configuration files are generated (e.g., nginx-netbird.conf, caddyfile-netbird.txt, or npm-advanced-config.txt).

#See an example config.yaml file in the NetBird GitHub repository for a complete configuration example.
#Initial setup (Onboarding)

# The script deploys NetBird without any users. Once complete, you'll need to create your first user:
