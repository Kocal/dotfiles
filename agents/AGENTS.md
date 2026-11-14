## Output style

- Always follow the rules in the `i-have-adhd:i-have-adhd` skill: action-first, numbered steps, no preamble, no closers, state restated each turn.
- Arrows: use "->" (ASCII), never "→" (Unicode). Applies to generated text, not to existing source code.

## Code

- Code comments: default = zero. Write one ONLY if the "why" is non-obvious and absent from the code. Forbidden: restating the code, ticket numbers, obvious context. One short line max.
- NEVER write a comment that does not describe what the code actually does. No guessing, no extrapolating from a name, no carrying over a claim that was true before an edit. If you cannot verify it, do not write it.
- NEVER rewrite, reword or move an existing comment unless it is ABSOLUTELY necessary (the code it documents changed and the comment is now wrong). Leaving a comment alone is always the safe default.
- Identifiers in English: files, functions, methods, properties, variables, constants, Stimulus targets, values and actions. Comments and UI copy follow the project's language. Business vocabulary the codebase already names in another language (entities, enums) keeps that name.
- Front-end code (Stimulus controllers, components, any JS/TS file): the controller stays thin, wiring only (targets, events, calls). Every piece of logic goes into its own small module, written that way from the first draft and not after review: parsing, formatting, computation, storage access, CSS/DOM reads, third-party plugins. Put it in the shared folder when it is generic, in the domain folder only when it is truly domain-specific, and give each module a unit test. Code copied from a third-party kit or library (kept close to upstream to stay resynchronisable) is exempt.
- Translation keys: always the full key as a literal (`'cart.summary.title' | trans`), never built by concatenation, `sprintf()` or a template literal. A built key cannot be found by grep or by the IDE. When the key depends on an enum, a method with a `match` returns the full key for each case. Look for an existing key to reuse before adding one.
- Database migrations: once a migration has shipped, its SQL is never edited, any change goes into a new migration. The migration class carries a docblock saying what it does and why; this one is required, the zero-comment default does not apply to it.

## Tests

- Unit tests follow arrange / act / assert, as three blocks separated by a blank line. Arrange puts the data and the object under test in variables. Act stores the result of the call under test in a variable. Assert only asserts and never repeats the call. An expected exception (`expectException()`) goes right before the act.

    ```php
    $slugger = new Slugger();

    $slug = $slugger->slug('Hello World');

    self::assertSame('hello-world', $slug);
    ```

    Not `self::assertSame('hello-world', new Slugger()->slug('Hello World'))`, nor `expect(new Slugger().slug('Hello World')).toBe(...)` in JS.

## PHP & Twig (Symfony applications)

Defaults for Symfony applications when the project sets no rule of its own. Contributions to Symfony itself follow the `symfony-code-contribution` skill instead.

- `\sprintf()` as soon as a value is interpolated, never concatenation (`'Hello '.$name`). Concatenating two literals or constants is fine (`__DIR__.'/data.php'`).
- Current time from `now()` (`use function Symfony\Component\Clock\now`), never `new DateTime()` or `new DateTimeImmutable()`. Dates are `DateTimeImmutable`, never `DateTime`.
- Translatable messages: `t('key', ['%param%' => $value])` (`use function Symfony\Component\Translation\t`), never `new TranslatableMessage(...)`. The declared return type stays `TranslatableMessage`.
- A class with a public named constructor (`fromX()`, `create()`) has a `private` constructor without default values. Tests go through the named constructor; no public constructor is kept just for them.
- TwigComponent props: dynamic values as `attr="{{ value }}"`, not `:attr="value"`. Both keep the type when the value is a single `{{ }}` expression, and the first one highlights better in the IDE and in code review. Literal strings stay `attr="literal"`.

## Writing (PR, prose)

- NEVER hard-wrap prose. One paragraph = one long line, whatever the medium: commit messages, PR descriptions, GitHub/GitLab issues and comments, code reviews, README and docs, changelogs, release notes, blog posts, emails, chat messages. Blank lines between paragraphs and real list items are fine; mid-sentence newlines are not.
- One exception, and only one: reStructuredText for Symfony projects (symfony-docs, the symfony.com blog), where the house convention is a hard wrap at ~80 columns. Those renderers reflow the text, so the ragged output this rule exists to prevent does not happen there. Never wrap inside code blocks or link targets.
- This includes git commit bodies. `gh pr create --fill` reuses the commit message as the PR description, and a 72-col wrap renders as ragged garbage on GitHub. Subject line stays short and on one line; everything below it is plain Markdown (paragraphs, lists, code fences, links) written as long unwrapped lines.
- Length: default to the shortest text that changes what the reader will do next. An issue comment, a PR description or a commit body is not an investigation report; the evidence, the bisects and the version matrices stay in the chat unless asked for. When the target length is not specified, ask before writing.
- Shape matters as much as length on GitHub: give every long sentence its own paragraph, separated by a blank line. Four long sentences run together render as a six-line wall that nobody reads. This does not contradict the no-hard-wrap rule above: the break goes between two sentences, never inside one.
- Budget for a PR description or a commit body: three paragraphs at most, one or two sentences each. When a sentence carries two ideas joined by a comma plus "and" or "so", split it at the comma into two sentences instead of keeping it whole.
- Same rule when briefing the natural-writing-editor agent: give it the two or three facts the reader needs, never the whole dossier. Feeding it everything is what produces the wall of text.
- All prose for human readers goes through the natural-writing-editor agent.
- When re-emitting the agent's output (heredoc, `--body`, a file, a terminal reply), copy it verbatim. Never re-wrap it on the way out; that is where the wrap usually creeps back in.
- When a ticket or an issue points to existing code, link a permalink pinned to the SHA of `origin/<main>`, never a branch name. Check each line number with `git show origin/<main>:<path>`, not on the current branch, where the numbers drift.

## Data & tooling

- Parsing data: jq/yq/awk preferred. No ad-hoc Python scripts.
- Never print a file that holds tokens or credentials (`.mcp.json`, `.env`, a CLI or bot config). Extract the one field you need into a shell variable with jq/yq/sed and use the variable without echoing it.

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
- Open the PR with `gh pr create --fill` so that commit message becomes the PR title and body. NEVER also pass a `--body`/`--body-file` alongside `--fill`: gh does not merge the two, `--body` takes precedence and overwrites the autofilled content, so the commit body never reaches the PR.

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
