#!/bin/bash
# Complete .env Generator - Interactive Script
# Save as: generate_complete_env.sh

set -e

echo "🔐 Docker Core Stack - Complete .env Generator"
echo "=============================================="

# Interactive prompts
read -s -p "Enter base password for PGAdmin/Postgres (hidden): " BASE_PASS
echo
read -s -p "Enter Authentik secret key (64+ chars, or Enter for random): " AUTH_SECRET
echo

# Generate secure passwords
if [ -z "$AUTH_SECRET" ]; then
  AUTH_SECRET=$(LC_ALL=C tr -dc 'A-Za-z0-9_.-' < /dev/urandom | head -c 64)
fi

POSTGRES_PASS="${BASE_PASS}$(LC_ALL=C tr -dc 'A-Za-z0-9_.-' < /dev/urandom | head -c 16)"
PGADMIN_PASS="${BASE_PASS}$(LC_ALL=C tr -dc 'A-Za-z0-9_.-' < /dev/urandom | head -c 16)"

# Ensure we're in the right directory
cd /opt/core-stack || { echo "❌ Not in /opt/core-stack"; exit 1; }

# Backup existing .env
cp .env .env.backup 2>/dev/null || true

# Replace ALL fields in .env
cat > .env << EOF
# Docker Core Stack - Auto-generated .env
# Generated: $(date)

# Domain & Paths
DOMAIN=ktown.gg
BASE_DIR=/opt/core-stack

# Traefik / SSL
ACME_EMAIL=admin@ktown.gg
DESEC_TOKEN=AmJv5iu1CAn5GmadEYP6XkM1CD1e

# Database Configuration
POSTGRES_USER=admin
POSTGRES_PASSWORD=${POSTGRES_PASS}

# pgAdmin Configuration
PGADMIN_DEFAULT_EMAIL=admin@ktown.gg
PGADMIN_DEFAULT_PASSWORD=${PGADMIN_PASS}

# Authentik Configuration
AUTHENTIK_SECRET_KEY=${AUTH_SECRET}
EOF

echo "✅ .env file completely regenerated!"
echo ""
echo "📝 Your passwords to remember:"
echo "   PGAdmin/Postgres base: $BASE_PASS"
echo ""
echo "🔒 .env file contents (masked):"
grep -E "(POSTGRES_PASSWORD|PGADMIN_DEFAULT_PASSWORD|AUTHENTIK_SECRET_KEY)" .env | \
sed 's/\(^[A-Z_]*=\)\([^ ]*\)/\1\2: \1*****/'
echo ""
echo "📁 Backup saved as .env.backup"
echo "🚀 Ready to run ./start_all.sh"
