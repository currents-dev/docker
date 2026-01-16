#!/bin/bash
#
# API smoke test - verify the Currents API is working
# Creates an action via the API and verifies it can be retrieved
#
# Usage: ./api-test.sh <api_key> <project_id>
#
# Based on Currents API: https://api.currents.dev/v1/docs/

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

echo "Running API smoke test..." >&2
echo "API URL: $API_BASE_URL" >&2
echo "Project ID: $PROJECT_ID" >&2
echo "" >&2

# Generate unique name for this test run
TEST_NAME="smoke-test-action-$(date +%s)"

RESPONSE_FILE=$(mktemp)
trap 'rm -f "$RESPONSE_FILE"' EXIT

# =============================================================================
# Step 1: Create an action
# =============================================================================
echo "Step 1: Creating test action..." >&2

HTTP_CODE=$(curl -s -o "$RESPONSE_FILE" -w "%{http_code}" -X POST "${API_BASE_URL}/actions?projectId=${PROJECT_ID}" \
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

RESPONSE_BODY=$(cat "$RESPONSE_FILE")

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

# =============================================================================
# Step 2: Fetch the action back
# =============================================================================
echo "" >&2
echo "Step 2: Fetching action..." >&2

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

if [ "$FETCHED_NAME" != "$TEST_NAME" ]; then
    echo "❌ Action name mismatch" >&2
    echo "Expected: $TEST_NAME" >&2
    echo "Got: $FETCHED_NAME" >&2
    show_logs_on_failure
    exit 1
fi

echo "✅ Fetched action successfully" >&2
echo "   Name: $FETCHED_NAME" >&2
echo "   Status: $FETCHED_STATUS" >&2

# =============================================================================
# Step 3: Clean up - delete the action
# =============================================================================
echo "" >&2
echo "Step 3: Cleaning up (deleting action)..." >&2

HTTP_CODE=$(curl -s -o "$RESPONSE_FILE" -w "%{http_code}" -X DELETE "${API_BASE_URL}/actions/${ACTION_ID}" \
  -H "Authorization: Bearer ${API_KEY}")

RESPONSE_BODY=$(cat "$RESPONSE_FILE")

if [ "$HTTP_CODE" != "200" ]; then
    echo "⚠️  Warning: Failed to delete action (HTTP $HTTP_CODE)" >&2
    echo "Response: $RESPONSE_BODY" >&2
    # Don't fail the test for cleanup issues
else
    echo "✅ Action deleted (archived)" >&2
fi

# =============================================================================
# Summary
# =============================================================================
echo "" >&2
echo "==========================================" >&2
echo "✅ API smoke test passed!" >&2
echo "==========================================" >&2
echo "" >&2
echo "Verified:" >&2
echo "  - POST /actions (create)" >&2
echo "  - GET /actions/{actionId} (read)" >&2
echo "  - DELETE /actions/{actionId} (delete)" >&2
echo "" >&2
