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
    echo "Usage: $0 <api_key> <action_id> [expected_name]"
    exit 1
fi

if [ -z "$ACTION_ID" ]; then
    echo "❌ Error: Action ID is required"
    echo "Usage: $0 <api_key> <action_id> [expected_name]"
    exit 1
fi

echo "Fetching action: $ACTION_ID..."

GET_RESPONSE=$(curl -s -w "\n%{http_code}" "${API_BASE_URL}/actions/${ACTION_ID}" \
  -H "Authorization: Bearer ${API_KEY}")

HTTP_CODE=$(echo "$GET_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$GET_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" != "200" ]; then
    echo "❌ Failed to fetch action (HTTP $HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
    show_logs_on_failure
    exit 1
fi

FETCHED_NAME=$(echo "$RESPONSE_BODY" | jq -r '.data.name')
FETCHED_STATUS=$(echo "$RESPONSE_BODY" | jq -r '.data.status')

# Verify name if provided
if [ -n "$EXPECTED_NAME" ] && [ "$FETCHED_NAME" != "$EXPECTED_NAME" ]; then
    echo "❌ Action name mismatch"
    echo "Expected: $EXPECTED_NAME"
    echo "Got: $FETCHED_NAME"
    show_logs_on_failure
    exit 1
fi

echo "✅ Fetched action successfully"
echo "   Name: $FETCHED_NAME"
echo "   Status: $FETCHED_STATUS"
