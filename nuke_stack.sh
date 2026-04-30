#!/bin/bash
# Total Teardown Script - USE WITH CAUTION

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "⚠️  WARNING: THIS WILL COMPLETELY WIPE YOUR DOCKER STACK ⚠️"
echo "Containers, Networks, Volumes (Databases!), and Images will be deleted."
read -p "Are you absolutely sure you want to proceed? (y/N): " confirm

if [[ "$confirm" != [yY] && "$confirm" != [yY][eE][sS] ]]; then
    echo "Aborted. Your stack is safe."
    exit 1
fi

echo "🔥 Commencing total teardown..."

# Stop and remove stacks in reverse order, including volumes (-v) and images (--rmi all)
declare -a stacks=(
    "05-vpn"
    "04-management"
    "03-auth"
    "02-database"
    "01-proxy"
)

for stack in "${stacks[@]}"; do
    if [ -d "$stack" ] && [ -f "$stack/docker-compose.yml" ]; then
        echo "🛑 Tearing down $stack..."
        cd "$stack"
        docker compose --env-file ../.env down -v --rmi all --remove-orphans || true
        cd ..
    fi
done

echo "🧹 Removing shared networks..."
docker network rm proxy_net 2>/dev/null || true
docker network rm db_net 2>/dev/null || true

echo "🗑️  Pruning any lingering Docker artifacts..."
docker system prune -a --volumes -f

# Reset Traefik's acme.json to prevent cert errors on a fresh start
if [ -f "01-proxy/letsencrypt/acme.json" ]; then
    echo "📄 Clearing old Let's Encrypt certificates..."
    rm -f 01-proxy/letsencrypt/acme.json
    touch 01-proxy/letsencrypt/acme.json
    chmod 600 01-proxy/letsencrypt/acme.json
fi

echo ""
echo "✅ Stack has been completely wiped. You are ready for a clean start."
