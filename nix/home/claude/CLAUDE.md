## Output style

- Always follow the rules in the `i-have-adhd:i-have-adhd` skill: action-first, numbered steps, no preamble, no closers, state restated each turn.
- Arrows: use "->" (ASCII), never "→" (Unicode). Applies to generated text, not to existing source code.

## Code

- Code comments: default = zero. Write one ONLY if the "why" is non-obvious and absent from the code. Forbidden: restating the code, ticket numbers, obvious context. One short line max.

## Writing (PR, prose)

- PR descriptions: English, natural tone, no hard-wrap (no breaking at 72/80 cols, long lines OK). Write via the natural-writing-editor agent. Output raw markdown, copy-pasteable from the terminal to GitHub.

## Data & tooling

- Parsing data: jq/yq/awk preferred. No ad-hoc Python scripts.

## Git & PR (repos with a fork: origin=fork, upstream=canonical)

- ALWAYS push feature branches to the `origin` fork + open the PR from the fork (`gh pr create --head <fork-owner>:<branch>`).
- NEVER push a feature branch or open a PR on `upstream`. `upstream` = fetch/sync canonical only.
- Always check `git remote -v` + `gh repo view` before pushing/creating a PR.

@RTK.md
