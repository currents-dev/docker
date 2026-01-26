# Prepare Release

Prepare a new on-prem release by updating version files, changelog, and creating a PR.

## Instructions

### 1. Get the version number

Ask the user for the version number if not provided. Format: `YYYY-MM-DD-NNN` (e.g., `2026-01-23-001`).

### 2. Check current state

Before starting, check where we are in the release process:

- Is a release branch already checked out? (`git branch --show-current`)
- Are version files already updated? (check `on-prem/VERSION`)
- Are changes already committed? (`git status`)
- Is the branch already pushed? (`git log origin/main..HEAD`)
- Does a PR already exist? (check GitHub MCP)

Skip any steps that are already complete.

### 3. Create a release branch (if needed)

If not already on a release branch:

```bash
git checkout -b release-on-prem/<version>
```

### 4. Update version files (if needed)

Update the following files with the new version/image tag:

- `on-prem/VERSION` — Set to the version number
- `on-prem/.env.example` — Update `DC_CURRENTS_IMAGE_TAG` to the version number

### 5. Update the changelog (if needed)

Follow the `update-changelog` command instructions, but with these modifications:

- Instead of adding to `[Unreleased]`, **move** the existing `[Unreleased]` content to a new version section
- Create a new section header: `## [<version>] - <today's date in YYYY-MM-DD format>`
- Place it immediately after the `[Unreleased]` section
- Leave `[Unreleased]` empty (or with placeholder subsection headers)

### 6. User commits and pushes

**Important:** Do NOT use shell commands for git commit or push. The user likely has commit signing and SSH credentials configured that won't work via shell commands.

Tell the user to run these commands manually:

```bash
git add on-prem/VERSION on-prem/.env.example on-prem/CHANGELOG.md
git commit -m "release: on-prem <version>"
git push -u origin HEAD
```

Wait for the user to confirm they've committed and pushed, or re-run this command after they have.

### 7. Create the PR (if needed)

Once changes are pushed, check if a PR already exists using GitHub MCP `list_pull_requests` or `search_pull_requests`.

If no PR exists, follow the `create-pull-request` command to create a PR with:

- Title: `release: on-prem <version>`
- Body: Summary of changes from the changelog

## Notes

- This command is idempotent — it can be run multiple times and will pick up where it left off
- This command stops after creating the PR
- CI will run validation and smoke tests on the PR
- After CI passes and PR is merged, follow the tagging steps in the top-level README.md
- See the Release Process in the top-level README.md for the complete workflow
