#!/bin/bash
#
# Wait for MongoDB to be healthy
#
# Usage: ./wait-for-mongodb.sh [max_attempts]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ON_PREM_DIR="$SCRIPT_DIR/../.."

MAX_ATTEMPTS="${1:-60}"

cd "$ON_PREM_DIR"

echo "Waiting for MongoDB to be healthy..." >&2
for i in $(seq 1 "$MAX_ATTEMPTS"); do
    if docker compose -f docker-compose.full.yml exec -T mongodb mongosh --quiet --eval "db.runCommand('ping').ok" localhost:27017 2>/dev/null | grep -q 1; then
        echo "✅ MongoDB is ready" >&2
        exit 0
    fi
    echo "Attempt $i/$MAX_ATTEMPTS - MongoDB not ready yet..." >&2
    sleep 2
done

echo "❌ MongoDB failed to start" >&2
docker compose -f docker-compose.full.yml logs mongodb >&2
exit 1
