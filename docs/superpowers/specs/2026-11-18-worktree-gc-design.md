# worktree-gc design

## Intent

Agent sessions create one git worktree per PR under `<repo>/.claude/worktrees/<name>` and nobody removes them once the PR lands, because the merge happens later, outside the session. On 2026-11-18 that was 93 worktrees and 61 GB in a single repo. `worktree-gc` is the command to run when disk is tight, or whenever.

## Goals

- Remove, without asking, every worktree whose work is provably done: PR merged (or branch already contained in the default branch) and no uncommitted change.
- For every other worktree, print why it is not provably done and ask y/N, one by one.
- Never lose uncommitted work without an explicit yes.

## Non-goals

- No scheduled run. The command is interactive by design.
- No cleanup of `node_modules`, `vendor`, `build` or `target` inside kept worktrees.
- No handling of worktrees created outside `.claude/worktrees/` (GitButler, manual).

## Constraints

- Installed through home-manager like the other dotfiles commands: `pkgs.writeShellApplication` in `nix/home/git.nix`, script body in `nix/home/git/worktree-gc.sh`.
- bash (what `writeShellApplication` runs), `git` and `coreutils` from Nix, `gh` from the user's PATH (Homebrew), already authenticated.
- Repos live in `~/workspace/<org>/<repo>` and sometimes `~/workspace/<repo>`. `--root` overrides for tests.

## Approaches considered

1. **Interactive CLI run by hand** (chosen). Matches how merges happen: the user merges, the user cleans. Zero risk of a background job deleting a bench base mid-benchmark.
2. launchd job deleting SAFE worktrees weekly. Rejected: SAFE depends on a `gh` call that can fail silently (rate limit, offline) and the job would then do nothing or, worse, trust a stale answer.
3. Session-end hook in the agent. Rejected: the PR is never merged by the time the session ends.

## Classification

For each worktree listed by `git worktree list --porcelain` except the main one:

| State | Condition | Action |
|---|---|---|
| SAFE | clean tree, and (PR state is MERGED, or HEAD is an ancestor of the base branch) | remove without asking |
| ASK | anything else | print reason, ask y/N |
| PRUNE | directory missing on disk | `git worktree prune`, no question |

Clean tree: `git status --porcelain --untracked-files=normal` prints nothing. Untracked files count as work unless gitignored, so build output stays out of the way while a new file that was never `git add`ed still blocks a silent removal.

Base branch: first of `upstream/main`, `upstream/master`, `origin/main`, `origin/master` that exists locally. No fetch is done.

PR state: `gh pr list --state all --head <branch> --json state --jq '.[0].state // empty'` run inside the repo. Empty output (no PR, gh error, detached HEAD) means "no PR".

ASK reasons, one per line, in this order: `uncommitted changes`, `PR closed without merge`, `detached HEAD`, `no PR, not in <base>`, `PR open`. A worktree with uncommitted changes always shows that reason first, whatever its PR state.

Removal: `git worktree remove --force <path>`, then `git branch -D <branch>` when the worktree had a branch. `--force` is needed because untracked build output otherwise blocks the removal.

## CLI

```
worktree-gc [--dry-run] [--yes] [--root <dir>]
```

- `--dry-run`: classify and print, remove nothing, ask nothing.
- `--yes`: remove SAFE and treat every ASK as answered yes (for a user who already read a `--dry-run`).
- Output: one line per SAFE removal, then one prompt per ASK with path, size, age in days and reason, then a total of freed space.

## Left to the builder

Exact output wording, size formatting, how the age is computed.
