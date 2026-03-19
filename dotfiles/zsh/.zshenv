# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

export LANG=fr_FR.UTF-8
export LC_ALL=fr_FR.UTF-8
export TIMEFMT=$'%J\n%U user\n%S system\n%P cpu\n%*E total'

export PATH="$PATH:$HOME/.local/bin"
# Composer
export PATH="$HOME/.composer/vendor/bin:$PATH"
# Rust
export PATH="$HOME/.cargo/bin:$PATH"
# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias sf="symfony"
alias sfc="symfony console"
alias sfcp="symfony composer"
alias sfp="symfony php"
alias ux="cd ~/workspace/symfony/ux"
alias uxc="cd ~/workspace/symfony/ux.symfony.com"
alias ux-link="~/workspace/symfony/ux/link ."
alias encore="cd ~/workspace/symfony/webpack-encore"

_log_info() {
    echo -e "\033[1;34m[INFO]\033[0m $*"
}
_log_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $*"
}
_log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $*"
}
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

source ~/.zshenv.os
