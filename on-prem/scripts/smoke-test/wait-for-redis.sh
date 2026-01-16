#!/bin/bash
#
# Wait for Redis to be ready
#
# Usage: ./wait-for-redis.sh [max_attempts]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ON_PREM_DIR="$SCRIPT_DIR/../.."

MAX_ATTEMPTS="${1:-30}"

cd "$ON_PREM_DIR"

echo "Waiting for Redis to be ready..."
for i in $(seq 1 $MAX_ATTEMPTS); do
    if docker compose -f docker-compose.full.yml exec -T redis redis-cli ping 2>/dev/null | grep -q PONG; then
        echo "✅ Redis is ready"
        exit 0
    fi
    echo "Attempt $i/$MAX_ATTEMPTS - Redis not ready yet..."
    sleep 2
done

echo "❌ Redis failed to start"
docker compose -f docker-compose.full.yml logs redis
exit 1
