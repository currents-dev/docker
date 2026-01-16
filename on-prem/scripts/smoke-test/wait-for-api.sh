#!/bin/bash
#
# Wait for API to be ready
#
# Usage: ./wait-for-api.sh [max_attempts]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ON_PREM_DIR="$SCRIPT_DIR/../.."

MAX_ATTEMPTS="${1:-60}"

cd "$ON_PREM_DIR"

echo "Waiting for API to be ready..."
for i in $(seq 1 $MAX_ATTEMPTS); do
    if curl -sf http://localhost:4000/health > /dev/null 2>&1; then
        echo "✅ API is ready"
        exit 0
    fi
    echo "Attempt $i/$MAX_ATTEMPTS - API not ready yet..."
    sleep 2
done

echo "❌ API failed to start"
docker compose -f docker-compose.full.yml logs api
exit 1
