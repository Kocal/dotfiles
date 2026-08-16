---
name: performance-optimization
description: Evidence-driven performance work on PHP and JS/TS code - find hot paths, benchmark before/after with Blackfire or node, keep only measurable wins, ship one surgical branch per improvement.
---

## When to Activate

When the user asks to make code faster, or mentions: performance, perf, optimize, benchmark,
profile, Blackfire, "it's slow", "reduce memory". Also when reviewing a change whose stated
purpose is speed.

## Core Rules

1. **No number, no change.** Every shipped improvement carries a before/after measurement.
   This applies to the "obviously beneficial" change too: removing plainly wasted work still
   needs a number, to justify it and to rank it.
2. **Benchmark the realistic scenario, never the worst case.** Ask what the real volume is,
   and ask the person who knows. A pre-lexer change looked like 7.7x on a 154 KB template and
   was a 13% *regression* on the repository's actual templates, whose median is 332 B. Pick
   the input sizes, the collection sizes and the call counts from production, then measure.
3. **Know where the code runs before claiming a win.** Compile time, cache warmup, CLI and
   per-request are not the same currency. A win at Twig compile time is worth real but modest
   money: templates compile once per deploy. Say which one you are buying.
4. **If the gain is inside the noise, drop it.** Revert, delete the branch, report it as
   investigated-and-rejected. Shipping noise costs review time and adds risk.
5. **Assert identical output**, in the benchmark or via the test suite. A faster wrong answer
   is a bug.
6. **Run the base branch test suite before blaming yourself.** Flaky timing assertions,
   snapshot drift and stale caches are common. State which failures are pre-existing.
7. **Prefer algorithmic wins.** Look for repeated work: a copy per character, a filesystem
   walk per lookup, a render per row. `O(n²) -> O(n)` beats any micro-tuning.
8. **One improvement, one branch, one commit** — even within the same package.
9. **Never invent an improvement to fill a package.** "Nothing found in Turbo" is a valid
   deliverable.
10. **Never use `git stash` to A/B.** It pops the user's stashes and destroys work. Copy to the
   scratchpad instead.
11. **Profiler output is your material, not the reader's.** Call graphs, edge tables and tooling
   commands stay in the analysis. A commit carries: what was slow, why, the fix, the numbers,
   the profile links, a runnable benchmark. Nothing else.

## Traps that produce false results

| Trap | Reality |
|------|---------|
| The first run right after `git checkout` | Contaminated: it pays template recompilation and cold caches. One profile read 4584ms/109MB this way against 3054-3259ms/93MB once warm — a 36% "win" that did not exist. Run once and discard before measuring. |
| `git checkout <branch> -- <file>` to compare | If the change is not committed, this **destroys it**. Copy to the scratchpad first. |
| Blackfire numbers disagreeing with raw ones | Instrumentation costs per *call*, so it flattens wins that shrink work inside one call and inflates wins that remove calls. Report both. |
| Grepping to confirm you removed something | Grep for what the reader sees, not the string you renamed. A renamed heading made a search come up clean while the whole dump was still in 14 PRs. |
| `class_exists()` looks expensive | A hashtable lookup once the class is loaded, ~50-100ns. OPcache does not fold it, but it is already free. |
| Extracting a helper to replace inline `substr()` | PHP method-call overhead can exceed the allocation removed. This can be a *regression*. |
| Hoisting regex literals in JS | V8 caches the compiled regex per literal, expect ~0%. Caching a `new RegExp(dynamicPattern)` is a real win. |
| `isset($a, $b, $c)` | That is AND, not OR. For "any of these keys", chain `\|\|`. |
| Replacing `usort` | It is stable since PHP 8.0. Preserve exact order semantics, including a trailing `array_reverse`. |
| Monorepo sibling packages | A package may install its sibling from Packagist, not the local path: editing `src/A` will not affect `src/B`'s tests. Patch `src/B/vendor/...` to benchmark, and say so in the commit. |
| A suite that suddenly fails | Move the framework cache aside (never `rm -rf`) and re-run. |

## Writing a benchmark

