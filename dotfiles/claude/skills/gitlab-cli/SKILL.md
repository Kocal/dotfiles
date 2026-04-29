---
name: gitlab-cli
description: Use the GitLab CLI (`glab`) to fetch real data whenever the user references a GitLab issue, merge request, CI job, or any other GitLab resource by number or URL. Never guess or fabricate GitLab content.
---

## When to Activate

Use when user mention:

- Issue/MR number (`#123`, `fix #456`, `issue 789`)
- GitLab URL (`https://gitlab.com/owner/repo/-/issues/123`, `https://gitlab.com/owner/repo/-/merge_requests/456`)
- CI/CD job logs or pipeline runs ("CI failing", "check failed job logs", pipeline link)
- MR checks, reviews, comments, labels
- GitLab release or tag

## Core Rules

1. **Always use `glab` to fetch data.** Never guess issue/MR/comment/log content. Run `glab` command first.
2. **Never fabricate GitLab URLs.** Only use URLs from user or `glab` output.
3. **Prefer specific `glab` subcommands** over `glab api`. Fall back to `glab api` for uncovered endpoints.
4. **Quote relevant parts** of fetched data so user sees actual content.

## Command Reference

### Issues

```bash
# View an issue (current repo)
glab issue view 123

# View an issue from a specific repo
glab issue view 123 --repo owner/repo

# List issue notes (comments)
glab issue note list 123
```

### Merge Requests

```bash
# View a MR
glab mr view 123

# View a MR from a specific repo
glab mr view 123 --repo owner/repo

# List MR notes and discussions
glab mr note list 123

# View MR diff
glab mr diff 123

# Check MR approval status
glab mr approvals 123
```

### CI / GitLab Pipelines

```bash
# List recent pipeline runs
glab pipeline list

# View a specific pipeline (by ID)
glab pipeline view 12345

# View pipeline jobs
glab pipeline ci view 12345

# View job logs (trace)
glab pipeline ci trace 12345 <job-name>

# Retry a failed pipeline
glab pipeline retry 12345

# Retry a specific job
glab pipeline ci retry 12345 <job-name>
```

### Generic API Access

Use `glab api` for anything not covered above:

```bash
# Get MR discussions
glab api projects/:id/merge_requests/123/discussions

# Get issue resource label events
glab api projects/:id/issues/123/resource_label_events

# Get pipeline test report
glab api projects/:id/pipelines/456/test_report
```

## Workflow

1. **Detect reference.** Find issue/MR number or URL in user message.
2. **Determine repo.** Full URL → extract `owner/repo`. Number only → assume current repo. Ambiguous → ask.
3. **Fetch data.** Run `glab` command via Bash tool.
4. **Analyze and respond.** Quote relevant sections, answer question or do action.

## Examples

### User says: "What's the status of #42?"

```bash
glab issue view 42
```

Summarize title, state, assignees, latest activity.

### User says: "The CI is red on my MR, can you check?"

```bash
glab mr view
```

Get MR number, then:

```bash
glab pipeline list --per-page 1
```

If pipeline failed:

```bash
glab pipeline ci view <pipeline-id>
```

For failed jobs:

```bash
glab pipeline ci trace <pipeline-id> <job-name>
```

Analyze failure, suggest fix.

### User pastes: "https://gitlab.com/acme/app/-/merge_requests/789"

```bash
glab mr view 789 --repo acme/app
```

Answer whatever user asked about that MR.