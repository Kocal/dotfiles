---
name: sf-performance-optimization
description: Evidence-driven performance work on PHP and JS/TS. Find the hot path, prove the win with a before/after benchmark on realistic input, and drop anything that lands inside the noise. Use whenever someone wants code to run faster or use less memory, or says any of: performance, perf, optimize, profile, benchmark, Blackfire, "it's slow", "this takes forever", "reduce memory", "c'est lent". Use it too when reviewing a change whose stated purpose is speed, because the first question there is what was measured and on what input. Covers Blackfire and node benchmarking, the traps that manufacture fake wins, and shipping one surgical branch per improvement.
---

# Performance work

## Core rules

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
4. **Time and memory are different currencies too.** Peak usage answers "will this OOM", the
   allocation count answers "is this doing pointless work", and a change can improve one while
   regressing the other. Caching buys time with memory by definition. When the ask is memory,
   say which of the two you measured, and report both whenever the change touches allocation.
5. **Establish the noise floor before claiming a win.** Run the baseline five times and look at
   the spread. A delta that fits inside that spread is not a result, whatever the means say.
   Report the range rather than a single figure: `382-425 ms against a 412 ms baseline` tells
   the reader it is noise, `398 ms vs 412 ms` hides it.
6. **If the gain is inside the noise, drop it.** Revert, delete the branch, report it as
   investigated-and-rejected. Shipping noise costs review time and adds risk.
7. **Assert identical output**, in the benchmark or via the test suite. A faster wrong answer
   is a bug.
8. **Run the base branch test suite before blaming yourself.** Flaky timing assertions,
   snapshot drift and stale caches are common. State which failures are pre-existing.
9. **Prefer algorithmic wins.** Look for repeated work: a copy per character, a filesystem
   walk per lookup, a render per row. `O(n²) -> O(n)` beats any micro-tuning.
10. **One improvement, one branch, one commit** — even within the same package.
11. **Never invent an improvement to fill a package.** "Nothing found in Turbo" is a valid
    deliverable.
12. **Never use `git stash` to A/B.** It pops the user's stashes and destroys work. Copy to the
    scratchpad instead, as shown under Measuring.
13. **Profiler output is your material, not the reader's.** Call graphs, edge tables and tooling
    commands stay in the analysis. A commit carries: what was slow, why, the fix, the numbers,
    the profile links, a runnable benchmark. Those numbers are the one investigation detail a
    perf commit earns the right to keep, because nobody can review the change without them.
    Everything else about how you got there stays in the chat.

## Traps that produce false results

| Trap | Reality |
|------|---------|
| The first run right after `git checkout` | Contaminated: it pays template recompilation and cold caches. One profile read 4584ms/109MB this way against 3054-3259ms/93MB once warm — a 36% "win" that did not exist. Run once and discard before measuring. |
| `git checkout <branch> -- <file>` to compare | If the change is not committed, this **destroys it**. Use `git show <base>:<path>` instead, which writes to stdout and cannot touch the working tree. |
| Blackfire numbers disagreeing with raw ones | Instrumentation costs per *call*, so it flattens wins that shrink work inside one call and inflates wins that remove calls. Report both. |
| Grepping to confirm you removed something | Grep for what the reader sees, not the string you renamed. A renamed heading made a search come up clean while the whole dump was still in 14 PRs. |
| `class_exists()` looks expensive | A hashtable lookup once the class is loaded, ~50-100ns. OPcache does not fold it, but it is already free. |
| Extracting a helper to replace inline `substr()` | PHP method-call overhead can exceed the allocation removed. This can be a *regression*. |
| Hoisting regex literals in JS | V8 caches the compiled regex per literal, expect ~0%. Caching a `new RegExp(dynamicPattern)` is a real win. |
| `isset($a, $b, $c)` | That is AND, not OR. For "any of these keys", chain `\|\|`. |
| Replacing `usort` | It is stable since PHP 8.0. Preserve exact order semantics, including a trailing `array_reverse`. |
| Monorepo sibling packages | A package may install its sibling from Packagist, not the local path: editing `src/A` will not affect `src/B`'s tests. Patch `src/B/vendor/...` to benchmark, and say so in the commit. |
| A suite that suddenly fails | Move the framework cache aside (never `rm -rf`) and re-run. |

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
7. **Branch and commit.** The commit message *is* the PR: subject line, then the repo's PR
   template filled in, then problem, fix, raw numbers, the benchmark in a fenced block, and the
   profile links as bullets. Write it unwrapped, one long line per paragraph, and run it through
   the `natural-writing-editor` agent before committing, so `gh pr create --fill` reuses it
   as-is. For browser-side JS, say there is no Blackfire profile and give the `node` or `vitest`
   command instead. Pushing is the user's call: print the command and hand it over.
8. **Before opening PRs**, check what is already open (`gh pr list --author <you> --state all`)
   and rebase on a freshly fetched base. When the same technique lands in several branches,
   keep constants and helper names identical, or reviewers will ask why they differ.
9. **Report** what was investigated and rejected, and which failures were pre-existing.

## Measuring

The profiler and the benchmark answer different questions. The profiler tells you *where* the
time goes and is the only way to find a hot path you did not suspect; the benchmark tells you
*whether your fix worked* and is the number that ships. You can do the second without the
first, so the absence of Blackfire is never a reason to skip the proof.

Reproduce the **shape** of production, not just the operation: realistic call-stack depth,
collection sizes, and repetition of the same key. Loop for 100ms+ of work, run each side 5
times discarding the first, print whether old and new output match, and keep it standalone so
it can be pasted into the commit. For Blackfire, cut iterations 10-40x.

### A/B two versions safely

Set `S` to this session's scratchpad directory first. The point of this dance is that nothing
ever reads the candidate back out of git, so an uncommitted change cannot be lost:

```bash
S=/path/to/scratchpad

cp src/Foo.php "$S/Foo.candidate.php"             # the change you are testing
git show <base>:src/Foo.php > "$S/Foo.base.php"   # baseline, straight from the object database

cp "$S/Foo.base.php" src/Foo.php                  # run BEFORE
cp "$S/Foo.candidate.php" src/Foo.php             # run AFTER
```

`git show` writes to stdout and leaves the working tree alone. `git checkout <base> -- <path>`
overwrites it, which is how uncommitted work disappears.

## Tooling

```bash
# Profile a script; --ignore-exit-status for a suite with known failures
blackfire run --title "Subject - before" symfony php bench.php

# JS: build first, then benchmark the built output
pnpm --filter <package> run build && node bench.mjs
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

## Examples

### A candidate that must be dropped

`StimulusAttributes::escape()` calls `class_exists()` on every attribute. Looks wasteful.
Measured: 11 ms out of 412 ms, and caching it produced 382-425 ms against a 412 ms baseline —
pure noise. Reverted, branch deleted, reported as investigated-and-rejected.

### A candidate that turned out to be a regression

Replacing six inline `substr()` comparisons with calls to a helper made a benchmark go from
64 ms to 90 ms: method-call overhead exceeded the saved allocations. What worked was a guard
on the three characters that can start a delimiter, keeping the inline `substr()`: 64 -> 16 ms.
