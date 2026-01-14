#!/bin/bash
#
# Seed the database with test data for smoke testing
# Creates: organization, project, and API key
#
# Prerequisites:
# - MongoDB must be running and healthy
# - API must have created the root user (from ON_PREM_EMAIL in .env)
#
# Usage: ./seed-database.sh
# Outputs: API_KEY and PROJECT_ID to stdout (can be eval'd)
#
# Example:
#   eval $(./scripts/smoke-test/seed-database.sh)
#   echo $API_KEY $PROJECT_ID

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ON_PREM_DIR="$SCRIPT_DIR/../.."

cd "$ON_PREM_DIR"

# Source environment variables
source .env

echo "Seeding database with test data..." >&2

# Generate a random 6-character project ID (alphanumeric)
generate_project_id() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1
}

# Generate a 64-character API key
generate_api_key() {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1
}

PROJECT_ID=$(generate_project_id)
API_KEY=$(generate_api_key)
ROOT_EMAIL="${ON_PREM_EMAIL:-root@currents.local}"

# Create the MongoDB seed script
SEED_SCRIPT=$(cat <<MONGOSCRIPT
// Switch to currents database
db = db.getSiblingDB("currents");

// Find the root user created by the API container
const rootEmail = "${ROOT_EMAIL}";
const user = db.user.findOne({ email: rootEmail });

if (!user) {
    print("ERROR: Root user not found with email: " + rootEmail);
    print("Make sure the API has started and created the initial user.");
    quit(1);
}

print("Found root user: " + user._id);

// Generate ObjectIds for new documents
const orgOid = new ObjectId();
const orgDocId = new ObjectId();
const projectDocId = new ObjectId();
const apiKeyDocId = new ObjectId();
const memberOid = new ObjectId();

const now = new Date();
const projectId = "${PROJECT_ID}";
const apiKey = "${API_KEY}";

// Create organization
const orgResult = db.organization.insertOne({
    _id: orgDocId,
    name: "Smoke Test Organization",
    enableDomainAccess: false,
    discoverySource: "api",
    orgId: orgOid,
    ownerId: user._id.toString(),
    createdAt: now,
    active: true,
    billingEmails: [user.email],
    members: [
        {
            createdAt: now,
            memberId: memberOid,
            userId: user._id.toString(),
            role: "admin",
            email: user.email,
            invitationId: null,
            name: user.name || "Admin"
        }
    ],
    leadData: {
        testsAmount: "lt100",
        peopleAmount: "1-to-5",
        plannedTestingFrameworks: [],
        discoverySource: "api"
    }
});

if (!orgResult.acknowledged) {
    print("ERROR: Failed to create organization");
    quit(1);
}
print("Created organization: " + orgOid);

// Create project
const projectResult = db.projects.insertOne({
    _id: projectDocId,
    name: "Smoke Test Project",
    hooks: [],
    createdAt: now.toISOString(),
    failFast: false,
    inactivityTimeoutSeconds: 1800,
    parallelExecutionStrategy: "EXPECTED_DURATION",
    orgId: orgOid.toString(),
    defaultBranchName: "main",
    projectId: projectId
});

if (!projectResult.acknowledged) {
    print("ERROR: Failed to create project");
    quit(1);
}
print("Created project: " + projectId);

// Create API key
const apiKeyResult = db.apiKeys.insertOne({
    _id: apiKeyDocId,
    orgId: orgOid.toString(),
    key: apiKey,
    createdAt: now,
    createdBy: user._id.toString(),
    version: 0,
    expireAfter: null,
    deletedAt: null,
    deletedBy: null,
    lastUsed: null,
    scope: null,
    name: "Smoke Test API Key"
});

if (!apiKeyResult.acknowledged) {
    print("ERROR: Failed to create API key");
    quit(1);
}
print("Created API key");

print("SUCCESS");
MONGOSCRIPT
)

# Run MongoDB commands using --eval instead of heredoc
echo "Running MongoDB seed script..." >&2
RESULT=$(docker compose -f docker-compose.full.yml exec -T mongodb mongosh \
  -u "$MONGODB_USERNAME" -p "$MONGODB_PASSWORD" --authenticationDatabase admin \
  --quiet --eval "$SEED_SCRIPT" 2>&1)

echo "$RESULT" >&2

# Check if MongoDB commands succeeded
if ! echo "$RESULT" | grep -q "SUCCESS"; then
    echo "❌ Failed to seed database" >&2
    exit 1
fi

# Output variables that can be eval'd by the caller
echo "API_KEY=${API_KEY}"
echo "PROJECT_ID=${PROJECT_ID}"

echo "✅ Database seeded successfully" >&2
echo "   Project ID: ${PROJECT_ID}" >&2
echo "   API Key: ${API_KEY:0:8}..." >&2
