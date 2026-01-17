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
    echo "" >&2
    echo "==========================================" >&2
    echo "API container logs (last 100 lines):" >&2
    echo "==========================================" >&2
    cd "$ON_PREM_DIR"
    docker compose -f docker-compose.full.yml logs --tail=100 api >&2
    echo "==========================================" >&2
}

if [ -z "$API_KEY" ]; then
    echo "❌ Error: API key is required" >&2
    echo "Usage: $0 <api_key> <action_id>" >&2
    exit 1
fi

if [ -z "$ACTION_ID" ]; then
    echo "❌ Error: Action ID is required" >&2
    echo "Usage: $0 <api_key> <action_id>" >&2
    exit 1
fi

echo "Deleting action: $ACTION_ID..." >&2

RESPONSE_FILE=$(mktemp)
trap 'rm -f "$RESPONSE_FILE"' EXIT

HTTP_CODE=$(curl -s -o "$RESPONSE_FILE" -w "%{http_code}" -X DELETE "${API_BASE_URL}/actions/${ACTION_ID}" \
  -H "Authorization: Bearer ${API_KEY}")

RESPONSE_BODY=$(cat "$RESPONSE_FILE")

if [ "$HTTP_CODE" != "200" ]; then
    echo "❌ Failed to delete action (HTTP $HTTP_CODE)" >&2
    echo "Response: $RESPONSE_BODY" >&2
    show_logs_on_failure
    exit 1
fi

echo "✅ Action deleted (archived)" >&2
