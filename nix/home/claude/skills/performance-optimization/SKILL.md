---
name: performance-optimization
description: Evidence-driven performance work on PHP and JS/TS code - find hot paths, benchmark before/after with Blackfire or node, keep only measurable wins, ship one surgical branch per improvement.
---

## When to Activate

Activate when the user asks to make code faster, or mentions: performance, perf, optimize,
benchmark, profile, Blackfire, "it's slow", "reduce memory", "too many queries/allocations".

Also activate when reviewing a change whose stated purpose is speed.

## Core Rules

1. **No number, no change.** Every shipped improvement carries a before/after measurement.
   A change that "should be faster" and is not measured does not get committed.
2. **Measure before implementing.** Establish the baseline first, so a regression is visible.
3. **If the gain is inside the noise, drop the candidate.** Revert it, delete the branch, and
   report it as investigated-and-rejected. Shipping noise costs review time and adds risk.
4. **Assert identical output.** The benchmark compares results between old and new code, or the
   package test suite does. A faster wrong answer is a bug.
5. **Run the baseline test suite before blaming yourself.** Many suites have pre-existing
   failures (flaky timing assertions, snapshot/libxml drift, stale caches). Verify on the
   untouched base branch, then state explicitly which failures are pre-existing.
6. **Prefer algorithmic wins.** `O(n²) -> O(n)` beats any amount of micro-tuning. Look for
   repeated work first: a copy per character, a filesystem walk per lookup, a render per row.
7. **One improvement, one branch, one commit.** Even within the same package. A surgical diff
   is reviewable; a 6-in-1 perf commit is not.
8. **Never invent an improvement to fill a package.** If a package has no real hot path,
   say so. An honest "nothing found in Turbo" is a valid deliverable.
9. **Never use `git stash` to A/B two versions.** It pops the user's existing stashes and
   destroys work. Copy files to the scratchpad instead (see Command Reference).

## Guidelines

### Where the wins actually are

| Look here | Skip |
|-----------|------|
| Code running per request, per render, per DOM element, per row | One-shot boot / DI compilation |
| Loops calling a function that re-derives the same value | Code already behind a warm cache |
| Reflection, `debug_backtrace()`, exception construction in a hot path | Error paths, CLI-only commands (unless they *are* the complaint) |
| Filesystem access inside a generator that gets re-iterated | Anything a profiler shows under 2% |
| Regex compiled per call, per key, or per character | Regex literals in JS (V8 already caches them) |

### Traps that produce false results

| Trap | Reality |
|------|---------|
| `class_exists()` looks expensive | Once the class is loaded it is a hashtable lookup. OPcache does not fold it, but it costs ~50-100ns. Measure before "fixing" it. |
| Extracting a helper method to replace inline `substr()` | PHP method-call overhead can exceed the allocation you removed. This can be a *regression*. Measure. |
| Hoisting regex literals in JS | V8 caches the compiled regex per literal. Expect ~0%. Caching a `new RegExp(dynamicPattern)` is a real win; hoisting a literal is not. |
| `isset($a, $b, $c)` | That is AND, not OR. To test "any of these keys exists", chain `||`. |
| Replacing `usort` with a manual sort | `usort` is stable since PHP 8.0. Preserve the exact order semantics, including a trailing `array_reverse`. |
| Monorepo sibling packages | A package may install its sibling from Packagist, not the local path. Editing `src/A` will not affect `src/B`'s tests. Copy the patched file into `src/B/vendor/...` to benchmark, and say so in the commit. |
| Blackfire numbers do not match raw numbers | Instrumentation adds per-call overhead, which flattens wins that come from removing *calls* and inflates wins from removing *allocations*. Report both raw and Blackfire figures. |
| A test suite that suddenly fails | Clear the framework cache (move it aside, do not `rm -rf`) and re-run. Stale Symfony caches produce phantom failures. |

### Writing a benchmark

- Reproduce the **shape** of production, not just the operation: realistic call-stack depth,
  realistic collection sizes, realistic repetition of the same key.
- Loop enough to get 100ms+ of work, and run each side at least 3 times.
- Print the numbers, and print whether old and new output match.
- Keep it standalone (one file, one `require`), so it can be pasted into the commit message.
- For Blackfire, cut the iteration count by 10-40x; instrumentation is 5-20x slower.

## Command Reference

