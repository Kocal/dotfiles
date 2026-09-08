---
name: github-cli
description: Use the GitHub CLI (`gh`) to fetch real data whenever the user references a GitHub issue, pull request, CI job, or any other GitHub resource by number or URL, and to create pull requests correctly (including from a fork). Never guess or fabricate GitHub content.
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
4. **NEVER run `gh pr merge`**, and never merge through `gh api` either. Merging is the user's decision alone, whatever the CI says and whatever option label they picked. Prepare the branch, hand back the push command, stop there.
5. **Quote relevant parts** of fetched data so user sees actual content.

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

### Checking Out Someone Else's PR

To work on a contributor's PR — rebase it, fix review findings, re-run its tests — always check it out with `gh pr checkout`, inside a worktree under `<repo>/.claude/worktrees/pr<number>`:

```bash
git worktree add --detach .claude/worktrees/pr123 upstream/main
cd .claude/worktrees/pr123
gh pr checkout 123 --repo owner/repo
```

`gh pr checkout` creates a local branch named after the PR head and sets `branch.<name>.remote` **and** `branch.<name>.pushremote` to the contributor's fork, so a later `git push --force` needs no refspec. Verify with:

```bash
git config --get-regexp '^branch\..*\.(remote|pushremote)$'
```

Never substitute `git fetch upstream pull/N/head:branch`. It fetches the same commits but configures no push remote, so pushing back then needs a full explicit `git push --force-with-lease=... git@github.com:owner/repo.git local:remote`, which is long and easy to get wrong.

`gh pr checkout` works only when the PR allows maintainer edits — check `maintainerCanModify` first:

```bash
gh pr view 123 --repo owner/repo --json maintainerCanModify,headRepositoryOwner,headRefName
```

### Creating Pull Requests

**One PR = one commit, and that commit message IS the PR.** Squash first, put the filled-in PR template in the commit body, then open the PR with `--fill`.

1. **Read the repo's PR template.** `.github/PULL_REQUEST_TEMPLATE.md`, or `.github/PULL_REQUEST_TEMPLATE/*`, or `docs/PULL_REQUEST_TEMPLATE.md`.
2. **Build the commit message.** Subject = the PR title, in the repo's convention. Body = the template's table/checklist with the answers filled in, then the description. Keep the rows verbatim, drop the `<!-- ... -->` authoring hints.
3. **Open the PR with `--fill`.** `gh` then reuses that commit message as the PR title and body.

**Never pass a `--body`/`--body-file` built from the template on top of `--fill`** — the table would appear twice. `--fill` ignores the repo template on purpose, which is what you want here since the commit body already carries it. `--template` stays opt-in and you do not need it.

`--fill` only maps subject/body cleanly when the branch holds a single commit; with several, `gh` falls back to the branch name and a list of commit subjects. That is the reason for the one-commit rule.

```bash
# fetch the template if unsure it exists
gh api repos/OWNER/REPO/contents/.github/PULL_REQUEST_TEMPLATE.md --jq .content | base64 -d

# write the message to a file (avoids shell-escaping multi-line Markdown), then
git commit -F msg.txt          # or: git commit --amend -F msg.txt
gh pr create --fill
```

**From a fork (common case).** The branch lives on your fork (`origin`, e.g. `Kocal/repo`) while the PR targets the upstream default repo (e.g. `symfony/repo`). `gh` defaults the *base* repo to upstream, so an unqualified `--head my-branch` makes gh look for the branch **in upstream** and fails with `Head sha can't be blank` / `No commits between ...`. Check the setup first:

```bash
git remote -v                                        # origin = fork, upstream = canonical
gh repo view --json nameWithOwner -q .nameWithOwner  # gh's default (base) repo
```

Then create it one of two ways:

```bash
# A. let gh auto-detect (the branch tracks origin = fork)
gh pr create --fill

# B. qualify the head with the fork owner
gh pr create --fill --base main --head FORK_OWNER:BRANCH
```

Note: `git push` may be sandbox-blocked; if so, ask the user to run it via the `!` prefix, then create the PR.

**Squash before opening.** Collapse the work-in-progress commits into the single commit described above, following the repo's commit-message convention. This also keeps the squash commit body clean on repos that squash-merge, since those concatenate every commit message.

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