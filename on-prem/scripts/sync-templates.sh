#!/bin/bash
#
# Regenerate the committed docker-compose files from templates
# Run this after modifying any template files
#
# Usage:
#   ./scripts/sync-templates.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Regenerating docker-compose files from templates..."

"$SCRIPT_DIR/generate-compose.sh" full
"$SCRIPT_DIR/generate-compose.sh" database
"$SCRIPT_DIR/generate-compose.sh" cache

echo ""
echo "Done! The following files have been updated:"
echo "  - docker-compose.full.yml"
echo "  - docker-compose.database.yml"
echo "  - docker-compose.cache.yml"

