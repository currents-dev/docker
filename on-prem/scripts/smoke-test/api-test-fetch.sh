#!/bin/bash
#
# API smoke test - Fetch action
# Fetches an action by ID and verifies it exists
#
# Usage: ./api-test-fetch.sh <api_key> <action_id> [expected_name]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ON_PREM_DIR="$SCRIPT_DIR/../.."

API_KEY="${1:-}"
ACTION_ID="${2:-}"
EXPECTED_NAME="${3:-}"
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
    echo "Usage: $0 <api_key> <action_id> [expected_name]" >&2
    exit 1
fi

if [ -z "$ACTION_ID" ]; then
    echo "❌ Error: Action ID is required" >&2
    echo "Usage: $0 <api_key> <action_id> [expected_name]" >&2
    exit 1
fi

echo "Fetching action: $ACTION_ID..." >&2

RESPONSE_FILE=$(mktemp)
trap 'rm -f "$RESPONSE_FILE"' EXIT

HTTP_CODE=$(curl -s -o "$RESPONSE_FILE" -w "%{http_code}" "${API_BASE_URL}/actions/${ACTION_ID}" \
  -H "Authorization: Bearer ${API_KEY}")

RESPONSE_BODY=$(cat "$RESPONSE_FILE")

if [ "$HTTP_CODE" != "200" ]; then
    echo "❌ Failed to fetch action (HTTP $HTTP_CODE)" >&2
    echo "Response: $RESPONSE_BODY" >&2
    show_logs_on_failure
    exit 1
fi

FETCHED_NAME=$(echo "$RESPONSE_BODY" | jq -r '.data.name')
FETCHED_STATUS=$(echo "$RESPONSE_BODY" | jq -r '.data.status')

# Verify name if provided
if [ -n "$EXPECTED_NAME" ] && [ "$FETCHED_NAME" != "$EXPECTED_NAME" ]; then
    echo "❌ Action name mismatch" >&2
    echo "Expected: $EXPECTED_NAME" >&2
    echo "Got: $FETCHED_NAME" >&2
    show_logs_on_failure
    exit 1
fi

echo "✅ Fetched action successfully" >&2
echo "   Name: $FETCHED_NAME" >&2
echo "   Status: $FETCHED_STATUS" >&2
