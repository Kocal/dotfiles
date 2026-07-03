# Dotfiles

Personal macOS (Apple Silicon) dotfiles, built on nix-darwin + home-manager. Everything is declarative in `nix/`. The darwinConfiguration is named `MacBook-Pro-de-Hugo` and the repo is expected to live at `~/workspace/kocal/dotfiles`.

## Install

Clone the repo:

```shell
mkdir -p ~/workspace/kocal && cd $_
git clone https://github.com/Kocal/dotfiles.git dotfiles && cd dotfiles
git remote set-url origin git@github.com:Kocal/dotfiles.git
```

Install the Xcode command-line tools and Nix:

```shell
xcode-select --install
curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh
```

Bootstrap nix-darwin (first run only):

```shell
sudo nix run nix-darwin/master#darwin-rebuild --extra-experimental-features "nix-command flakes" -- switch --flake "$PWD/nix"
```

All subsequent rebuilds:

```shell
sudo darwin-rebuild switch --flake "$PWD/nix"
```

## Layout

```
nix/
  flake.nix         flake inputs, system packages, homebrew casks
  home.nix          home-manager entrypoint, imports all home/ modules
  home/
    options.nix     dotfiles.dir option (defaults to ~/workspace/kocal/dotfiles)
    git.nix         programs.git: SSH signing via 1Password's op-ssh-sign
    zsh.nix         zsh + Starship, aliases, shell functions
    vim.nix         programs.vim: plugins + vimrc
    node.nix        fnm (Node version manager)
    php.nix         PHP 8.1-8.5 + composer + symfony-cli
    claude.nix      ~/.claude/* symlinked out-of-store to nix/home/claude/
    ghostty.nix     Ghostty config (app itself is a Homebrew cask)
```

### System packages

CLI tools and GUI apps go into `environment.systemPackages` in `flake.nix` when they're available and working in nixpkgs: things like `gh`, `bat`, `ripgrep`, `ffmpeg`, `claude-code`, `orbstack`, `jetbrains-toolbox`, `rectangle-pro`, and more. See `flake.nix` for the full list.

GUI apps installed this way get copied as real `.app` bundles into `/Applications/Nix Apps`, so Spotlight and Launchpad find them automatically.

Homebrew casks (`homebrew.casks` in `flake.nix`) are for apps that can't come from Nix: not in nixpkgs, darwin build broken (GTK/Qt deps, appstream/libadwaita), or strict signing and location requirements (1Password, Cloudflare WARP). Current casks include Ghostty, 1Password, Inkscape, Pinta, Affinity, mGBA, and a few others; see `flake.nix`.

### Home-manager modules

- **git** (`home/git.nix`): commits and tags signed via 1Password's `op-ssh-sign`. Machine-local overrides (different email, signing key, etc.) go in `~/.gitconfig.local`, included but not managed by Nix.
- **zsh** (`home/zsh.nix`): native completion, autosuggestions, syntax highlighting, Starship prompt. Aliases and shell functions are in `nix/home/zsh/functions.zsh`. Loads `~/.zshrc.local` if it exists.
- **vim** (`home/vim.nix`): plugins (vim-sensible, vim-obsession, vim-airline, vim-solarized8) via Nix; config from `nix/home/vim/vimrc.vim`.
- **node** (`home/node.nix`): fnm as the version manager. Nix installs fnm itself; you still need to run `fnm install --lts` (or a specific version) after first setup.
- **php** (`home/php.nix`): PHP 8.1-8.5, each with xdebug, apcu, blackfire probe, and opcache. Default unversioned `php` is 8.4. Versioned binaries (`php8.1` ... `php8.5`) are on PATH so the Symfony CLI picks the right one via `.php-version`. PHP 8.1 comes from the `phps` input (EOL, dropped from nixpkgs).
- **claude** (`home/claude.nix`): `~/.claude/settings.json`, `~/.claude/CLAUDE.md`, `~/.claude/agents/`, `~/.claude/skills/`, and `~/.claude/agent-memory/` are all out-of-store symlinks pointing back into `nix/home/claude/`. Runtime writes by Claude land in the repo, not a read-only store path.
- **ghostty** (`home/ghostty.nix`): config written to `~/.config/ghostty/config` by home-manager. The app itself is a cask; nixpkgs ghostty is broken on darwin.

## Post-install

Steps Nix can't handle declaratively:

**RTK**: initialize the global config:

```shell
rtk init --global
```

**Blackfire**: configure the agent (credentials from your Blackfire account). Nix installs the binary but sets up no service, so start it yourself or add a launchd agent:

```shell
blackfire agent:config
```

**Node**: install at least one version via fnm:

```shell
fnm install --lts
```

## Maintenance

### Update

Dependencies are pinned in `nix/flake.lock`. Updating bumps a flake input and rebuilds; there is no per-package pin, so a package's version follows whatever input it comes from. Most CLI tools and apps (including `claude-code`, `gh`, `php`, the GUI apps) come from `nixpkgs`.

Update everything:

```shell
nix flake update --flake "$PWD/nix"
sudo darwin-rebuild switch --flake "$PWD/nix"
```

Update a single input:

```shell
nix flake update nixpkgs --flake "$PWD/nix"   # bumps everything from nixpkgs: claude-code, gh, php, GUI apps, ...
# other inputs: home-manager, nix-darwin, phps, nix-homebrew
sudo darwin-rebuild switch --flake "$PWD/nix"
```

"Update just Claude Code" means updating the full `nixpkgs` input, which moves every nixpkgs package to the channel's latest at once. Commit the resulting `flake.lock` change to keep the machine reproducible.

Homebrew casks (1Password, Ghostty, ...) are managed by Homebrew, not the lock file. Upgrade them with `brew upgrade`, or set `homebrew.onActivation.upgrade = true;` in `flake.nix` to upgrade them automatically on every `darwin-rebuild switch`.

Roll back a bad update:

```shell
sudo darwin-rebuild --rollback
```

### Add a package

For CLI tools or Nix-packaged GUI apps, add to `environment.systemPackages` in `nix/flake.nix`, then rebuild. For casks, add the cask name to `homebrew.casks`; if it's from a third-party tap, add the tap to `nix-homebrew.taps` as well.
