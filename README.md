# Dotfiles

My personal configuration files for various applications and tools.

## Installation

Install the repository (without git):
```shell
[ "$(uname -s)" = "Linux" ] && sudo apt update && sudo apt install -y git
mkdir -p ~/workspace/kocal && cd $_
git clone https://github.com/Kocal/dotfiles.git dotfiles
cd dotfiles
git remote set-url origin git@github.com:Kocal/dotfiles.git
```

Install mandatory softwares:
```shell
# Prerequisites
[ "$(uname -s)" = "Darwin" ] && xcode-select --install
[ "$(uname -s)" = "Linux" ] && sudo apt update && sudo apt install -y curl wget build-essential autoconf

# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Make
[ "$(uname -s)" = "Darwin" ] && brew install make

# 1Password CLI
# - MacOS: https://developer.1password.com/docs/cli/get-started/#install
# - Linux: https://developer.1password.com/docs/cli/get-started/#install-linux
```

## git

Install GitHub CLI:
```shell
# MacOS
[ "$(uname -s)" = "Darwin" ] && brew install gh

# Linux (https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian)
if [ "$(uname -s)" = "Linux" ]; then
	(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
		&& sudo mkdir -p -m 755 /etc/apt/keyrings \
		&& out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
		&& cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
		&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
		&& sudo mkdir -p -m 755 /etc/apt/sources.list.d \
		&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
		&& sudo apt update \
		&& sudo apt install gh -y
fi
```

Install dotfiles:
```shell
[ -f ~/.gitconfig ] && mv ~/.gitconfig{,.back}
ln -s "$PWD/dotfiles/git/.gitconfig" ~/.gitconfig

[ -f ~/.gitignore_global ] && mv ~/.gitignore_global{,.back}
ln -s "$PWD/dotfiles/git/.gitignore_global" ~/.gitignore_global

[ -f ~/.gitconfig.os ] && mv ~/.gitconfig.os{,.back}
ln -s "$PWD/dotfiles/git/.gitconfig.$(uname -s)" ~/.gitconfig.os
```

## zsh

Install zsh and Oh My Zsh:
```shell
# zsh
[ "$(uname -s)" = "Darwin" ] && brew install zsh
[ "$(uname -s)" = "Linux" ] && sudo apt install zsh

# Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

Install dotfiles:
```shell
[ -f ~/.zshenv ] && mv ~/.zshenv{,.back}
ln -s "$PWD/dotfiles/zsh/.zshenv" ~/.zshenv

[ -f ~/.zshenv.os ] && mv ~/.zshenv.os{,.back}
ln -s "$PWD/dotfiles/zsh/.zshenv.$(uname -s)" ~/.zshenv.os

[ -f ~/.zshrc ] && mv ~/.zshrc{,.back}
ln -s "$PWD/dotfiles/zsh/.zshrc" ~/.zshrc
```

## vim

Install vim and vim-plug:
```shell
# vim
[ "$(uname -s)" = "Darwin" ] && brew install vim
[ "$(uname -s)" = "Linux" ] && sudo apt install vim

# vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

Install dotfiles:
```shell
[ -f ~/.vimrc ] && mv ~/.vimrc{,.back}
ln -s "$PWD/dotfiles/vim/.vimrc" ~/.vimrc
```
