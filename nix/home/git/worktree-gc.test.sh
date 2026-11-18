#!/usr/bin/env bash
set -u
here=$(cd "$(dirname "$0")" && pwd)
script="$here/worktree-gc.sh"
passed=0
failed=0

assert_eq() {
  if [ "$1" = "$2" ]; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
    echo "FAIL $3: expected '$1', got '$2'"
  fi
}

setup() {
  tmp=$(cd "$(mktemp -d)" && pwd -P)
  mkdir -p "$tmp/bin" "$tmp/gh-states" "$tmp/workspace/org" "$tmp/remotes"
  cat > "$tmp/bin/gh" <<EOF
#!/bin/sh
[ -e "$tmp/gh-fail" ] && exit 1
branch=""
while [ \$# -gt 0 ]; do [ "\$1" = "--head" ] && branch="\$2"; shift; done
[ -f "$tmp/gh-states/\$branch" ] && cat "$tmp/gh-states/\$branch"
exit 0
EOF
  chmod +x "$tmp/bin/gh"
  printf '[user]\n\tname = t\n\temail = t@t\n[commit]\n\tgpgsign = false\n[init]\n\tdefaultBranch = main\n' > "$tmp/gitconfig"
  export GIT_CONFIG_GLOBAL="$tmp/gitconfig"
  export PATH="$tmp/bin:$PATH"
}

teardown() {
  rm -rf "$tmp"
}

make_repo() {
  local name=$1 parent=${2-org} dir
  dir="$tmp/workspace${parent:+/$parent}/$name"
  git init -q --bare -b main "$tmp/remotes/$name.git"
  git init -q -b main "$dir"
  git -C "$dir" remote add origin "$tmp/remotes/$name.git"
  echo "$name" > "$dir/README.md"
  git -C "$dir" add README.md
  git -C "$dir" commit -q -m init
  git -C "$dir" push -q -u origin main
  echo "$dir"
}

make_wt() {
  local repo=$1 name=$2 branch=$3 path="$1/.claude/worktrees/$2"
  if [ "$branch" = detached ]; then
    git -C "$repo" worktree add -q --detach "$path"
  else
    git -C "$repo" worktree add -q -b "$branch" "$path"
  fi
  echo "$path"
}

commit_in() {
  git -C "$1" commit -q --allow-empty -m "work"
}

gh_state() {
  echo "$2" > "$tmp/gh-states/$1"
}

state_and_reason() {
  (set -euo pipefail; classify "$1") | cut -d'|' -f1,4
}

run_gc() {
  WORKTREE_GC_TEST= bash "$script" --root "$tmp/workspace" "$@"
}

worktree_registered() {
  git -C "$1" worktree list --porcelain | grep -q "^worktree $2\$" && echo yes || echo no
}

# shellcheck source=worktree-gc.sh
WORKTREE_GC_TEST=1 . "$script"
set +e +o pipefail

classifies_merged_clean_as_safe() {
  setup
  repo=$(make_repo r)
  wt=$(make_wt "$repo" feat feat)
  commit_in "$wt"
  gh_state feat MERGED

  result=$(state_and_reason "$wt")

  assert_eq "SAFE|PR merged" "$result" "${FUNCNAME[0]}"
  teardown
}

classifies_ancestor_clean_as_safe() {
  setup
  repo=$(make_repo r)
  wt=$(make_wt "$repo" landed landed)

  result=$(state_and_reason "$wt")

  assert_eq "SAFE|already in origin/main" "$result" "${FUNCNAME[0]}"
  teardown
}

classifies_dirty_merged_as_ask() {
  setup
  repo=$(make_repo r)
  wt=$(make_wt "$repo" feat feat)
  commit_in "$wt"
  gh_state feat MERGED
  echo changed > "$wt/README.md"

  result=$(state_and_reason "$wt")

  assert_eq "ASK|uncommitted changes" "$result" "${FUNCNAME[0]}"
  teardown
}

classifies_closed_as_ask() {
  setup
  repo=$(make_repo r)
  wt=$(make_wt "$repo" feat feat)
  commit_in "$wt"
  gh_state feat CLOSED

  result=$(state_and_reason "$wt")

  assert_eq "ASK|PR closed without merge" "$result" "${FUNCNAME[0]}"
  teardown
}

classifies_detached_as_ask() {
  setup
  repo=$(make_repo r)
  wt=$(make_wt "$repo" bench detached)
  commit_in "$wt"

  result=$(state_and_reason "$wt")

  assert_eq "ASK|detached HEAD" "$result" "${FUNCNAME[0]}"
  teardown
}

classifies_open_as_ask() {
  setup
  repo=$(make_repo r)
  wt=$(make_wt "$repo" feat feat)
  commit_in "$wt"
  gh_state feat OPEN

  result=$(state_and_reason "$wt")

  assert_eq "ASK|PR open" "$result" "${FUNCNAME[0]}"
  teardown
}

classifies_no_pr_as_ask() {
  setup
  repo=$(make_repo r)
  wt=$(make_wt "$repo" feat feat)
  commit_in "$wt"

  result=$(state_and_reason "$wt")

  assert_eq "ASK|no PR, not in origin/main" "$result" "${FUNCNAME[0]}"
  teardown
}

classifies_branch_without_base_as_ask() {
  setup
  repo=$(make_repo r)
  git -C "$repo" remote remove origin
  wt=$(make_wt "$repo" feat feat)
  commit_in "$wt"

  result=$(state_and_reason "$wt")

  assert_eq "ASK|no PR, not in " "$result" "${FUNCNAME[0]}"
  teardown
}

treats_gh_failure_as_no_pr() {
  setup
  repo=$(make_repo r)
  wt=$(make_wt "$repo" feat feat)
  commit_in "$wt"
  touch "$tmp/gh-fail"

  result=$(state_and_reason "$wt")

  assert_eq "ASK|no PR, not in origin/main" "$result" "${FUNCNAME[0]}"
  teardown
}

classifies_missing_dir_as_prune() {
  setup
  repo=$(make_repo r)
  wt=$(make_wt "$repo" feat feat)
  rm -rf "$wt"

  result=$(state_and_reason "$wt")

  assert_eq "PRUNE|missing on disk" "$result" "${FUNCNAME[0]}"
  teardown
}

dry_run_removes_nothing() {
  setup
  repo=$(make_repo r)
  wt=$(make_wt "$repo" landed landed)

  output=$(run_gc --dry-run </dev/null)

  assert_eq "yes" "$([ -d "$wt" ] && echo yes || echo no)" "${FUNCNAME[0]} dir kept"
  assert_eq "yes" "$(echo "$output" | grep -q SAFE && echo yes || echo no)" "${FUNCNAME[0]} output"
  teardown
}

removes_safe_without_prompt() {
  setup
  repo=$(make_repo r)
  wt=$(make_wt "$repo" landed landed)

  output=$(run_gc </dev/null)

  assert_eq "no" "$([ -d "$wt" ] && echo yes || echo no)" "${FUNCNAME[0]} dir removed"
  assert_eq "" "$(git -C "$repo" branch --list landed)" "${FUNCNAME[0]} branch deleted"
  assert_eq "yes" "$(echo "$output" | grep -q freed && echo yes || echo no)" "${FUNCNAME[0]} output"
  teardown
}

asks_before_removing_ask() {
  setup
  repo=$(make_repo r)
  wt=$(make_wt "$repo" feat feat)
  commit_in "$wt"

  run_gc </dev/null >/dev/null
  kept=$([ -d "$wt" ] && echo yes || echo no)
  printf 'y\n' | run_gc >/dev/null
  removed=$([ -d "$wt" ] && echo no || echo yes)

  assert_eq "yes" "$kept" "${FUNCNAME[0]} kept on no answer"
  assert_eq "yes" "$removed" "${FUNCNAME[0]} removed on yes"
  teardown
}

yes_flag_removes_ask() {
  setup
  repo=$(make_repo r)
  wt=$(make_wt "$repo" feat feat)
  commit_in "$wt"

  run_gc --yes </dev/null >/dev/null

  assert_eq "no" "$([ -d "$wt" ] && echo yes || echo no)" "${FUNCNAME[0]}"
  teardown
}

prunes_missing_worktree() {
  setup
  repo=$(make_repo r)
  wt=$(make_wt "$repo" feat feat)
  rm -rf "$wt"

  run_gc </dev/null >/dev/null

  assert_eq "no" "$(worktree_registered "$repo" "$wt")" "${FUNCNAME[0]}"
  teardown
}

finds_repos_at_depth_one_and_two() {
  setup
  solo=$(make_repo solo "")
  deep=$(make_repo deep org)
  wt1=$(make_wt "$solo" landed landed)
  wt2=$(make_wt "$deep" landed landed)

  output=$(run_gc --dry-run </dev/null)

  assert_eq "yes" "$(echo "$output" | grep -qF "$wt1" && echo yes || echo no)" "${FUNCNAME[0]} depth one"
  assert_eq "yes" "$(echo "$output" | grep -qF "$wt2" && echo yes || echo no)" "${FUNCNAME[0]} depth two"
  teardown
}

classifies_untracked_file_as_ask() {
  setup
  repo=$(make_repo r)
  wt=$(make_wt "$repo" landed landed)
  echo new > "$wt/notes.md"

  result=$(state_and_reason "$wt")

  assert_eq "ASK|uncommitted changes" "$result" "${FUNCNAME[0]}"
  teardown
}

ignores_gitignored_untracked_files() {
  setup
  repo=$(make_repo r)
  echo "build/" > "$repo/.gitignore"
  git -C "$repo" add .gitignore && git -C "$repo" commit -q -m ignore && git -C "$repo" push -q
  wt=$(make_wt "$repo" landed landed)
  mkdir "$wt/build" && echo out > "$wt/build/app.js"

  result=$(state_and_reason "$wt")

  assert_eq "SAFE|already in origin/main" "$result" "${FUNCNAME[0]}"
  teardown
}

classifies_large_dirty_tree_as_ask() {
  setup
  repo=$(make_repo r)
  wt=$(make_wt "$repo" feat feat)
  mkdir "$wt/many"
  for i in $(seq 1 4000); do echo "$i" > "$wt/many/file-$i.txt"; done
  git -C "$wt" add many && git -C "$wt" commit -q -m many
  for i in $(seq 1 4000); do echo changed > "$wt/many/file-$i.txt"; done

  result=$(state_and_reason "$wt")

  assert_eq "ASK|uncommitted changes" "$result" "${FUNCNAME[0]}"
  teardown
}

classifies_broken_gitdir_as_ask() {
  setup
  repo=$(make_repo r)
  wt=$(make_wt "$repo" feat feat)
  echo "gitdir: $tmp/nowhere" > "$wt/.git"

  result=$(state_and_reason "$wt")

  assert_eq "ASK|unreadable" "$result" "${FUNCNAME[0]}"
  teardown
}

survives_unreadable_file_in_worktree() {
  setup
  repo=$(make_repo r)
  wt=$(make_wt "$repo" landed landed)
  mkdir "$wt/secret" && chmod 000 "$wt/secret"

  output=$(run_gc --dry-run </dev/null)
  chmod 755 "$wt/secret"

  assert_eq "yes" "$(echo "$output" | grep -qF "$wt" && echo yes || echo no)" "${FUNCNAME[0]} listed"
  assert_eq "yes" "$(echo "$output" | grep -q 'dry run' && echo yes || echo no)" "${FUNCNAME[0]} completed"
  teardown
}

continues_after_failed_removal() {
  setup
  repo=$(make_repo r)
  wt1=$(make_wt "$repo" a-locked a-locked)
  wt2=$(make_wt "$repo" b-landed b-landed)
  git -C "$repo" worktree lock "$wt1"

  output=$(run_gc </dev/null 2>/dev/null)

  assert_eq "yes" "$([ -d "$wt1" ] && echo yes || echo no)" "${FUNCNAME[0]} locked kept"
  assert_eq "no" "$([ -d "$wt2" ] && echo yes || echo no)" "${FUNCNAME[0]} next removed"
  assert_eq "yes" "$(echo "$output" | grep -q '^freed 0,0 Go' && echo yes || echo no)" "${FUNCNAME[0]} freed excludes failure"
  teardown
}

skips_unusable_repo_during_discovery() {
  setup
  repo=$(make_repo zz)
  wt=$(make_wt "$repo" landed landed)
  mkdir -p "$tmp/workspace/org/aa/.git"

  output=$(run_gc --dry-run </dev/null 2>/dev/null)

  assert_eq "yes" "$(echo "$output" | grep -qF "$wt" && echo yes || echo no)" "${FUNCNAME[0]}"
  teardown
}

classifies_merged_clean_as_safe
classifies_ancestor_clean_as_safe
classifies_dirty_merged_as_ask
classifies_closed_as_ask
classifies_detached_as_ask
classifies_open_as_ask
classifies_no_pr_as_ask
classifies_branch_without_base_as_ask
treats_gh_failure_as_no_pr
classifies_missing_dir_as_prune
dry_run_removes_nothing
removes_safe_without_prompt
asks_before_removing_ask
yes_flag_removes_ask
prunes_missing_worktree
finds_repos_at_depth_one_and_two
classifies_untracked_file_as_ask
ignores_gitignored_untracked_files
classifies_large_dirty_tree_as_ask
classifies_broken_gitdir_as_ask
survives_unreadable_file_in_worktree
continues_after_failed_removal
skips_unusable_repo_during_discovery

echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
