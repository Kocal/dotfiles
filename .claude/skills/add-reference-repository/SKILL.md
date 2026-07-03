---
name: add-reference-repository
description: Clones a reference repository into `.references/<name>` and prepares it for reuse. Use when adding, refreshing, or bootstrapping a local reference repo from GitHub or another git remote.
---

# Add Reference Repository

## Quick Start

Create or reuse the current repo's `.references/` directory, then clone the requested repository into `.references/<name>`.

If the target path already exists, do not overwrite it blindly. Inspect the existing repo first and only replace it if the user explicitly asks.

## Workflow

1. Resolve the target name and clone URL.
2. Ensure `.references/` exists at the root of the current repository.
3. Clone the remote into `.references/<name>`.
4. If the cloned repository does not contain an `AGENTS.md`, create one from the local repo's `AGENTS.md` or a minimal repository-specific template.
5. Report the created path and the remote URL used.
6. Update the workspace `reference-repos.md` index when the curated set of references changes.

## Notes

- Use the repository root of the current workspace, not the agent's own home directory.
- Keep reference repositories isolated under `.references/` so they can be inspected without affecting the main repo.
- When a reference repo already exists, treat it as a reusable local fixture rather than recreating it.
- Keep a `reference-repos.md` file in the workspace root with the repo URL, local clone path, and a short reason for keeping each reference.
