---
name: github-cli
description: Fetch real GitHub data with the `gh` CLI instead of reconstructing it from memory. Use whenever a message mentions an issue or PR number (`#123`, "issue 789", "la PR 12"), pastes a github.com URL, or brings up CI failures, review comments, checks, labels, releases or tags, even when the word "GitHub" never appears, since "the CI is red" and a bare `#456` are already GitHub references. Use it too when opening a pull request (repo template, fork workflow, `gh pr create` traps) or checking out someone else's PR to rebase it or answer its review.
---

# GitHub CLI

`gh` is the only reliable account of what an issue, a PR, a review or a CI run actually contains. Reconstructing that from memory, from a branch name, or from what the user seems to imply produces fiction that reads exactly like fact, and they usually find out only after acting on it. Fetch first, answer second.

## Rules

**Run `gh` before answering, even when the question looks answerable from context.** "Is #42 still open?" still needs a fetch: the state moved since anything you might remember, and a stale "yes" costs more than a slow one.

**Only emit URLs that came from the user or from `gh` output.** A `github.com/owner/repo/pull/123` you assembled yourself is a 404 at best and a stranger's PR at worst.

**Reach for the specific subcommand before `gh api`.** `gh issue view`, `gh pr checks` and `gh run view` return output shaped for reading. `gh api` returns raw JSON where the one field you wanted sits among fifty you did not, all of it billed to your context. Fall back to `gh api` when no subcommand covers the case, and pair it with `--jq` when you do.

**Quote the part you acted on:** the failing log line, the review comment, the check name. The user should be able to audit your conclusion without re-running your commands.

**Workflow rules live in `CLAUDE.md`, not here.** Its `Git & PR` and `Merging is mine, never yours` sections govern fork versus upstream, one PR = one commit, the PR template, and the fact that pushing and merging belong to the user alone. This file covers `gh` mechanics only. Where the two look like they disagree, `CLAUDE.md` wins.

## Reading issues and pull requests

```bash
gh issue view 123                      # current repo
gh issue view 123 --repo owner/repo    # anywhere
gh issue view 123 --comments           # plus the discussion
gh issue list --search "is:open label:bug sort:updated-desc"

gh pr view 123 --repo owner/repo
gh pr view 123 --comments              # discussion and review summaries
gh pr diff 123
gh pr checks 123                       # each check run and its conclusion
gh pr view 123 --json state,mergeable,reviewDecision,headRefName,maintainerCanModify
```

**`--comments` stops at the conversation tab.** Comments left on specific diff lines are a separate resource, and they are usually where the actual review findings are. On one symfony/symfony PR, `gh pr view --comments` surfaced 6 entries where the inline endpoint returned 28. Answering a review off the first number means missing most of it:

```bash
gh api repos/OWNER/REPO/pulls/123/comments --paginate \
  --jq '.[] | {path, line: (.line // .original_line), user: .user.login, body}'
```

`line` is null once the diff hunk a comment was attached to has moved; `original_line` still points at the code it was written against.

## Reading CI

```bash
gh run list --limit 10
gh run view 12345678                   # run id comes from the URL or from gh pr checks
gh run view 12345678 --log-failed      # only the steps that failed
gh run rerun 12345678 --failed
```

**`--log` dumps the entire run**, which on a matrix build is tens of thousands of lines landing in context in full. Start with `--log-failed`, and filter when you only need the assertion that broke:

```bash
gh run view 12345678 --log-failed | grep -iE 'error|fail|assert' | head -40
```

## Going further

| Task | Read |
| --- | --- |
| Open a PR: repo template, `--fill`, pushing from a fork | `references/creating-prs.md` |
| Take over someone else's PR: check out, rebase, answer the review | `references/reviewing-prs.md` |

Anything with no subcommand goes through `gh api`, which speaks the whole REST API and, with `graphql`, the parts REST does not reach:

```bash
gh api repos/OWNER/REPO/issues/123/timeline --jq '.[] | {event, actor: .actor.login}'
gh api repos/OWNER/REPO/releases/latest --jq '.tag_name'
gh api graphql -f query='query { viewer { login } }'
```

## Worked examples

**"What's the status of #42?"** -> `gh issue view 42`, then report state, assignees and the last thing that happened on it. "It's open" is the part they already knew.

**"The CI is red on my PR."** -> `gh pr checks` to find which check failed and its run id, then `gh run view <id> --log-failed` for the reason. Quote the failing assertion and say what would fix it.

**A bare `https://github.com/acme/app/pull/789` with no question attached** -> `gh pr view 789 --repo acme/app`. If they asked nothing, summarise state, checks, and what the PR is waiting on.
