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

source ~/.zshenv.os
