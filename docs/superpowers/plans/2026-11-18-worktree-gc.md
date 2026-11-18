# worktree-gc Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A `worktree-gc` command that removes merged, clean `.claude/worktrees/*` worktrees under `~/workspace` and asks before removing anything else.

**Architecture:** One bash script `nix/home/git/worktree-gc.sh` with a pure `classify` function (prints `STATE|path|branch|reason`) and a thin main loop that acts on its output. A bash test script builds throwaway git repos with a fake `gh` on PATH and asserts on `--dry-run` output. `nix/home/git.nix` wraps the script in `pkgs.writeShellApplication` and adds it to `home.packages`.

**Tech Stack:** bash, git, coreutils, gh (from PATH), home-manager.

**Spec:** `docs/superpowers/specs/2026-11-18-worktree-gc-design.md`

## Global Constraints

- Script runs under `writeShellApplication`: `set -euo pipefail` is implied, every non-zero command must be guarded.
- `gh` is not a Nix runtime input; it comes from the user's PATH.
- Default root is `$HOME/workspace`; repos are matched at depth 1 and 2.
- Worktrees outside `.claude/worktrees/` are ignored.
- Dirty check uses `--untracked-files=normal`: untracked files count as work unless gitignored.

## Review Focus

- A repo with no remote at all (no base branch): classify must still work and report `no PR, not in <base>` with an empty base. Covered by Task 1 test `classifies_branch_without_base_as_ask`.
- `gh` unreachable or unauthenticated: must degrade to "no PR", never abort the run. Covered by Task 1 test `treats_gh_failure_as_no_pr`.
- A worktree with a merged PR but uncommitted changes must be ASK, not SAFE. Covered by Task 1 test `classifies_dirty_merged_as_ask`.
- A worktree directory deleted by hand but still registered: must be pruned, not crash `du`. Covered by Task 2 test `prunes_missing_worktree`.
- `--dry-run` must not call `git worktree remove` at all. Covered by Task 2 test `dry_run_removes_nothing`.

---

### Task 1: classify

**Files:**
- Create: `nix/home/git/worktree-gc.sh`
- Test: `nix/home/git/worktree-gc.test.sh`

**Interfaces:**
- Produces: `classify <worktree-path>` prints exactly one line `STATE|path|branch|reason` with STATE in `SAFE`, `ASK`, `PRUNE`; `branch` empty for detached HEAD. `repo_of <worktree-path>` prints the main repo path (everything before `/.claude/worktrees/`). `base_of <repo-path>` prints the first existing ref among `upstream/main upstream/master origin/main origin/master`, or nothing.
- Script accepts `WORKTREE_GC_TEST=1` to source only (define functions, skip main), so the test file can call `classify` directly.

- [ ] **Step 1: Write the failing tests** in `nix/home/git/worktree-gc.test.sh`

Fixture helper `make_repo <name>`: `git init -b main` a bare "remote", clone it into `$tmp/workspace/org/<name>`, one initial commit pushed to `origin/main`. Helper `make_wt <repo> <name> <branch|detached>`: `git worktree add` under `<repo>/.claude/worktrees/<name>`. Fake `gh` written to `$tmp/bin/gh`, prepended to PATH, that reads `--head <branch>` and prints the state from `$tmp/gh-states/<branch>` if that file exists, else nothing; exits 1 when `$tmp/gh-fail` exists.

Tests (each `assert_eq "<expected>" "$(classify "$wt" | cut -d'|' -f1,4)"`):

- `classifies_merged_clean_as_safe`: branch `feat`, gh state `MERGED`, clean -> `SAFE|PR merged`
- `classifies_ancestor_clean_as_safe`: branch `landed` with no new commit, no gh state -> `SAFE|already in origin/main`
- `classifies_dirty_merged_as_ask`: branch `feat`, gh `MERGED`, tracked file modified -> `ASK|uncommitted changes`
- `classifies_closed_as_ask`: gh `CLOSED`, one commit ahead -> `ASK|PR closed without merge`
- `classifies_detached_as_ask`: detached at a new commit -> `ASK|detached HEAD`
- `classifies_open_as_ask`: gh `OPEN`, one commit ahead -> `ASK|PR open`
- `classifies_no_pr_as_ask`: no gh state, one commit ahead -> `ASK|no PR, not in origin/main`
- `classifies_branch_without_base_as_ask`: repo whose `origin` remote was removed -> `ASK|no PR, not in `
- `treats_gh_failure_as_no_pr`: `$tmp/gh-fail` present, one commit ahead -> `ASK|no PR, not in origin/main`
- `classifies_missing_dir_as_prune`: `rm -rf` the worktree dir -> `PRUNE|missing on disk`

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash nix/home/git/worktree-gc.test.sh`
Expected: FAIL, `classify: command not found`

- [ ] **Step 3: Implement `repo_of`, `base_of`, `pr_state`, `classify` in `nix/home/git/worktree-gc.sh`**

`pr_state <repo> <branch>` runs `gh pr list --state all --head "$branch" --json state --jq '.[0].state // empty'` with `cd "$repo"`, `2>/dev/null || true`. Guard the file with `if [ "${WORKTREE_GC_TEST:-}" != 1 ]; then main "$@"; fi` at the bottom (main is defined in Task 2; define an empty `main` here).

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash nix/home/git/worktree-gc.test.sh`
Expected: `10 passed`

