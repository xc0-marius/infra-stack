#!/usr/bin/env bash
# up_all.sh — Start all infra-stack stacks in dependency order.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo "Creating shared Docker networks (idempotent)..."
docker network create proxy_net 2>/dev/null || true
docker network create db_net   2>/dev/null || true

echo ""
echo "Starting 01-proxy (Traefik)..."
cd 01-proxy && docker compose --env-file ../.env up -d --wait && cd ..

echo "Starting 02-database (PostgreSQL + Redis)..."
cd 02-database && docker compose --env-file ../.env up -d --wait && cd ..

echo "Starting 03-auth (Authentik)..."
cd 03-auth && docker compose --env-file ../.env up -d --wait && cd ..

echo "Starting 04-frontends (Dockhand + pgAdmin)..."
cd 04-frontends && docker compose --env-file ../.env up -d --wait && cd ..

echo "Starting 05-vpn (NetBird)..."
cd 05-vpn && docker compose --env-file ../.env up -d --wait && cd ..

echo ""
echo "All stacks are up."