Reproduce the **shape** of production, not just the operation: realistic call-stack depth,
collection sizes, and repetition of the same key. Loop for 100ms+ of work, run each side 3+
times discarding the first, print whether old and new output match, and keep it standalone so
it can be pasted into the commit. For Blackfire, cut iterations 10-40x.

## Command Reference

```bash
# Profile a script; --ignore-exit-status for a suite with known failures
blackfire run --title "Subject - before" symfony php bench.php

# JS: build first, then benchmark the built output
pnpm --filter <package> run build && node bench.mjs
```

A/B two versions **without `git stash`**:

```bash
cp path/to/File.php $S/File.new.php      # save the candidate
git checkout <base> -- path/to/File.php  # baseline -> run BEFORE
cp $S/File.new.php path/to/File.php      # candidate -> run AFTER
```

### Reading the profile

Analyse the call graph, do not eyeball the web UI:

```bash
blackfire profile:graph "$UUID" \
  | jq -r '.edges[] | "\(.cost.wt/1000|round)ms ct=\(.cost.ct) \(.caller) -> \(.callee)"' \
  | sort -rn | head -15
```

**`ct` is the deterministic figure.** Wall time under instrumentation is noisy, call counts are
exact. "22,140 filesystem walks for 450 component lookups" survives review; a wall-time delta
on a test suite does not.

**`profile:graph` requires `--env <UUID>`** and refuses profiles living on a personal account
("No agent found for environment"). It wants an *environment* UUID, not an organisation one.
Set `BLACKFIRE_ENV` once so `run` and `profile:graph` agree, and so links are readable by
reviewers rather than private to you. Read the UUID from the URL a run prints
(`app.blackfire.io/envs/<here>/profiles/…`); the v1 API will not list it, and an `env=` key in
`~/.blackfire.ini` is ignored.

| Kind | URL |
|------|-----|
| Profile | `https://app.blackfire.io/envs/<env>/profiles/<uuid>/graph` |
| Comparison | `https://app.blackfire.io/envs/<env>/profiles/compare/<before>...<after>/graph` |

## Workflow

1. **Map the hot paths.** Read what runs per request / render / element. List candidates with
   a one-line hypothesis each. Do not edit yet.
2. **Benchmark the baseline**, then **read its call graph** to confirm the hypothesis against
   `ct` and `wt` before writing code. Cheaper than patching to find out.
3. **Implement the smallest possible change**, re-measure, and check output is identical.
   Gain inside the noise: revert and move on.
4. **Profile the fix.** Diff the call graphs: the edges you aimed at should move, the others
   should not. An unexplained global shift means a contaminated run, not a win.
5. **Run the package tests**, and the same suite on the untouched base branch.
6. **Lint and format**: `php-cs-fixer`, `oxlint`, `oxfmt`, `twig-cs-fixer`. For JS packages,
   rebuild and commit `dist/` if the repo tracks it.
7. **Branch and commit.** Use the repo's PR template if it has one, then: problem, fix, raw
   numbers, the benchmark in a fenced block, the profile links as bullets. For browser-side
   JS, say there is no Blackfire profile and give the node/vitest command instead. The commit
   message stays wrapped; a **PR body must not be**, so run it through the
   `natural-writing-editor` agent, one long line per paragraph, before `gh pr edit`.
8. **Before opening PRs**, check what is already open (`gh pr list --author <you> --state all`)
   and rebase on a freshly fetched base. When the same technique lands in several branches,
   keep constants and helper names identical, or reviewers will ask why they differ.
9. **Report** what was investigated and rejected, and which failures were pre-existing.

## Examples

### A candidate that must be dropped

`StimulusAttributes::escape()` calls `class_exists()` on every attribute. Looks wasteful.
Measured: 11 ms out of 412 ms, and caching it produced 382-425 ms against a 412 ms baseline —
pure noise. Reverted, branch deleted, reported as investigated-and-rejected.

### A candidate that turned out to be a regression

Replacing six inline `substr()` comparisons with calls to a helper made a benchmark go from
64 ms to 90 ms: method-call overhead exceeded the saved allocations. What worked was a guard
on the three characters that can start a delimiter, keeping the inline `substr()`: 64 -> 16 ms.