- [ ] **Step 5: Commit**

```bash
git add nix/home/git/worktree-gc.sh nix/home/git/worktree-gc.test.sh
git commit -m "add worktree-gc classification"
```

### Task 2: main loop, flags, Nix packaging

**Files:**
- Modify: `nix/home/git/worktree-gc.sh`
- Modify: `nix/home/git/worktree-gc.test.sh`
- Modify: `nix/home/git.nix`
- Modify: `README.md` (one line in the git section)

**Interfaces:**
- Consumes: `classify`, `repo_of` from Task 1.
- Produces: `main "$@"` parsing `--dry-run`, `--yes`, `--root <dir>`; `list_worktrees <root>` prints every `.claude/worktrees/*` worktree path registered in repos at depth 1 and 2 under root; `remove_worktree <path> <branch>` runs `git worktree remove --force` then `git branch -D` when branch is non-empty.

- [ ] **Step 1: Write the failing tests**

Run the script as a subprocess: `run_gc() { WORKTREE_GC_TEST= bash "$script" --root "$tmp/workspace" "$@" </dev/null; }`.

- `dry_run_removes_nothing`: one SAFE worktree, `run_gc --dry-run` -> directory still exists and output contains `SAFE`
- `removes_safe_without_prompt`: one SAFE worktree, `run_gc` (stdin `/dev/null`) -> directory gone, local branch gone, output contains `freed`
- `asks_before_removing_ask`: one ASK worktree, `run_gc` with stdin `/dev/null` -> directory still exists; `printf 'y\n' | run_gc` -> directory gone
- `yes_flag_removes_ask`: one ASK worktree, `run_gc --yes` -> directory gone
- `prunes_missing_worktree`: registered worktree whose dir was deleted, `run_gc` -> `git worktree list` no longer shows it
- `finds_repos_at_depth_one_and_two`: repos at `$tmp/workspace/solo` and `$tmp/workspace/org/repo`, each with one SAFE worktree, `run_gc --dry-run` output has both paths

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash nix/home/git/worktree-gc.test.sh`
Expected: the 6 new tests FAIL (directories still exist / output empty), the 10 from Task 1 still pass

- [ ] **Step 3: Implement `list_worktrees`, `remove_worktree`, `main`**

Prompt reads from stdin with `read -r -p "... [y/N] " answer || answer=n`, so a closed stdin means no. Size via `du -sk`, age via `stat -f %m` on macOS with `stat -c %Y` fallback. Print `freed <N> Go` at the end (sum of removed `du -sk`, divided by 1024*1024, one decimal).

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash nix/home/git/worktree-gc.test.sh`
Expected: `16 passed`

- [ ] **Step 5: Package in `nix/home/git.nix`**

In the `let` block: `worktreeGc = pkgs.writeShellApplication { name = "worktree-gc"; runtimeInputs = [ pkgs.git pkgs.coreutils ]; text = builtins.readFile ./git/worktree-gc.sh; };` and `home.packages = [ worktreeGc ];` in the module body. Add one README line under the git module description: `worktree-gc` removes merged `.claude/worktrees/*` worktrees under `~/workspace` and asks for the rest.

- [ ] **Step 6: Verify the build**

Run: `nix build --no-link --print-out-paths .#homeConfigurations.$(hostname -s).activationPackage 2>&1 | tail -3` from `nix/` (or the repo's documented switch command in dry-run form).
Expected: build succeeds; `shellcheck` run by `writeShellApplication` reports nothing.

- [ ] **Step 7: Run the real thing in dry-run**

Run: `worktree-gc --dry-run` after `home-manager switch`.
Expected: the ASK groups from the 2026-11-18 triage show up, no SAFE line (all SAFE ones were already removed by hand), nothing deleted.

- [ ] **Step 8: Commit**

```bash
git add nix/home/git/worktree-gc.sh nix/home/git/worktree-gc.test.sh nix/home/git.nix README.md
git commit -m "add worktree-gc"
```
