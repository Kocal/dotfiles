# Dotfiles

My personal configuration files for various applications and tools.

## Installation

Clone the repository:
```shell
[ "$(uname -s)" = "Linux" ] && sudo apt update && sudo apt install -y git
mkdir -p ~/workspace/kocal && cd $_
git clone https://github.com/Kocal/dotfiles.git dotfiles && cd $_
git remote set-url origin git@github.com:Kocal/dotfiles.git
```

Install mandatory softwares:
```shell
# Prerequisites
[ "$(uname -s)" = "Darwin" ] && xcode-select --install
[ "$(uname -s)" = "Linux" ] && sudo apt update && sudo apt install -y curl wget build-essential autoconf

# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# GNU Make for MacOS
[ "$(uname -s)" = "Darwin" ] && brew install make
```

- **1Password CLI** ([MacOS](https://developer.1password.com/docs/cli/get-started/#install) / [Linux](https://developer.1password.com/docs/cli/get-started/#install-linux))

## git

Install dotfiles:
```shell
[ -f ~/.gitconfig ] && mv ~/.gitconfig{,.back}
ln -s "$PWD/dotfiles/git/.gitconfig" ~/.gitconfig

[ -f ~/.gitignore_global ] && mv ~/.gitignore_global{,.back}
ln -s "$PWD/dotfiles/git/.gitignore_global" ~/.gitignore_global

[ -f ~/.gitconfig.os ] && mv ~/.gitconfig.os{,.back}
ln -s "$PWD/dotfiles/git/.gitconfig.$(uname -s)" ~/.gitconfig.os
```

## GitHub CLI

```shell
brew install gh
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
mkdir -p ~/.local/bin

[ -f ~/.zshenv.os ] && mv ~/.zshenv.os{,.back}
ln -s "$PWD/dotfiles/zsh/.zshenv.$(uname -s)" ~/.zshenv.os

[ -f ~/.zshenv ] && mv ~/.zshenv{,.back}
ln -s "$PWD/dotfiles/zsh/.zshenv" ~/.zshenv

[ -f ~/.zshrc.os ] && mv ~/.zshrc.os{,.back}
ln -s "$PWD/dotfiles/zsh/.zshrc.$(uname -s)" ~/.zshrc.os

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

## PHP

### Prerequisites

```shell
[ "$(uname -s)" = "Darwin" ] && brew install autoconf bison re2c libiconv libxml2 sqlite # To complete...
[ "$(uname -s)" = "Linux" ] && sudo apt install -y pkg-config build-essential autoconf libc6-dev bison re2c libxml2-dev \
  libsqlite3-dev libpq-dev libcurl4-openssl-dev libgd-dev libpng-dev zlib1g-dev libonig-dev libedit-dev libsodium-dev \
  libargon2-dev libtidy-dev libxslt1-dev libzip-dev
```

### PHP Integrated Environment (PIE)

```shell
[ -f ~/.local/bin/pie.phar ] && mv ~/.local/bin/pie.phar{,.back}
curl -fsSL  https://github.com/php/pie/releases/latest/download/pie.phar -o ~/.local/bin/pie.phar 
```

### Build from sources

Clone PHP sources:
```shell
PHP_VERSIONS=("8.1" "8.2" "8.3" "8.4" "8.5")

mkdir -p ~/workspace/php && cd $_
for PHP_VERSION in ${PHP_VERSIONS[@]}; do
  local branch="PHP-$PHP_VERSION"
  local directory="$branch"
  [ ! -d "$directory" ] && git clone https://github.com/php/php-src.git --single-branch --branch $branch $directory
  (cd $directory; git checkout $branch && git pull)
done
```

Build and install PHP:
```shell
PHP_CONFIGURE_FLAGS=(
  --enable-option-checking=fatal
  # GD
  --enable-gd --with-external-gd --with-avif --with-webp --with-jpeg --with-freetype
  # String & Encoding
  --enable-mbregex --enable-mbstring --with-iconv
  # Database
  --enable-dba --enable-mysqlnd --with-pdo-sqlite=/usr --with-sqlite3=/usr --with-pdo-pgsql=/usr --with-pgsql=/usr
  # Web & FPM
  --disable-cgi --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data
  # Math & File
  --enable-bcmath --enable-calendar --enable-exif --enable-ftp
  # Network & Protocol
  --with-curl --enable-soap --enable-sockets
  # Process & System
  --enable-pcntl --enable-shmop --enable-sysvmsg --enable-sysvsem --enable-sysvshm
  # Internationalization
  --enable-intl
  # Debugging
  --enable-phpdbg --enable-phpdbg-readline
  # Security & Cryptography
  --with-password-argon2 --with-sodium --with-openssl --with-mhash
  # Libraries
  --with-external-pcre --with-ffi --with-libxml --with-libedit --with-readline --with-zlib --with-tidy --with-xsl --with-zip --with-pic
)
declare -A PHP_CONFIGURE_FLAGS_PER_VERSION=(
  ["8.1"]="--enable-opcache"
  ["8.2"]="--enable-opcache"
  ["8.3"]="--enable-opcache"
  ["8.4"]="--enable-opcache"
  ["8.5"]=""
)

for PHP_VERSION in ${PHP_VERSIONS[@]}; do
  echo "Building PHP $PHP_VERSION..."
  
  cd ~/workspace/php/PHP-$PHP_VERSION \
    && ./buildconf --force \
    && ./configure \
      --prefix=$HOME/.local/php-$PHP_VERSION \
      --with-config-file-path=$HOME/.local/etc/php-$PHP_VERSION \
      --with-config-file-scan-dir=$HOME/.local/etc/php-$PHP_VERSION/conf.d \
      "${PHP_CONFIGURE_FLAGS[@]}" ${PHP_CONFIGURE_FLAGS_PER_VERSION[$PHP_VERSION]} \
    && make -j"$(nproc)" \
    && make install \
    && cd -
done
```

Configure `php.ini`:
```shell
for PHP_VERSION in ${PHP_VERSIONS[@]}; do
    mkdir -p ~/.local/etc/php-$PHP_VERSION/conf.d
    [ -f ~/.local/etc/php-$PHP_VERSION/php.ini ] && mv ~/.local/etc/php-$PHP_VERSION/php.ini{,.back}
    cp ~/workspace/php/PHP-$PHP_VERSION/php.ini-development ~/.local/etc/php-$PHP_VERSION/php.ini
    
    rm -f ~/.local/bin/php$PHP_VERSION
    ln -s ~/.local/php-$PHP_VERSION/bin/php ~/.local/bin/php$PHP_VERSION
done
```

### Install Composer

```shell
if [ command -v composer >/dev/null 2>&1 ]; then
    echo "Composer is already installed"
    composer self-update
else 
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php -r "if (hash_file('sha384', 'composer-setup.php') === 'c8b085408188070d5f52bcfe4ecfbee5f727afa458b2573b8eaaf77b3419b0bf2768dc67c86944da1544f06fa544fd47') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('composer-setup.php'); exit(1); }"
    php composer-setup.php
    php -r "unlink('composer-setup.php');"
    mv composer.phar ~/.local/bin/composer
fi 

command -v composer >/dev/null 2>&1 || { echo >&2 "Composer installation failed"; }
```

### Install XDebug

```shell
for PHP_VERSION in ${PHP_VERSIONS[@]}; do
    echo "Installing XDebug for PHP $PHP_VERSION..."
    ~/.local/php-$PHP_VERSION/bin/php ~/.local/bin/pie.phar install xdebug/xdebug
done
```

### Install APCu

```shell
for PHP_VERSION in ${PHP_VERSIONS[@]}; do
    echo "Installing APCu for PHP $PHP_VERSION..."
    ~/.local/php-$PHP_VERSION/bin/php ~/.local/bin/pie.phar install apcu/apcu
done
```

### Install OPCache

```shell
for PHP_VERSION in ${PHP_VERSIONS[@]}; do
    cp dotfiles/php/conf.d/opcache.ini ~/.local/etc/php-$PHP_VERSION/conf.d/ext-opcache.ini
    
    # opcache is built-in from PHP 8.5
    if [ "$PHP_VERSION" = "8.5" ]; then
      sed -i '/zend_extension=opcache/d' ~/.local/etc/php-$PHP_VERSION/conf.d/ext-opcache.ini
    fi
done
```

### Symfony CLI

```shell
brew install symfony-cli/tap/symfony-cli
```

### Blackfire

Install Blackfire Agent:
```shell
if [ "$(uname -s)" = "Linux" ]; then
    wget -q -O - https://packages.blackfire.io/gpg.key | sudo dd of=/usr/share/keyrings/blackfire-archive-keyring.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/blackfire-archive-keyring.asc] http://packages.blackfire.io/debian any main" | sudo tee /etc/apt/sources.list.d/blackfire.list    sudo apt update
    sudo apt update
    sudo apt install blackfire
fi
```

Configure Blackfire Agent (get credentials from https://app.blackfire.io/my/organizations):
```shell
sudo blackfire agent:config
if [ "$(uname -s)" = "Linux" ]; then
    sudo systemctl restart blackfire-agent
fi
```
Install the PHP Probe:
```shell
blackfire php:install
```
