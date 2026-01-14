#!/bin/bash
#
# Interactive setup script for Currents on-prem
# Generates a docker-compose file based on your infrastructure choices
# and sets it as the default docker-compose.yml
#
# Usage:
#   ./setup.sh              # Interactive setup (profile selection + env generation)
#   ./setup.sh --env-only   # Only generate .env file with secrets (non-interactive)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ON_PREM_DIR="$SCRIPT_DIR/.."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
ENV_ONLY=false
FORCE_REGEN=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --env-only)
            ENV_ONLY=true
            shift
            ;;
        --force)
            FORCE_REGEN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --env-only    Only generate .env file with secrets (non-interactive)"
            echo "  --force       Force regenerate secrets even if .env exists"
            echo "  -h, --help    Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# =============================================================================
# Environment file setup
# =============================================================================
# Define setup_env_file function first (used by both modes)
setup_env_file() {
    cd "$ON_PREM_DIR"
    
    if [ -f .env ]; then
        echo -e "${YELLOW}Found existing .env file${NC}"
        if [ "$FORCE_REGEN" = true ]; then
            echo "Force regenerating secrets..."
        elif [ "$ENV_ONLY" = true ]; then
            # Non-interactive mode: skip if .env exists and --force not set
            echo "Using existing .env file (use --force to regenerate secrets)"
            return
        else
            read -p "Regenerate secrets in .env? [y/N]: " regen_secrets
            if [[ ! $regen_secrets =~ ^[Yy] ]]; then
                return
            fi
        fi
        ENV_FILE=".env"
    else
        echo "Creating .env file from .env.example..."
        cp .env.example .env
        ENV_FILE=".env"
    fi
    
    echo "Generating secrets..."
    
    # Generate BETTER_AUTH_SECRET
    BETTER_AUTH_SECRET=$("$SCRIPT_DIR/generate-secrets.sh" token 64)
    if grep -q "^BETTER_AUTH_SECRET=" "$ENV_FILE"; then
        sed -i.bak "s|^BETTER_AUTH_SECRET=.*|BETTER_AUTH_SECRET=$BETTER_AUTH_SECRET|" "$ENV_FILE"
    fi
    
    # Generate API_SECRET
    API_SECRET=$("$SCRIPT_DIR/generate-secrets.sh" token 64)
    if grep -q "^API_SECRET=" "$ENV_FILE"; then
        sed -i.bak "s|^API_SECRET=.*|API_SECRET=$API_SECRET|" "$ENV_FILE"
    fi
    
    # Generate ON_PREM_PASSWORD (initial admin user password)
    ON_PREM_PASSWORD=$("$SCRIPT_DIR/generate-secrets.sh" token 32)
    if grep -q "^ON_PREM_PASSWORD=" "$ENV_FILE"; then
        sed -i.bak "s|^ON_PREM_PASSWORD=.*|ON_PREM_PASSWORD=$ON_PREM_PASSWORD|" "$ENV_FILE"
    fi
    
    # Generate RUSTFS_SECRET_KEY
    RUSTFS_SECRET=$("$SCRIPT_DIR/generate-secrets.sh" token 32)
    if grep -q "^RUSTFS_SECRET_KEY=" "$ENV_FILE"; then
        sed -i.bak "s|^RUSTFS_SECRET_KEY=.*|RUSTFS_SECRET_KEY=$RUSTFS_SECRET|" "$ENV_FILE"
    fi
    
    # Generate CLICKHOUSE_DEFAULT_PASSWORD
    CLICKHOUSE_DEFAULT=$("$SCRIPT_DIR/generate-secrets.sh" token 32)
    if grep -q "^CLICKHOUSE_DEFAULT_PASSWORD=" "$ENV_FILE"; then
        sed -i.bak "s|^CLICKHOUSE_DEFAULT_PASSWORD=.*|CLICKHOUSE_DEFAULT_PASSWORD=$CLICKHOUSE_DEFAULT|" "$ENV_FILE"
    fi
    
    # Generate CLICKHOUSE_CURRENTS_PASSWORD
    CLICKHOUSE_CURRENTS=$("$SCRIPT_DIR/generate-secrets.sh" token 32)
    if grep -q "^CLICKHOUSE_CURRENTS_PASSWORD=" "$ENV_FILE"; then
        sed -i.bak "s|^CLICKHOUSE_CURRENTS_PASSWORD=.*|CLICKHOUSE_CURRENTS_PASSWORD=$CLICKHOUSE_CURRENTS|" "$ENV_FILE"
    fi
    
    # Generate MONGODB_PASSWORD
    MONGODB_PASS=$("$SCRIPT_DIR/generate-secrets.sh" token 32)
    if grep -q "^MONGODB_PASSWORD=" "$ENV_FILE"; then
        sed -i.bak "s|^MONGODB_PASSWORD=.*|MONGODB_PASSWORD=$MONGODB_PASS|" "$ENV_FILE"
    fi
    
    # Generate GITLAB_STATE_SECRET (RSA private key, base64 encoded)
    GITLAB_KEY_FILE="$ON_PREM_DIR/.gitlab-key.pem"
    if [ ! -f "$GITLAB_KEY_FILE" ]; then
        "$SCRIPT_DIR/generate-secrets.sh" key ".gitlab-key.pem" > /dev/null
    fi
    GITLAB_SECRET=$(base64 < "$GITLAB_KEY_FILE" | tr -d '\n')
    if grep -q "^GITLAB_STATE_SECRET=" "$ENV_FILE"; then
        sed -i.bak "s|^GITLAB_STATE_SECRET=.*|GITLAB_STATE_SECRET=$GITLAB_SECRET|" "$ENV_FILE"
    fi
    
    # Clean up backup files created by sed
    rm -f "$ENV_FILE.bak"
    
    echo -e "${GREEN}✓ Secrets generated and saved to .env${NC}"
}

