---
name: github-cli
description: Use the GitHub CLI (`gh`) to fetch real data whenever the user references a GitHub issue, pull request, CI job, or any other GitHub resource by number or URL. Never guess or fabricate GitHub content.
---

## When to Activate

Use when user mention:

- Issue/PR number (`#123`, `fix #456`, `issue 789`)
- GitHub URL (`https://github.com/owner/repo/issues/123`, `https://github.com/owner/repo/pull/456`)
- CI/CD logs/runs ("CI failing", "check failed job logs", Actions run link)
- PR checks, reviews, comments, labels
- GitHub release/tag

## Core Rules

1. **Always use `gh` to fetch data.** Never guess issue/PR/comment/log content. Run `gh` first.
2. **Never fabricate GitHub URLs.** Only use URLs from user or `gh` output.
3. **Prefer specific `gh` subcommands** over `gh api`. Fall back to `gh api` when no subcommand exists.
4. **Quote relevant parts** of fetched data so user sees actual content.

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

1. **Detect reference.** Find issue/PR number or URL in user message.
2. **Determine repo.** Full URL → extract `owner/repo`. Number only → assume current repo. Ambiguous → ask.
3. **Fetch data.** Run `gh` command via Bash tool.
4. **Analyze + respond.** Quote relevant output, answer question or act.

## Examples

### User says: "What's the status of #42?"

```bash
gh issue view 42
```

Summarize title, state, assignees, latest activity.

### User says: "The CI is red on my PR, can you check?"

```bash
gh pr checks
```

If check failed:

```bash
gh run view <run-id> --log-failed
```

Analyze failure, suggest fix.

### User pastes: "https://github.com/acme/app/pull/789"

```bash
gh pr view 789 --repo acme/app
```

Answer whatever user asked about that PR.