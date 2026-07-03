# Logging helpers
_log_info()    { echo -e "\033[1;34m[INFO]\033[0m $*"; }
_log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $*"; }
_log_error()   { echo -e "\033[1;31m[ERROR]\033[0m $*"; }
_log_execution() {
  _log_info "Executing: $*"
  "$@"
  local cmd_status=$?
  if [ $cmd_status -eq 0 ]; then
    _log_success "Command succeeded: $*"
  else
    _log_error "Command failed with status $cmd_status: $*"
  fi
  return $cmd_status
}

# Resync a fork branch with its upstream, then force-push to origin.
git-fork-resync-branch() {
  if [ -z "$1" ]; then
    _log_error "Usage: git-fork-resync-branch <branch-name>"
    return 1
  fi

  local branch="$1"
  local remote_upstream="upstream"
  local remote_origin="origin"

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    _log_error "Not inside a git repository."
    return 1
  fi

  if ! git rev-parse --verify "$branch" >/dev/null 2>&1; then
    _log_error "Branch '$branch' does not exist."
    return 1
  fi

  if ! git remote | grep -q "$remote_upstream"; then
    _log_error "Remote '$remote_upstream' not found."
    return 1
  fi

  _log_execution git fetch "$remote_upstream" || return 1
  _log_execution git checkout "$branch" || return 1
  _log_execution git reset --hard "$remote_upstream/$branch" || return 1
  _log_execution git push --force "$remote_origin" HEAD || return 1

  _log_success "Branch '$branch' successfully resynced with $remote_upstream."
}
