#!/bin/bash
#
# Wait for root user to be created by scheduler
#
# Usage: ./wait-for-root-user.sh [max_attempts]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ON_PREM_DIR="$SCRIPT_DIR/../.."

MAX_ATTEMPTS="${1:-30}"

cd "$ON_PREM_DIR"
source .env

echo "Waiting for root user to be created..."
for i in $(seq 1 $MAX_ATTEMPTS); do
    if docker compose -f docker-compose.full.yml exec -T mongodb mongosh \
        -u "$MONGODB_USERNAME" -p "$MONGODB_PASSWORD" --authenticationDatabase admin \
        --quiet --eval "db.getSiblingDB('currents').user.findOne({email: '${ON_PREM_EMAIL:-root@currents.local}'})" 2>/dev/null | grep -q "_id"; then
        echo "✅ Root user exists"
        exit 0
    fi
    echo "Attempt $i/$MAX_ATTEMPTS - Root user not created yet..."
    sleep 2
done

echo "❌ Root user was not created"
docker compose -f docker-compose.full.yml logs api scheduler
exit 1
