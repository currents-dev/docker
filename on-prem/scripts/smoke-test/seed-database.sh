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
echo "[DEBUG] Sourcing .env file..." >&2
source .env

echo "Seeding database with test data..." >&2

# Generate a random 6-character project ID (alphanumeric)
generate_project_id() {
    openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 6
}

# Generate a 64-character API key
generate_api_key() {
    openssl rand -base64 96 | tr -dc 'a-zA-Z0-9' | head -c 64
}

echo "[DEBUG] Generating project ID..." >&2
PROJECT_ID=$(generate_project_id)
echo "[DEBUG] Project ID: $PROJECT_ID" >&2

echo "[DEBUG] Generating API key..." >&2
API_KEY=$(generate_api_key)
echo "[DEBUG] API key generated" >&2

ROOT_EMAIL="${ON_PREM_EMAIL:-root@currents.local}"
echo "[DEBUG] Root email: $ROOT_EMAIL" >&2

# Create temp file for the MongoDB script
echo "[DEBUG] Creating temp file..." >&2
TEMP_SCRIPT=$(mktemp)
trap "rm -f $TEMP_SCRIPT" EXIT
echo "[DEBUG] Temp file: $TEMP_SCRIPT" >&2

echo "[DEBUG] Writing MongoDB script to temp file..." >&2
cat > "$TEMP_SCRIPT" <<MONGOSCRIPT
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
print("Created API key: " + apiKey.substring(0, 8) + "...");

// Verify the API key was inserted
const verifyKey = db.apiKeys.findOne({ key: apiKey });
if (verifyKey) {
    print("Verified API key exists in database");
    print("API key orgId: " + verifyKey.orgId);
} else {
    print("WARNING: Could not verify API key in database");
}

// Verify project exists
const verifyProject = db.projects.findOne({ projectId: projectId });
if (verifyProject) {
    print("Verified project exists: " + verifyProject.projectId);
    print("Project orgId: " + verifyProject.orgId);
} else {
    print("WARNING: Could not verify project in database");
}

print("SUCCESS");
MONGOSCRIPT

echo "[DEBUG] MongoDB script written" >&2

# Get the container name
echo "[DEBUG] Getting MongoDB container ID..." >&2
CONTAINER=$(docker compose -f docker-compose.full.yml ps -q mongodb)
echo "[DEBUG] Container ID: $CONTAINER" >&2

if [ -z "$CONTAINER" ]; then
    echo "❌ MongoDB container not found" >&2
    exit 1
fi

# Copy script into container
echo "[DEBUG] Copying seed script to container..." >&2
docker cp "$TEMP_SCRIPT" "$CONTAINER:/tmp/seed.js"
echo "[DEBUG] Script copied" >&2

# Run the script
echo "[DEBUG] Running MongoDB seed script..." >&2
RESULT=$(docker exec "$CONTAINER" mongosh \
  -u "$MONGODB_USERNAME" -p "$MONGODB_PASSWORD" --authenticationDatabase admin \
  --quiet --file /tmp/seed.js 2>&1)

echo "[DEBUG] Script execution completed" >&2
echo "$RESULT" >&2

# Check if MongoDB commands succeeded
if ! echo "$RESULT" | grep -q "SUCCESS"; then
    echo "❌ Failed to seed database" >&2
    exit 1
fi

# Output variables that can be eval'd by the caller
printf "API_KEY=%q\n" "${API_KEY}"
printf "PROJECT_ID=%q\n" "${PROJECT_ID}"

echo "✅ Database seeded successfully" >&2
echo "   Project ID: ${PROJECT_ID}" >&2
echo "   API Key: ${API_KEY:0:8}..." >&2