# =============================================================================
# Handle --env-only mode
# =============================================================================
if [ "$ENV_ONLY" = true ]; then
    setup_env_file
    echo -e "${GREEN}✓ Environment setup complete!${NC}"
    exit 0
fi

# =============================================================================
# Interactive mode: Profile selection
# =============================================================================
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           Currents On-Prem Setup                          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo "This script will help you generate a docker-compose configuration"
echo "based on which services you want to run locally vs externally."
echo ""

echo -e "${YELLOW}Select a configuration profile:${NC}"
echo ""
echo "  1) full      - All services (redis, mongodb, clickhouse, rustfs)"
echo "                 Use when running everything locally"
echo ""
echo "  2) database  - Database services (redis, mongodb, clickhouse)"
echo "                 Use when you have external S3-compatible storage"
echo ""
echo "  3) cache     - Cache only (redis)"
echo "                 Use when you have external MongoDB, ClickHouse, and S3"
echo ""
echo "  4) custom    - Build a custom configuration"
echo "                 Select individual services to include"
echo ""

read -p "Enter choice [1-4] (default: 2): " choice
choice=${choice:-2}

case $choice in
    1)
        PROFILE="full"
        ;;
    2)
        PROFILE="database"
        ;;
    3)
        PROFILE="cache"
        ;;
    4)
        # Custom configuration
        echo ""
        echo -e "${YELLOW}Select services to include:${NC}"
        SERVICES=""
        
        read -p "Include Redis (cache/pub-sub)? [Y/n]: " include_redis
        include_redis=${include_redis:-Y}
        if [[ $include_redis =~ ^[Yy] ]]; then
            SERVICES="$SERVICES redis"
        fi
        
        read -p "Include MongoDB (primary database)? [Y/n]: " include_mongo
        include_mongo=${include_mongo:-Y}
        if [[ $include_mongo =~ ^[Yy] ]]; then
            SERVICES="$SERVICES mongodb"
        fi
        
        read -p "Include ClickHouse (analytics)? [Y/n]: " include_clickhouse
        include_clickhouse=${include_clickhouse:-Y}
        if [[ $include_clickhouse =~ ^[Yy] ]]; then
            SERVICES="$SERVICES clickhouse"
        fi
        
        read -p "Include RustFS (S3-compatible storage)? [y/N]: " include_rustfs
        include_rustfs=${include_rustfs:-N}
        if [[ $include_rustfs =~ ^[Yy] ]]; then
            SERVICES="$SERVICES rustfs"
        fi
        
        if [ -z "$SERVICES" ]; then
            echo -e "${RED}Error: No services selected. At least one service is required.${NC}"
            exit 1
        fi
        
        # Convert services to profile name
        PROFILE=$(echo $SERVICES | tr ' ' '-' | sed 's/^-//')
        
        echo ""
        echo "Generating custom configuration with:$SERVICES"
        "$SCRIPT_DIR/generate-compose.sh" $SERVICES
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

# Generate the compose file (unless custom already did it)
if [ "$choice" != "4" ]; then
    echo ""
    echo "Generating docker-compose.$PROFILE.yml..."
    "$SCRIPT_DIR/generate-compose.sh" $PROFILE
fi

# Update symlink
COMPOSE_FILE="docker-compose.${PROFILE}.yml"
echo ""
echo "Setting docker-compose.yml -> $COMPOSE_FILE"
cd "$ON_PREM_DIR"
ln -sf "$COMPOSE_FILE" docker-compose.yml

# Setup .env file
echo ""
setup_env_file

echo ""
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "Your configuration:"
echo "  Profile: $PROFILE"
echo "  File: $COMPOSE_FILE"
echo "  Symlink: docker-compose.yml -> $COMPOSE_FILE"
echo ""
echo "Next steps:"
echo "  1. Review and customize .env as needed"
echo "  2. Run: docker compose up -d"
echo ""
