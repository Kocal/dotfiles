---
name: gitlab-cli
description: Use the GitLab CLI (`glab`) to fetch real data whenever the user references a GitLab issue, merge request, CI job, or any other GitLab resource by number or URL. Never guess or fabricate GitLab content.
---

## When to Activate

Use this skill whenever the user mentions or references:

- An issue or MR number (e.g. `#123`, `fix #456`, `issue 789`)
- A GitLab URL (e.g. `https://gitlab.com/owner/repo/-/issues/123`, `https://gitlab.com/owner/repo/-/merge_requests/456`)
- CI/CD job logs or pipeline runs (e.g. "the CI is failing", "check the logs of the failed job", a link to a GitLab CI pipeline)
- MR checks, reviews, comments, or labels
- A GitLab release or tag

## Core Rules

1. **Always use `glab` to fetch data.** Never guess the content of an issue, MR, comment, or log. Always run the appropriate `glab` command first.
2. **Never fabricate GitLab URLs.** Only use URLs provided by the user or returned by `glab` commands.
3. **Prefer specific `glab` subcommands** over `glab api` when one exists. Fall back to `glab api` for endpoints not covered by subcommands.
4. **Quote the relevant parts** of the fetched data in your response so the user sees the actual content.

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

1. **Detect the reference.** Identify the issue/MR number or URL from the user's message.
2. **Determine the repo.** If the user provides a full URL, extract `owner/repo`. If only a number is given, assume the current repo (let `glab` resolve it). If ambiguous, ask.
3. **Fetch the data.** Run the appropriate `glab` command via the Bash tool.
4. **Analyze and respond.** Read the output, quote the relevant sections, and answer the user's question or perform the requested action.

## Examples

### User says: "What's the status of #42?"

```bash
glab issue view 42
```

Then summarize the issue title, state, assignees, and latest activity.

### User says: "The CI is red on my MR, can you check?"

```bash
glab mr view
```

Get the MR number, then:

```bash
glab pipeline list --per-page 1
```

If a pipeline failed:

```bash
glab pipeline ci view <pipeline-id>
```

Then for failed jobs:

```bash
glab pipeline ci trace <pipeline-id> <job-name>
```

Then analyze the failure and suggest a fix.

### User pastes: "https://gitlab.com/acme/app/-/merge_requests/789"

```bash
glab mr view 789 --repo acme/app
```

Then answer whatever the user asked about that MR.
