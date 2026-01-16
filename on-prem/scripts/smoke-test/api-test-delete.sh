#!/bin/bash
#
# API smoke test - Delete action
# Deletes (archives) an action by ID
#
# Usage: ./api-test-delete.sh <api_key> <action_id>
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ON_PREM_DIR="$SCRIPT_DIR/../.."

API_KEY="${1:-}"
ACTION_ID="${2:-}"
API_BASE_URL="${API_BASE_URL:-http://localhost:4000/v1}"

# Function to show logs on failure
show_logs_on_failure() {
    echo ""
    echo "=========================================="
    echo "API container logs (last 100 lines):"
    echo "=========================================="
    cd "$ON_PREM_DIR"
    docker compose -f docker-compose.full.yml logs --tail=100 api
    echo "=========================================="
}

if [ -z "$API_KEY" ]; then
    echo "❌ Error: API key is required"
    echo "Usage: $0 <api_key> <action_id>"
    exit 1
fi

if [ -z "$ACTION_ID" ]; then
    echo "❌ Error: Action ID is required"
    echo "Usage: $0 <api_key> <action_id>"
    exit 1
fi

echo "Deleting action: $ACTION_ID..."

DELETE_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "${API_BASE_URL}/actions/${ACTION_ID}" \
  -H "Authorization: Bearer ${API_KEY}")

HTTP_CODE=$(echo "$DELETE_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$DELETE_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" != "200" ]; then
    echo "❌ Failed to delete action (HTTP $HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
    show_logs_on_failure
    exit 1
fi

echo "✅ Action deleted (archived)"
