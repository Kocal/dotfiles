# Creating a pull request with `gh`

The workflow rules, one PR = one commit, the filled-in repo template inside the commit body, fork as `origin` and never pushing to `upstream`, are set in `CLAUDE.md`. This file is about how `gh pr create` behaves under those rules and where it bites.

## The commit message is the PR

`gh pr create --fill` copies the single commit's subject to the PR title and its body to the PR body. Everything a reviewer will read therefore has to be in that commit before you run it.

1. Find the repo's template: `.github/PULL_REQUEST_TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE/*.md`, or `docs/PULL_REQUEST_TEMPLATE.md`. From outside a checkout:

   ```bash
   gh api repos/OWNER/REPO/contents/.github/PULL_REQUEST_TEMPLATE.md --jq .content | base64 -d
   ```

2. Squash to one commit and write the message: subject in the repo's convention, then the template's table or checklist answered for this PR, then the description. Keep the rows verbatim and drop the `<!-- ... -->` hints, which speak to the author rather than the reader. Keep whatever closing keyword the template asks for: a Symfony `| Issues | Fix #1234` row that loses its `Fix #` stops closing the issue on merge, and someone has to close it by hand.

3. Write the message to a file rather than fighting shell quoting over multi-line Markdown, and preview before committing to it:

   ```bash
   git commit -F msg.txt              # or: git commit --amend -F msg.txt
   gh pr create --dry-run --fill      # prints the PR it would create, creates nothing
   gh pr create --fill
   ```

## Why `--fill` alone

`--fill` reads git and ignores the repo template. That is deliberate and it is what you want here, since the commit body already carries the filled-in template.

Do not add `--body` or `--body-file` on top. `gh` does not merge the two: a `--title` or `--body` passed alongside `--fill` takes precedence and overwrites the autofilled content, so the carefully built commit body silently never reaches the PR. `--template` is for the interactive editor flow and stays opt-in.

`--fill` maps subject and body cleanly only when the branch holds exactly one commit. With several, `gh` falls back to the branch name as the title and a bullet list of commit subjects as the body. That is the mechanical reason behind the one-commit rule, on top of it being house style.

When the default is wrong: `--fill-first` uses only the first commit, `--fill-verbose` concatenates every commit's subject and body.

## Pushing from a fork

`origin` is the fork, `upstream` is canonical, and `gh` defaults the *base* repo to upstream. That mismatch is what produces `Head sha can't be blank` or `No commits between ...`: an unqualified `--head my-branch` sends `gh` looking for the branch in upstream, where it does not exist.

Check the ground first:

```bash
git remote -v                                         # origin = fork, upstream = canonical
gh repo view --json nameWithOwner -q .nameWithOwner   # gh's default base repo
```

Then either form works:

```bash
gh pr create --fill                                    # branch tracks origin, gh resolves the head itself
gh pr create --fill --base main --head FORK_OWNER:BRANCH
```

`--head user:branch` accepts only a **user** as the owner. A fork living under an organisation cannot be expressed this way (cli/cli#10093), so let auto-detection handle it, which means making sure the branch is pushed and tracking `origin` before calling `gh pr create`.

Pushing is denied to you. Print the push command and hand it to the user.
