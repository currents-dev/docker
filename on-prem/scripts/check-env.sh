#!/bin/bash
#
# Check for missing environment variables
# Compares .env against .env.example to find variables that may need to be added
#
# Usage:
#   ./scripts/check-env.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ON_PREM_DIR="$SCRIPT_DIR/.."

ENV_FILE="$ON_PREM_DIR/.env"
EXAMPLE_FILE="$ON_PREM_DIR/.env.example"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Run ./scripts/setup.sh first to create your .env file"
    exit 1
fi

if [ ! -f "$EXAMPLE_FILE" ]; then
    echo -e "${RED}Error: .env.example file not found${NC}"
    exit 1
fi

echo "Checking for missing environment variables..."
echo ""

MISSING=()
COMMENTED=()

while IFS= read -r line || [ -n "$line" ]; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$line" ]] && continue
    
    # Extract variable name (handle lines with or without values)
    var_name=$(echo "$line" | cut -d'=' -f1 | tr -d '[:space:]')
    
    # Skip if empty
    [ -z "$var_name" ] && continue
    
    # Check if variable exists in .env (either set or commented)
    if grep -q "^${var_name}=" "$ENV_FILE" 2>/dev/null; then
        continue
    elif grep -q "^#.*${var_name}=" "$ENV_FILE" 2>/dev/null; then
        COMMENTED+=("$var_name")
    else
        MISSING+=("$var_name")
    fi
done < "$EXAMPLE_FILE"

if [ ${#MISSING[@]} -eq 0 ] && [ ${#COMMENTED[@]} -eq 0 ]; then
    echo -e "${GREEN}All environment variables are present in .env${NC}"
    exit 0
fi

if [ ${#MISSING[@]} -gt 0 ]; then
    echo -e "${RED}Missing variables (not in .env):${NC}"
    for var in "${MISSING[@]}"; do
        echo "  - $var"
    done
    echo ""
    echo "To add missing variables, copy them from .env.example:"
    echo "  grep 'VARIABLE_NAME' .env.example >> .env"
    echo ""
    # Also show commented variables before exiting if any
    if [ ${#COMMENTED[@]} -gt 0 ]; then
        echo -e "${YELLOW}Commented variables (may need review):${NC}"
        for var in "${COMMENTED[@]}"; do
            echo "  - $var"
        done
        echo ""
    fi
    exit 1
fi

if [ ${#COMMENTED[@]} -gt 0 ]; then
    echo -e "${YELLOW}Commented variables (may need review):${NC}"
    for var in "${COMMENTED[@]}"; do
        echo "  - $var"
    done
    echo ""
fi

exit 0