```bash
# Profile a script (symfony CLI picks the right PHP version)
blackfire run --title "Subject - before" symfony php bench.php

# Profile a command that exits non-zero (e.g. a suite with a known failure)
blackfire run --ignore-exit-status --title "Subject - after" symfony php vendor/bin/phpunit --filter '...'

# JS: build first, then benchmark the built output
pnpm --filter <package> run build && node bench.mjs
```

Blackfire URLs:

| Kind | Format |
|------|--------|
| Profile | `https://blackfire.io/profiles/<uuid>/graph` (printed by the CLI) |
| Comparison | `https://app.blackfire.io/profiles/compare/<before-uuid>...<after-uuid>/graph` |

A/B two versions of a file **without `git stash`**:

```bash
S=<scratchpad>
cp path/to/File.php $S/File.new.php          # save the candidate
git checkout <base> -- path/to/File.php      # back to baseline
<run benchmark>                              # BEFORE
cp $S/File.new.php path/to/File.php          # restore the candidate
<run benchmark>                              # AFTER
```

## Workflow

1. **Map the hot paths.** Read the code that runs per request / per render / per element.
   List candidates with a one-line hypothesis each. Do not start editing.
2. **Build a benchmark** for the top candidate and record the **baseline** (3+ runs).
3. **Implement the smallest possible change.**
4. **Re-measure.** Confirm the gain is outside run-to-run noise, and that output is identical.
   If not: revert, drop the candidate, move on.
5. **Profile with Blackfire** before and after, with `--title` on each run. Keep both UUIDs.
6. **Run the package test suite**, and run it on the untouched base branch too. Classify every
   failure as caused-by-me or pre-existing.
7. **Lint and format**: `php-cs-fixer`, `oxlint`, `oxfmt`, `twig-cs-fixer` as applicable.
   For JS packages, rebuild and commit `dist/` if the repo tracks it.
8. **Branch and commit** — one branch per improvement, off the target base branch.
9. **Report**, including what was investigated and rejected, and which failures were pre-existing.

## Commit Message Format

Use the repository's PR template when it has one, then: what was slow and why, the fix, the raw
numbers, the benchmark script in a fenced block, and the Blackfire links as a bullet list.

````
[Package] Short imperative title

| Q              | A
| -------------- | ---
| Bug fix?       | no
| New feature?   | no
| Deprecations?  | no
| Documentation? | no
| Issues         | -
| License        | MIT

`consume()` built a copy of the whole remaining template on every call via
`substr()`, and it is called several times per character in the main scan
loop. Pre-lexing was therefore quadratic in template size.

Reuse `check()`, which compares in place with `substr_compare()`.

Pre-lexing a 154 KB template goes from ~724 ms to ~94 ms, and scaling is
now linear.

Benchmarked from the repository root with `blackfire run symfony php bench.php`:

```php
<?php
require __DIR__.'/src/TwigComponent/vendor/autoload.php';
// ... standalone, runnable, self-contained
```

Blackfire:

- before — 3.34s wall / 3.18s CPU: https://blackfire.io/profiles/<before>/graph
- after — 2.22s wall / 2.19s CPU: https://blackfire.io/profiles/<after>/graph
- diff: https://app.blackfire.io/profiles/compare/<before>...<after>/graph
````

If the change is browser-side JavaScript, say so explicitly ("no Blackfire profile for this
one") and give the node or vitest command instead.

## Examples

### "Make TwigComponent faster"

1. Read `TwigPreLexer`, `ComponentFactory`, `ComponentRenderer`, `ComponentAttributes`.
2. Spot `consume()` calling `substr($input, $position)` — a full copy of the remainder, several
   times per character. Hypothesis: quadratic.
3. Benchmark across sizes to confirm the curve: 3 KB -> 1.9 ms, 154 KB -> 724 ms. Superlinear.
4. Replace with `check()` (`substr_compare`, no copy). 154 KB -> 94 ms, and now linear.
5. Blackfire before/after, tests, one branch, one commit.

### A candidate that must be dropped

`StimulusAttributes::escape()` calls `class_exists()` on every attribute. Looks wasteful.
Measured: 11 ms out of 412 ms (2.7%), and caching it produced 382-425 ms against a 412 ms
baseline — pure noise. Reverted, branch deleted, reported as investigated-and-rejected.

### A candidate that turned out to be a regression

Replacing six inline `substr()` comparisons with calls to `check()` made the block-heavy
benchmark go from 64 ms to 90 ms: the method-call overhead exceeded the saved allocations.
The fix that actually worked was a guard on the three characters that can start a delimiter,
keeping the inline `substr()`: 64 ms -> 16 ms.
