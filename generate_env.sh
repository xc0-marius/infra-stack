#!/usr/bin/env bash
# generate_env.sh
# Interactively generates the root .env for infra-stack.
# Run once from the repo root before acme_setup.sh and up_all.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

echo "🔐  infra-stack — .env Generator"
echo "================================="
echo ""

# ── Helpers ────────────────────────────────────────────────────────────────────
ask() {
  # ask <VAR> <prompt> [default]
  local var="$1" prompt="$2" default="${3:-}"
  local value=""
  if [[ -n "${default}" ]]; then
    read -rp "  ${prompt} [${default}]: " value
    value="${value:-${default}}"
  else
    while [[ -z "${value}" ]]; do
      read -rp "  ${prompt}: " value
    done
  fi
  printf -v "${var}" '%s' "${value}"
}

ask_secret() {
  # ask_secret <VAR> <prompt>  (hidden input, no default)
  local var="$1" prompt="$2"
  local value=""
  while [[ -z "${value}" ]]; do
    read -rsp "  ${prompt}: " value
    echo
  done
  printf -v "${var}" '%s' "${value}"
}

rand() {
  # rand <length>
  LC_ALL=C tr -dc 'A-Za-z0-9_.-' < /dev/urandom | head -c "${1}"
}

# ── Prompts ────────────────────────────────────────────────────────────────────
echo "── General ───────────────────────────────────────────────────────────────"
ask        DOMAIN          "Domain"                      "ktown.gg"
ask        BASE_DIR        "Host base directory"         "/opt/docker/infrastack"
ask        ACME_EMAIL      "ACME / Let's Encrypt email"  "admin@${DOMAIN}"

echo ""
echo "── Traefik / deSEC DNS ───────────────────────────────────────────────────"
ask_secret DESEC_TOKEN     "deSEC API token"

echo ""
echo "── Database ──────────────────────────────────────────────────────────────"
ask        POSTGRES_USER   "Postgres username"           "admin"
ask_secret POSTGRES_PASSWORD "Postgres password (Enter for random)"
if [[ -z "${POSTGRES_PASSWORD}" ]]; then
  POSTGRES_PASSWORD="$(rand 32)"
  echo "  → generated: ${POSTGRES_PASSWORD}"
fi

echo ""
echo "── pgAdmin ───────────────────────────────────────────────────────────────"
ask        PGADMIN_DEFAULT_EMAIL    "pgAdmin email"   "admin@${DOMAIN}"
ask_secret PGADMIN_DEFAULT_PASSWORD "pgAdmin password (Enter for random)"
if [[ -z "${PGADMIN_DEFAULT_PASSWORD}" ]]; then
  PGADMIN_DEFAULT_PASSWORD="$(rand 32)"
  echo "  → generated: ${PGADMIN_DEFAULT_PASSWORD}"
fi

echo ""
echo "── Authentik ─────────────────────────────────────────────────────────────"
read -rsp "  Authentik secret key (Enter for random 64-char): " AUTHENTIK_SECRET_KEY
echo
if [[ -z "${AUTHENTIK_SECRET_KEY}" ]]; then
  AUTHENTIK_SECRET_KEY="$(rand 64)"
  echo "  → generated (64 chars)"
fi

echo ""
echo "── NetBird VPN ───────────────────────────────────────────────────────────"
echo "  OIDC issuer URL from Authentik, e.g. https://auth.${DOMAIN}/application/o/netbird/"
ask        NETBIRD_AUTH_AUTHORITY  "OIDC authority URL"
ask        NETBIRD_AUTH_CLIENT_ID  "OAuth2 client ID (from Authentik)"
ask        NETBIRD_TURN_EXTERNAL_IP "VPS public IPv4 (for coturn)"
ask        NETBIRD_TURN_USER        "TURN username"   "netbird"
ask_secret NETBIRD_TURN_PASSWORD    "TURN password (Enter for random)"
if [[ -z "${NETBIRD_TURN_PASSWORD}" ]]; then
  NETBIRD_TURN_PASSWORD="$(rand 32)"
  echo "  → generated: ${NETBIRD_TURN_PASSWORD}"
fi

# ── Write .env ─────────────────────────────────────────────────────────────────
if [[ -f "${ENV_FILE}" ]]; then
  cp "${ENV_FILE}" "${ENV_FILE}.backup"
  echo ""
  echo "  Existing .env backed up to .env.backup"
fi

cat > "${ENV_FILE}" <<EOF
# infra-stack — root .env
# Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')
# DO NOT commit this file to version control.

DOMAIN=${DOMAIN}
BASE_DIR=${BASE_DIR}

# Traefik / SSL
ACME_EMAIL=${ACME_EMAIL}
DESEC_TOKEN=${DESEC_TOKEN}

# Database Configuration
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

# pgAdmin Configuration
PGADMIN_DEFAULT_EMAIL=${PGADMIN_DEFAULT_EMAIL}
PGADMIN_DEFAULT_PASSWORD=${PGADMIN_DEFAULT_PASSWORD}

# Authentik Configuration
AUTHENTIK_SECRET_KEY=${AUTHENTIK_SECRET_KEY}
AUTHENTIK_ALLOWED_HOSTS=auth.${DOMAIN}
AUTHENTIK_LOG_LEVEL=info
AUTHENTIK_ERROR_REPORTING__ENABLED=false
AUTHENTIK_POSTGRESQL__PASSWORD_FROM_ENV=true
AUTHENTIK_REDIS__HOST_FROM_ENV=true
AUTHENTIK_ALLOWED_PROXY_HOSTS=traefik

# NetBird VPN Configuration
# NETBIRD_AUTH_AUTHORITY: full OIDC issuer URL (Authentik: https://auth.${DOMAIN}/application/o/netbird/)
NETBIRD_AUTH_AUTHORITY=${NETBIRD_AUTH_AUTHORITY}
# NETBIRD_AUTH_CLIENT_ID: OAuth2 client ID created in Authentik for NetBird
NETBIRD_AUTH_CLIENT_ID=${NETBIRD_AUTH_CLIENT_ID}
# NETBIRD_TURN_EXTERNAL_IP: the public IPv4 of your Hetzner VPS
NETBIRD_TURN_EXTERNAL_IP=${NETBIRD_TURN_EXTERNAL_IP}
NETBIRD_TURN_USER=${NETBIRD_TURN_USER}
NETBIRD_TURN_PASSWORD=${NETBIRD_TURN_PASSWORD}
EOF

echo ""
echo "✅  .env written to ${ENV_FILE}"
echo ""
echo "Next steps:"
echo "  1. chmod +x acme_setup.sh && sudo ./acme_setup.sh"
echo "  2. Populate ${BASE_DIR}/05-vpn/config.json with your NetBird management config"
echo "  3. ./up_all.sh"
