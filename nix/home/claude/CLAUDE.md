## Output style

- Always follow the rules in the `i-have-adhd:i-have-adhd` skill: action-first, numbered steps, no preamble, no closers, state restated each turn.
- Arrows: use "->" (ASCII), never "→" (Unicode). Applies to generated text, not to existing source code.

## Code

- Code comments: default = zero. Write one ONLY if the "why" is non-obvious and absent from the code. Forbidden: restating the code, ticket numbers, obvious context. One short line max.
- NEVER write a comment that does not describe what the code actually does. No guessing, no extrapolating from a name, no carrying over a claim that was true before an edit. If you cannot verify it, do not write it.
- NEVER rewrite, reword or move an existing comment unless it is ABSOLUTELY necessary (the code it documents changed and the comment is now wrong). Leaving a comment alone is always the safe default.

## Writing (PR, prose)

- NEVER hard-wrap prose. One paragraph = one long line, no matter the medium: PR descriptions, GitHub/GitLab issues and comments, code reviews, README and docs, changelogs, release notes, blog posts, emails, chat messages. Blank lines between paragraphs and real list items are fine; mid-sentence newlines are not. This applies to text you type directly, not only to text the agent produced.
- The ONLY exception is the body of a git commit message, wrapped at ~72 cols. Nothing else is ever wrapped.
- All prose for human readers goes through the natural-writing-editor agent, not just PR descriptions and commit messages.
- When re-emitting the agent's output (heredoc, `--body`, a file, a terminal reply), copy it verbatim. Never re-wrap it on the way out; that is where the wrap usually creeps back in.
- A PR body derived from a commit message is still a PR description: it must go through the agent and be unwrapped. Never ship `gh pr create --fill` output as-is, it inherits the commit's 72-col wrap.

## Data & tooling

- Parsing data: jq/yq/awk preferred. No ad-hoc Python scripts.

## Permissions

- A denied command stays denied whatever shape the command takes: inside a `for` loop, a subshell, a pipe, an `&&` chain, or built from variables. The deny rule only matches the start of the command string, so a wrapper slips past it silently. Before wrapping any command, check it is not in `permissions.deny`.
- Never work around a hook that blocks you, and never rephrase a command to get past one. Print the command and let me run it.

## Git & PR (repos with a fork: origin=fork, upstream=canonical)

- ALWAYS push feature branches to the `origin` fork + open the PR from the fork (`gh pr create --head <fork-owner>:<branch>`).
- NEVER push a feature branch or open a PR on `upstream`. `upstream` = fetch/sync canonical only.
- Always check `git remote -v` + `gh repo view` before pushing/creating a PR.

@RTK.md
