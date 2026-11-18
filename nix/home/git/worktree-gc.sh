#!/usr/bin/env bash
set -euo pipefail

repo_of() {
  printf '%s\n' "${1%%/.claude/worktrees/*}"
}

base_of() {
  local ref
  for ref in upstream/main upstream/master origin/main origin/master; do
    if git -C "$1" rev-parse --verify --quiet "$ref" >/dev/null; then
      printf '%s\n' "$ref"
      return
    fi
  done
}

pr_state() {
  [ -n "$2" ] || return 0
  (cd "$1" && gh pr list --state all --head "$2" --json state --jq '.[0].state // empty' 2>/dev/null) || true
}

classify() {
  local wt=$1 repo branch head base in_base=no pr dirty
  repo=$(repo_of "$wt")
  if [ ! -d "$wt" ]; then
    printf 'PRUNE|%s||missing on disk\n' "$wt"
    return
  fi
  branch=$(git -C "$wt" symbolic-ref --quiet --short HEAD 2>/dev/null || true)
  head=$(git -C "$wt" rev-parse HEAD 2>/dev/null || true)
  if [ -z "$head" ]; then
    printf 'ASK|%s|%s|unreadable\n' "$wt" "$branch"
    return
  fi
  base=$(base_of "$repo")
  if [ -n "$base" ] && git -C "$repo" merge-base --is-ancestor "$head" "$base" 2>/dev/null; then
    in_base=yes
  fi
  pr=$(pr_state "$repo" "$branch")
  dirty=$(git -C "$wt" status --porcelain --untracked-files=normal 2>/dev/null || echo unknown)

  if [ -n "$dirty" ]; then
    printf 'ASK|%s|%s|uncommitted changes\n' "$wt" "$branch"
  elif [ "$pr" = MERGED ]; then
    printf 'SAFE|%s|%s|PR merged\n' "$wt" "$branch"
  elif [ -n "$branch" ] && [ "$in_base" = yes ]; then
    printf 'SAFE|%s|%s|already in %s\n' "$wt" "$branch" "$base"
  elif [ "$pr" = CLOSED ]; then
    printf 'ASK|%s|%s|PR closed without merge\n' "$wt" "$branch"
  elif [ -z "$branch" ]; then
    printf 'ASK|%s||detached HEAD\n' "$wt"
  elif [ "$pr" = OPEN ]; then
    printf 'ASK|%s|%s|PR open\n' "$wt" "$branch"
  else
    printf 'ASK|%s|%s|no PR, not in %s\n' "$wt" "$branch" "$base"
  fi
}

usage() {
  echo "usage: worktree-gc [--dry-run] [--yes] [--root <dir>]" >&2
  exit 2
}

list_worktrees() {
  local gitdir key value
  for gitdir in "$1"/*/.git "$1"/*/*/.git; do
    [ -e "$gitdir" ] || continue
    git -C "${gitdir%/.git}" worktree list --porcelain 2>/dev/null | while read -r key value; do
      case "$key $value" in
        "worktree "*/.claude/worktrees/*) printf '%s\n' "$value" ;;
      esac
    done || true
  done
}

remove_worktree() {
  local repo err
  repo=$(repo_of "$1")
  if ! err=$(git -C "$repo" worktree remove --force "$1" 2>&1); then
    echo "      not removed: $err" >&2
    return 1
  fi
  if [ -n "$2" ] && ! git -C "$repo" branch -D "$2" >/dev/null 2>&1; then
    echo "      branch $2 not deleted" >&2
  fi
}

size_kb() {
  local kb
  kb=$(du -sk "$1" 2>/dev/null | cut -f1 || true)
  printf '%s\n' "${kb:-0}"
}

fmt_gb() {
  local tenths=$(( $1 * 10 / 1048576 ))
  printf '%d,%d Go' "$(( tenths / 10 ))" "$(( tenths % 10 ))"
}

age_days() {
  local mtime
  mtime=$(stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || date +%s)
  printf '%d' "$(( ( $(date +%s) - mtime ) / 86400 ))"
}

main() {
  local dry_run=0 yes=0 root="$HOME/workspace" lines state wt branch reason kb answer freed=0
  while [ $# -gt 0 ]; do
    case $1 in
      --dry-run) dry_run=1 ;;
      --yes) yes=1 ;;
      --root) shift; [ $# -gt 0 ] || usage; root=$1 ;;
      *) usage ;;
    esac
    shift
  done

  lines=$(list_worktrees "$root" | while read -r wt; do classify "$wt"; done | sort -t '|' -k1,1r -k2,2)
  if [ -z "$lines" ]; then
    echo "no .claude/worktrees/* worktree under $root"
    return
  fi

  while IFS='|' read -r -u 3 state wt branch reason; do
    case $state in
      PRUNE)
        echo "PRUNE $wt  $reason"
        [ $dry_run = 1 ] || git -C "$(repo_of "$wt")" worktree prune
        ;;
      SAFE)
        kb=$(size_kb "$wt")
        echo "SAFE  $wt  $reason, $(fmt_gb "$kb")"
        if [ $dry_run = 0 ] && remove_worktree "$wt" "$branch"; then
          freed=$(( freed + kb ))
        fi
        ;;
      ASK)
        kb=$(size_kb "$wt")
        echo "ASK   $wt  $reason, $(fmt_gb "$kb"), $(age_days "$wt")d"
        [ $dry_run = 0 ] || continue
        if [ $yes = 1 ]; then
          answer=y
        else
          read -r -p "      remove? [y/N] " answer || { answer=n; echo; }
        fi
        case $answer in
          y|Y)
            if remove_worktree "$wt" "$branch"; then
              freed=$(( freed + kb ))
            fi
            ;;
          *) echo "      kept" ;;
        esac
        ;;
    esac
  done 3<<EOF
$lines
EOF

  if [ $dry_run = 1 ]; then
    echo "dry run, nothing removed"
  else
    echo "freed $(fmt_gb "$freed")"
  fi
}

if [ "${WORKTREE_GC_TEST:-}" != 1 ]; then
  main "$@"
fi
