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
glab ci list

# A pipeline and its jobs, by ID (without -p: the current branch's latest)
glab ci get -p 12345 --with-job-details

# Failed jobs of an MR's pipeline
glab ci get --merge-request=42 --status=failed --with-job-details

# Job log, by job ID or job name (-p picks the pipeline for a name)
glab ci trace 224356863
glab ci trace lint -p 12345

# Retry a job (job ID, not pipeline ID)
glab ci retry 224356863
```

`glab ci view` is interactive and takes a branch or tag, not a pipeline ID.

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

## Resolving the repo

A full URL gives `owner/repo`; a bare number means the current repo. Ask when neither settles it.

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
glab ci get --merge-request=<mr-number> --status=failed --with-job-details
glab ci trace <job-id>
```

Analyze failure, suggest fix.

### User pastes: "https://gitlab.com/acme/app/-/merge_requests/789"

```bash
glab mr view 789 --repo acme/app
```

Answer whatever user asked about that MR.