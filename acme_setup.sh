#!/usr/bin/env bash
# acme_setup.sh
# Creates all host directories, touches required files with correct permissions,
# and ensures the external Docker networks exist.
# Run once on the host before bringing up any stack.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Load .env ─────────────────────────────────────────────────────────────────
if [[ ! -f "${SCRIPT_DIR}/.env" ]]; then
  echo "[ERROR] .env not found at ${SCRIPT_DIR}/.env"
  exit 1
fi

set -a
# shellcheck source=.env
source "${SCRIPT_DIR}/.env"
set +a

echo "[INFO] BASE_DIR = ${BASE_DIR}"
echo "[INFO] DOMAIN   = ${DOMAIN}"

# ── Helpers ───────────────────────────────────────────────────────────────────
make_dir() {
  local dir="$1"
  local mode="${2:-755}"
  mkdir -p "${dir}"
  chmod "${mode}" "${dir}"
  echo "[DIR]  ${dir}  (${mode})"
}

touch_file() {
  local file="$1"
  local mode="${2:-600}"
  # Only touch if the file does not already have content
  if [[ ! -s "${file}" ]]; then
    touch "${file}"
    chmod "${mode}" "${file}"
    echo "[FILE] ${file}  (${mode})"
  else
    # File exists and has content — only enforce permissions
    chmod "${mode}" "${file}"
    echo "[FILE] ${file}  already populated, permissions set to ${mode}"
  fi
}

make_net() {
  local net="$1"
  if ! docker network inspect "${net}" &>/dev/null 2>&1; then
    docker network create "${net}"
    echo "[NET]  created ${net}"
  else
    echo "[NET]  ${net} already exists, skipping"
  fi
}

# ── 01-proxy ──────────────────────────────────────────────────────────────────
echo ""
echo "==> 01-proxy"
make_dir   "${BASE_DIR}/01-proxy/letsencrypt"
# acme.json MUST be 600 — Traefik refuses to start if permissions are wrong
touch_file "${BASE_DIR}/01-proxy/letsencrypt/acme.json" 600

# ── 03-auth ───────────────────────────────────────────────────────────────────
echo ""
echo "==> 03-auth"
make_dir "${BASE_DIR}/03-auth/media"
make_dir "${BASE_DIR}/03-auth/custom-templates"
make_dir "${BASE_DIR}/03-auth/certs"

# ── 05-vpn ────────────────────────────────────────────────────────────────────
echo ""
echo "==> 05-vpn"
make_dir   "${BASE_DIR}/05-vpn/data/management"
# config.json is mounted read-only into netbird-server — populate before starting
touch_file "${BASE_DIR}/05-vpn/config.json" 600

# ── Docker networks ───────────────────────────────────────────────────────────
echo ""
echo "==> Docker networks"
make_net proxy_net
make_net db_net

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "[OK] All directories, files, and networks are ready."
echo ""
echo "Reminders:"
echo "  - Fill in all ***changeme*** values in ${SCRIPT_DIR}/.env before starting."
echo "  - Populate ${BASE_DIR}/05-vpn/config.json with your NetBird management"
echo "    config before starting 05-vpn (run the NetBird getting-started.sh to"
echo "    generate it, then copy the result here)."
