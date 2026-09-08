## Output style

- Always follow the rules in the `i-have-adhd:i-have-adhd` skill: action-first, numbered steps, no preamble, no closers, state restated each turn.
- Arrows: use "->" (ASCII), never "→" (Unicode). Applies to generated text, not to existing source code.

## Code

- Code comments: default = zero. Write one ONLY if the "why" is non-obvious and absent from the code. Forbidden: restating the code, ticket numbers, obvious context. One short line max.
- NEVER write a comment that does not describe what the code actually does. No guessing, no extrapolating from a name, no carrying over a claim that was true before an edit. If you cannot verify it, do not write it.
- NEVER rewrite, reword or move an existing comment unless it is ABSOLUTELY necessary (the code it documents changed and the comment is now wrong). Leaving a comment alone is always the safe default.

## Writing (PR, prose)

- NEVER hard-wrap prose, anywhere, no exception. One paragraph = one long line, whatever the medium: commit messages, PR descriptions, GitHub/GitLab issues and comments, code reviews, README and docs, changelogs, release notes, blog posts, emails, chat messages. Blank lines between paragraphs and real list items are fine; mid-sentence newlines are not.
- This includes git commit bodies. `gh pr create --fill` reuses the commit message as the PR description, and a 72-col wrap renders as ragged garbage on GitHub. Subject line stays short and on one line; everything below it is plain Markdown (paragraphs, lists, code fences, links) written as long unwrapped lines.
- Length: default to the shortest text that changes what the reader will do next. An issue comment, a PR description or a commit body is not an investigation report; the evidence, the bisects and the version matrices stay in the chat unless asked for. When the target length is not specified, ask before writing.
- Same rule when briefing the natural-writing-editor agent: give it the two or three facts the reader needs, never the whole dossier. Feeding it everything is what produces the wall of text.
- All prose for human readers goes through the natural-writing-editor agent.
- When re-emitting the agent's output (heredoc, `--body`, a file, a terminal reply), copy it verbatim. Never re-wrap it on the way out; that is where the wrap usually creeps back in.

## Data & tooling

- Parsing data: jq/yq/awk preferred. No ad-hoc Python scripts.

## Permissions

- A denied command stays denied whatever shape the command takes: inside a `for` loop, a subshell, a pipe, an `&&` chain, or built from variables. The deny rule only matches the start of the command string, so a wrapper slips past it silently. Before wrapping any command, check it is not in `permissions.deny`.
- Never work around a hook that blocks you, and never rephrase a command to get past one. Print the command and let me run it.

## Git & PR (repos with a fork: origin=fork, upstream=canonical)

- ALWAYS push feature branches to the `origin` fork + open the PR from the fork (`gh pr create --head <fork-owner>:<branch>`).
- NEVER push a feature branch or open a PR on `upstream`. `upstream` = fetch/sync canonical only.
- Always check `git remote -v` + `gh repo view` before pushing/creating a PR.
- One PR = one commit. Squash the work-in-progress commits before opening it. This is the default everywhere, and it is mandatory on Symfony projects.
- That single commit carries the repo's `.github/PULL_REQUEST_TEMPLATE.md`, filled in: subject = the PR title, then the template's table/checklist answered for this PR (Bug fix, New feature, Deprecations, Documentation, Issues, License), then the description. Drop the template's `<!-- ... -->` authoring hints, they are instructions to the author, not content.
- Keep every closing keyword the template asks for. On Symfony repos the Issues row reads `| Issues | Fix #1234` — dropping the `Fix #` and leaving a bare `#1234` means GitHub does not close the issue when the PR is merged, and someone has to close it by hand. Removing the surrounding `<!-- ... -->` hint is right; removing the `Fix #` is not. When the PR closes no issue, leave the row's value empty rather than inventing one.
- Open the PR with `gh pr create --fill` so that commit message becomes the PR title and body. NEVER also pass a `--body`/`--body-file` built from the template: the table would be duplicated.

## Merging is mine, never yours

- **NEVER merge a pull request.** Not with `gh pr merge`, not through the API, not because the CI is green, not because I picked an option whose label contained the word "merge". Merging is my call and mine only. Prepare everything up to the merge, then stop and hand it over. Never put "merge" in an AskUserQuestion option either.
- `git push` is denied to you as well. Print the command and let me run it with the `!` prefix.
- When you hand a branch back, give exactly **two lines**, nothing longer:

    ```
    cd .claude/worktrees/pr<number>
    git push --force
    ```

- For those two lines to work, set the worktree up with `gh pr checkout <number>`, which wires `branch.<name>.remote` and `.pushremote` to the contributor's fork. Never `git fetch upstream pull/N/head:...` — it leaves no push remote and forces me to type a long explicit refspec.

## Worktrees

- Git worktrees go in `<repo>/.claude/worktrees/<name>`. Not the session scratchpad, not a sibling directory next to the repo.
- Add `/.claude/worktrees/` to `.git/info/exclude` (local only, never the tracked `.gitignore`) so `git status` stays clean.
- Remove the worktree with `git worktree remove` once the branch is merged or abandoned.

@RTK.md
