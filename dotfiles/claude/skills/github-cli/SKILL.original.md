---
name: github-cli
description: Use the GitHub CLI (`gh`) to fetch real data whenever the user references a GitHub issue, pull request, CI job, or any other GitHub resource by number or URL. Never guess or fabricate GitHub content.
---

## When to Activate

Use this skill whenever the user mentions or references:

- An issue or PR number (e.g. `#123`, `fix #456`, `issue 789`)
- A GitHub URL (e.g. `https://github.com/owner/repo/issues/123`, `https://github.com/owner/repo/pull/456`)
- CI/CD job logs or workflow runs (e.g. "the CI is failing", "check the logs of the failed job", a link to a GitHub Actions run)
- PR checks, reviews, comments, or labels
- A GitHub release or tag

## Core Rules

1. **Always use `gh` to fetch data.** Never guess the content of an issue, PR, comment, or log. Always run the appropriate `gh` command first.
2. **Never fabricate GitHub URLs.** Only use URLs provided by the user or returned by `gh` commands.
3. **Prefer specific `gh` subcommands** over `gh api` when one exists. Fall back to `gh api` for endpoints not covered by subcommands.
4. **Quote the relevant parts** of the fetched data in your response so the user sees the actual content.

## Command Reference

### Issues

```bash
# View an issue (current repo)
gh issue view 123

# View an issue from a specific repo
gh issue view 123 --repo owner/repo

# List issue comments
gh issue view 123 --comments
```

### Pull Requests

```bash
# View a PR
gh pr view 123

# View a PR from a specific repo
gh pr view 123 --repo owner/repo

# List PR comments and reviews
gh pr view 123 --comments

# View PR checks/status
gh pr checks 123

# View PR diff
gh pr diff 123
```

### CI / GitHub Actions

```bash
# List recent workflow runs
gh run list

# View a specific run (by ID, visible in the URL)
gh run view 12345678

# View failed job logs
gh run view 12345678 --log-failed

# View full logs of a run
gh run view 12345678 --log

# Re-run failed jobs
gh run rerun 12345678 --failed
```

### Generic API Access

Use `gh api` for anything not covered above:

```bash
# Get PR review comments
gh api repos/owner/repo/pulls/123/comments

# Get issue timeline events
gh api repos/owner/repo/issues/123/timeline

# Get a specific check suite
gh api repos/owner/repo/check-runs/456
```

## Workflow

1. **Detect the reference.** Identify the issue/PR number or URL from the user's message.
2. **Determine the repo.** If the user provides a full URL, extract `owner/repo`. If only a number is given, assume the current repo (let `gh` resolve it). If ambiguous, ask.
3. **Fetch the data.** Run the appropriate `gh` command via the Bash tool.
4. **Analyze and respond.** Read the output, quote the relevant sections, and answer the user's question or perform the requested action.

## Examples

### User says: "What's the status of #42?"

```bash
gh issue view 42
```

Then summarize the issue title, state, assignees, and latest activity.

### User says: "The CI is red on my PR, can you check?"

```bash
gh pr checks
```

If a check failed:

```bash
gh run view <run-id> --log-failed
```

Then analyze the failure and suggest a fix.

### User pastes: "https://github.com/acme/app/pull/789"

```bash
gh pr view 789 --repo acme/app
```

Then answer whatever the user asked about that PR.
