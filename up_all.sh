#!/bin/bash
set -e

# Ensure we are operating in the correct directory
cd /opt/core-stack

echo "Creating shared Docker networks..."
docker network create proxy_net 2>/dev/null || true
docker network create db_net 2>/dev/null || true

echo "Starting 01-proxy (Traefik)..."
cd 01-proxy && docker compose --env-file ../.env up -d --wait && cd ..

echo "Starting 02-database (PostgreSQL + Redis)..."
cd 02-database && docker compose --env-file ../.env up -d --wait && cd ..

echo "Starting 03-auth (Authentik)..."
cd 03-auth && docker compose --env-file ../.env up -d --wait && cd ..

echo "Starting 04-management (Dockhand + pgAdmin)..."
cd 04-management && docker compose --env-file ../.env up -d --wait && cd ..

echo "Starting 05-vpn (Netbird)..."
cd 05-vpn && docker compose --env-file ../.env up -d --wait && cd ..

echo "All stacks have been successfully initialized using the .env configuration!"
