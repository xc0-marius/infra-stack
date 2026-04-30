#!/usr/bin/env bash
# down_all.sh — Stop all infra-stack stacks in reverse dependency order.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo "Bringing down all infra-stack services..."
echo ""

for stack in 05-vpn 04-frontends 03-auth 02-database 01-proxy; do
  if [[ -d "${stack}" ]]; then
    echo "Stopping ${stack}..."
    cd "${stack}" && docker compose --env-file ../.env down && cd ..
  else
    echo "[SKIP] ${stack} directory not found"
  fi
done

echo ""
echo "All stacks stopped."
echo "To also remove named volumes (WARNING: DATA LOSS): add --volumes to each docker compose down call."
