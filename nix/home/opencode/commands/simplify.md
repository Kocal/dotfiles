---
description: Clean up the current changes for reuse, simplicity, efficiency and altitude, without changing behavior
---

Review the changes in progress and tidy them up. This is a cleanup pass, not a bug hunt: never change what the code does.

Scope: `$ARGUMENTS`. If it is empty, review the working copy (`git diff` and `git diff --cached`). If there are no uncommitted changes, review the commits of the current branch against the repository's default branch (`git log <base>..HEAD`, `git diff <base>...HEAD`), where `<base>` is `upstream/HEAD` when an `upstream` remote exists, else `origin/HEAD`, else a local `main` or `master`. If `$ARGUMENTS` is a path or a commit range, restrict the review to it.

Read each changed file in full, not just the hunks, then look at the changes through four lenses:

1. Reuse: does the repo already have a helper, constant, type or pattern that does the same thing? Replace the new copy with the existing one.
2. Simplification: can the same behavior be written with less code, fewer branches, fewer variables or flatter control flow? Remove dead code, needless indirection and comments that restate the code.
3. Efficiency: is there work that is not needed, such as repeated computation, redundant I/O or queries, loops that can be hoisted, or data converted back and forth?
4. Altitude: is logic placed at the wrong level, such as business rules in a controller, formatting in a model, or a generic helper buried in a specific module? Move it where it belongs, only if the move is small and safe.

Apply the fixes directly. Keep each edit minimal, leave unrelated code alone, and run the project's existing tests or linters when there is a quick way to do so. If a cleanup might alter behavior, skip it.

Finish with two lists: the changes you made, and the candidates you rejected, each with the reason.
