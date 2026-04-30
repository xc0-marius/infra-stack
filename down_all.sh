#!/bin/bash
set -e

echo "Bringing down all Docker Core Stack services..."

# Stop each stack in reverse order (VPN first, proxy last)
echo "Stopping 05-vpn (Netbird)..."
if [ -d "05-vpn" ]; then
  cd 05-vpn && docker compose --env-file ../.env down && cd ..
fi

echo "Stopping 04-management (Dockhand + pgAdmin)..."
if [ -d "04-management" ]; then
  cd 04-management && docker compose --env-file ../.env down && cd ..
fi

echo "Stopping 03-auth (Authentik)..."
if [ -d "03-auth" ]; then
  cd 03-auth && docker compose --env-file ../.env down && cd ..
fi

echo "Stopping 02-database (PostgreSQL + Redis)..."
if [ -d "02-database" ]; then
  cd 02-database && docker compose --env-file ../.env down && cd ..
fi

echo "Stopping 01-proxy (Traefik)..."
if [ -d "01-proxy" ]; then
  cd 01-proxy && docker compose --env-file ../.env down && cd ..
fi

echo ""
echo "All stacks stopped successfully."
echo "To remove volumes (WARNING: DATA LOSS), run: ./stop_all.sh --volumes"
