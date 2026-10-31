# Working on someone else's PR

Rebasing a contributor's branch, fixing review findings on it, or re-running its tests all need a checkout that can push back afterwards. Only `gh pr checkout` wires that up.

## Check it out

`gh pr checkout` creates a local branch from the PR head and sets both `branch.<name>.remote` and `branch.<name>.pushremote` to the contributor's fork, so a later force-push needs no refspec. That is the entire point of using it.

It can create the worktree itself, in one command:

```bash
gh pr checkout 123 --repo owner/repo --worktree .claude/worktrees/pr123
cd .claude/worktrees/pr123
```

Confirm the push wiring actually landed before doing any work, because discovering it at push time means redoing the checkout:

```bash
git config --get-regexp '^branch\..*\.(remote|pushremote)$'
```

`CLAUDE.md`'s `Worktrees` section covers where worktrees live and how to keep them out of `git status`.

## What looks equivalent and is not

`git fetch upstream pull/123/head:some-branch` fetches the same commits. It configures no push remote, so pushing back then needs the full explicit form with `--force-with-lease=...`, the fork's SSH URL and a `local:remote` refspec spelled out. That is long, easy to get subtly wrong, and lands on the wrong ref when it is.

## Check you are allowed in

`gh pr checkout` can only push back if the contributor left maintainer edits enabled:

```bash
gh pr view 123 --repo owner/repo --json maintainerCanModify,headRepositoryOwner,headRefName
```

`maintainerCanModify: false` means the branch is read-only to you. Say so up front rather than doing the work and failing at the end.

## Read the whole review

`gh pr view 123 --comments` shows the conversation and the review summaries, not the comments attached to diff lines, which is where most findings live:

```bash
gh api repos/OWNER/REPO/pulls/123/comments --paginate \
  --jq '.[] | {path, line: (.line // .original_line), user: .user.login, body}'
```

Work through those, then re-run the checks:

```bash
gh pr checks 123 --repo owner/repo
```

## Hand it back

Pushing is the user's call, never yours. When the work is done, give exactly the two lines `CLAUDE.md` asks for, the `cd` into the worktree and the force-push, then stop.

Once the branch is merged or abandoned:

```bash
git worktree remove .claude/worktrees/pr123
```
