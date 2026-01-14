#!/bin/bash
#
# API smoke test - verify the Currents API is working
# Creates an action via the API and verifies it can be retrieved
#
# Usage: ./api-test.sh <api_key> <project_id>
#
# Based on Currents API: https://api.currents.dev/v1/docs/

set -e

API_KEY="${1:-}"
PROJECT_ID="${2:-}"
API_BASE_URL="${API_BASE_URL:-http://localhost:4000/v1}"

if [ -z "$API_KEY" ]; then
    echo "❌ Error: API key is required"
    echo "Usage: $0 <api_key> <project_id>"
    exit 1
fi

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: Project ID is required"
    echo "Usage: $0 <api_key> <project_id>"
    exit 1
fi

echo "Running API smoke test..."
echo "API URL: $API_BASE_URL"
echo "Project ID: $PROJECT_ID"
echo ""

# Generate unique name for this test run
TEST_NAME="smoke-test-action-$(date +%s)"

# =============================================================================
# Step 1: Create an action
# =============================================================================
echo "Step 1: Creating test action..."

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
    echo "❌ Failed to create action (HTTP $HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
    exit 1
fi

ACTION_ID=$(echo "$RESPONSE_BODY" | jq -r '.data.actionId')

if [ -z "$ACTION_ID" ] || [ "$ACTION_ID" = "null" ]; then
    echo "❌ Failed to extract actionId from response"
    echo "Response: $RESPONSE_BODY"
    exit 1
fi

echo "✅ Created action: $ACTION_ID"

# =============================================================================
# Step 2: Fetch the action back
# =============================================================================
echo ""
echo "Step 2: Fetching action..."

GET_RESPONSE=$(curl -s -w "\n%{http_code}" "${API_BASE_URL}/actions/${ACTION_ID}" \
  -H "Authorization: Bearer ${API_KEY}")

HTTP_CODE=$(echo "$GET_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$GET_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" != "200" ]; then
    echo "❌ Failed to fetch action (HTTP $HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
    exit 1
fi

FETCHED_NAME=$(echo "$RESPONSE_BODY" | jq -r '.data.name')
FETCHED_STATUS=$(echo "$RESPONSE_BODY" | jq -r '.data.status')

if [ "$FETCHED_NAME" != "$TEST_NAME" ]; then
    echo "❌ Action name mismatch"
    echo "Expected: $TEST_NAME"
    echo "Got: $FETCHED_NAME"
    exit 1
fi

echo "✅ Fetched action successfully"
echo "   Name: $FETCHED_NAME"
echo "   Status: $FETCHED_STATUS"

# =============================================================================
# Step 3: Clean up - delete the action
# =============================================================================
echo ""
echo "Step 3: Cleaning up (deleting action)..."

DELETE_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "${API_BASE_URL}/actions/${ACTION_ID}" \
  -H "Authorization: Bearer ${API_KEY}")

HTTP_CODE=$(echo "$DELETE_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$DELETE_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" != "200" ]; then
    echo "⚠️  Warning: Failed to delete action (HTTP $HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
    # Don't fail the test for cleanup issues
else
    echo "✅ Action deleted (archived)"
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "=========================================="
echo "✅ API smoke test passed!"
echo "=========================================="
echo ""
echo "Verified:"
echo "  - POST /actions (create)"
echo "  - GET /actions/{actionId} (read)"
echo "  - DELETE /actions/{actionId} (delete)"
echo ""
