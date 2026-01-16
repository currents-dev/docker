#!/bin/bash
#
# API smoke test - Create action
# Creates an action via the API and outputs the action ID
#
# Usage: ./api-test-create.sh <api_key> <project_id>
# Output: ACTION_ID=<id> (for eval)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ON_PREM_DIR="$SCRIPT_DIR/../.."

API_KEY="${1:-}"
PROJECT_ID="${2:-}"
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
    echo "Usage: $0 <api_key> <project_id>" >&2
    exit 1
fi

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: Project ID is required" >&2
    echo "Usage: $0 <api_key> <project_id>" >&2
    exit 1
fi

echo "Creating test action..." >&2
echo "API URL: $API_BASE_URL" >&2
echo "Project ID: $PROJECT_ID" >&2

# Generate unique name for this test run
TEST_NAME="smoke-test-action-$(date +%s)"

CREATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_BASE_URL}/actions?projectId=${PROJECT_ID}" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "'"${TEST_NAME}"'",
    "description": "Smoke test action - safe to delete",
    "action": [{"op": "skip"}],
    "matcher": {
      "op": "AND",
      "cond": [
        {
          "type": "title",
          "op": "eq",
          "value": "smoke-test-placeholder"
        }
      ]
    }
  }')

HTTP_CODE=$(echo "$CREATE_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$CREATE_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" != "201" ]; then
    echo "❌ Failed to create action (HTTP $HTTP_CODE)" >&2
    echo "Response: $RESPONSE_BODY" >&2
    show_logs_on_failure
    exit 1
fi

ACTION_ID=$(echo "$RESPONSE_BODY" | jq -r '.data.actionId')

if [ -z "$ACTION_ID" ] || [ "$ACTION_ID" = "null" ]; then
    echo "❌ Failed to extract actionId from response" >&2
    echo "Response: $RESPONSE_BODY" >&2
    show_logs_on_failure
    exit 1
fi

echo "✅ Created action: $ACTION_ID" >&2
echo "   Name: $TEST_NAME" >&2

# Output for eval
echo "ACTION_ID=$ACTION_ID"
echo "TEST_NAME=$TEST_NAME"
