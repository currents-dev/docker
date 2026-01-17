#!/bin/bash
#
# Wait for MongoDB to be healthy (authenticated and replica set ready)
#
# Usage: ./wait-for-mongodb.sh [max_attempts]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ON_PREM_DIR="$SCRIPT_DIR/../.."

MAX_ATTEMPTS="${1:-60}"

cd "$ON_PREM_DIR"

# Load credentials from .env
source .env

echo "Waiting for MongoDB to be healthy..." >&2
for i in $(seq 1 "$MAX_ATTEMPTS"); do
    # Check that authentication works and replica set is PRIMARY
    # This matches what the container healthcheck verifies
    if docker compose -f docker-compose.full.yml exec -T mongodb mongosh \
        -u "$MONGODB_USERNAME" -p "$MONGODB_PASSWORD" --authenticationDatabase admin \
        --quiet --eval "rs.status().myState === 1" 2>/dev/null | grep -q true; then
        echo "✅ MongoDB is ready (authenticated, replica set PRIMARY)" >&2
        exit 0
    fi
    echo "Attempt $i/$MAX_ATTEMPTS - MongoDB not ready yet..." >&2
    sleep 2
done

echo "❌ MongoDB failed to start" >&2
docker compose -f docker-compose.full.yml logs mongodb >&2
exit 1
