# Update Changelog

Update the `[Unreleased]` section of the CHANGELOG based on commits since the last release.

## Instructions

1. **Find the latest git tag** by running:
   ```bash
   git describe --tags --abbrev=0
   ```

2. **Get commits between the latest tag and main** using the GitHub MCP tool:
   - Use `list_commits` with the repository `currents-dev/docker`
   - Compare from the latest tag to `main` branch
   - Get the commit messages and descriptions

3. **Categorize the commits** into the following sections based on their content:
   - **Breaking Changes** — Changes that require user action or break backward compatibility
   - **Compose File Changes** — Changes to templates or compose generation that require regeneration
   - **New Environment Variables** — New variables added to `.env.example`
   - **Changed Environment Variables** — Variables with changed defaults or behavior
   - **Added** — New features
   - **Changed** — Changes to existing features
   - **Fixed** — Bug fixes
   - **Removed** — Removed features

4. **Update the CHANGELOG** at `on-prem/CHANGELOG.md`:
   - Add entries under the `## [Unreleased]` section
   - Follow the existing format and style
   - Only include sections that have entries (skip empty sections)
   - Do not duplicate entries that are already in the changelog

## Notes

- Skip merge commits and automated commits
- Write clear, user-facing descriptions (not raw commit messages)
- Group related commits into single entries where appropriate
- Focus on what changed from the user's perspective
