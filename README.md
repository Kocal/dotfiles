# Dotfiles

macOS (Apple Silicon) dotfiles, built on home-manager (standalone, no nix-darwin). Everything is declarative in `nix/`, and nothing needs `sudo` for daily use. Two machines share one base: personal and work. They diverge only on a handful of packages, driven by a `profile` argument (`perso` / `boulot`) in `flake.nix`. Each config is named after its profile, not the hostname: `homeConfigurations.perso` and `homeConfigurations.boulot`. The repo is expected to live at `~/workspace/kocal/dotfiles`.

## Install

Clone the repo:

```shell
mkdir -p ~/workspace/kocal && cd $_
git clone https://github.com/Kocal/dotfiles.git dotfiles && cd dotfiles
git remote set-url origin git@github.com:Kocal/dotfiles.git
```

Install the Xcode command-line tools and Nix. Installing Nix needs admin rights once (on a locked-down work Mac, IT installs it):

```shell
xcode-select --install
curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh
```

Homebrew is required: it installs every package except PHP and the tools home-manager configures. Install it with the official installer, in `/opt/homebrew`; like Nix, that needs admin rights once. On boulot, the `cloudflare-warp` cask ships a .pkg, so its install also needs admin rights.

First run. Flakes are not enabled yet, home-manager enables them itself afterwards:

```shell
export NIX_CONFIG="experimental-features = nix-command flakes"
# personal
nix run home-manager/release-26.05 -- switch -b hm-backup --flake "$PWD/nix#perso"
# work
nix run home-manager/release-26.05 -- switch -b hm-backup --flake "$PWD/nix#boulot"
```

All subsequent rebuilds. The profile is baked into `drs` at build time, so the same command works on both machines:

```shell
drs
# equivalent to:
home-manager switch -b hm-backup --flake "$PWD/nix#<profile>"
```

## Layout

```
nix/
  flake.nix         flake inputs, one home-manager config per machine (mkHome)
  home.nix          home-manager entrypoint, imports everything below
  nixpkgs.nix       allowed unfree/insecure packages, VS Code marketplace overlay
  home/
    options.nix     dotfiles.dir option (defaults to ~/workspace/kocal/dotfiles)
    nix.nix         enables flakes in ~/.config/nix/nix.conf
    homebrew.nix    Homebrew taps, brews and casks (CLI tools, GUI apps, fonts, Claude Code)
    git.nix         programs.git: SSH signing via 1Password's op-ssh-sign
    zsh.nix         zsh + Starship, aliases, shell functions
    neovim.nix      programs.neovim: plugins, treesitter, vimrc
    node.nix        fnm (Node version manager), boulot only
    vite-plus.nix   sources Vite+ env from .zshrc (Node and package managers on perso)
    php.nix         PHP 8.2-8.5 (+ 8.1 on perso) + composer + symfony-cli
    docker.nix      ~/.docker/config.json symlinked out-of-store to nix/home/docker/
    claude.nix      ~/.claude/* symlinked out-of-store to nix/home/claude/
    ghostty.nix     Ghostty config (app itself is a Homebrew cask)
```

### Packages

CLI tools are Homebrew formulae, listed in `brews` in `nix/home/homebrew.nix`. `home/zsh.nix` puts Homebrew on PATH ahead of the macOS tools it replaces (`jq`, `make`, `curl`) but behind the Nix profiles, and loads Homebrew's zsh completions.

VS Code is a cask too: `home/vscode.nix` sets `programs.vscode.package = null`, so home-manager only manages its settings and extensions.

GUI apps, the JetBrains Mono Nerd Font and Claude Code are Homebrew casks, listed in `nix/home/homebrew.nix`. App casks install into `/Applications` and update in place, unlike read-only Nix store copies. Claude Code uses `claude-code@latest`, which gets new releases sooner than the plain `claude-code` cask. Current casks include Ghostty, 1Password, OrbStack, JetBrains Toolbox, Firefox, Rectangle Pro, UTM, VS Code, VLC, and others; Brave, mGBA, Ankama, YACReader, Notion, Transmission, Ultimaker Cura and Tailscale are personal-only.

Each switch generates a Brewfile and runs `brew bundle --no-upgrade`, which installs missing formulae and casks but never upgrades or uninstalls anything. The module writes every fully qualified entry (`tap/name`, i.e. from a third-party tap) with `trusted: true` in the Brewfile, so `brew bundle` trusts it itself. If Homebrew isn't installed in `/opt/homebrew`, the step is skipped with a warning.

### Per-machine packages (perso / boulot)

`flake.nix` builds one config per machine through a `mkHome` helper, each passing a `profile` (`perso` or `boulot`). Almost everything is shared; the profile only adds personal extras, via `lib.optionals (profile == "perso")`:

- **perso only**: the yt-dlp and upsun-cli brews (with the upsun tap), and the Brave, mGBA, Ankama, YACReader, Notion, Transmission, Ultimaker Cura and Tailscale casks (`home/homebrew.nix`), JDK 21 and 25 (`openjdk@*` brews, wired up in `home/java.nix`), and PHP 8.1 with its EOL `permittedInsecurePackages` entry (`home/php.nix`). Perso also gets Node from Vite+ (`home/vite-plus.nix`) instead of fnm.
- **shared** (both machines): everything else, VLC included.

The work machine (`boulot`) gets the shared base and none of those extras. To scope a package to one machine, wrap it in `lib.optionals (profile == "perso") [ ... ]` in the relevant file.

### Home-manager modules

- **git** (`home/git.nix`): commits and tags signed via 1Password's `op-ssh-sign`. Machine-local overrides (different email, signing key, etc.) go in `~/.gitconfig.local`, included but not managed by Nix.
- **zsh** (`home/zsh.nix`): native completion, autosuggestions, syntax highlighting, Starship prompt. Aliases and shell functions are in `nix/home/zsh/functions.zsh`. Sources `~/.zshenv.local` (from the generated `.zshenv`, before `.zshrc`) and `~/.zshrc.local` if they exist. `~/.zshenv` loads Nix itself (`nix-daemon.sh`), because macOS updates overwrite `/etc/zshrc` and drop the Nix installer's hook. `drs` is a shell function that runs `home-manager switch` for the profile baked in at build time, so the same command works on every machine. Two siblings extend that: `dro` ("rebuild outdated") previews what a flake update would change without applying it, and `dru` ("rebuild update") updates the lock and rebuilds in one step.
- **neovim** (`home/neovim.nix`): `programs.neovim` replaces Vim, with `vi`, `vim`, and `vimdiff` pointing to it; same plugins as before via Nix, plus nvim-treesitter with its grammars declared in Nix (no `:TSInstall`), highlighting on for every filetype with a grammar; config still comes from `nix/home/vim/vimrc.vim`.
- **node** (`home/node.nix`): fnm as the version manager, boulot only. Nix installs fnm itself; you still need to run `fnm install --lts` (or a specific version) after first setup.
- **vite-plus** (`home/vite-plus.nix`): perso only. Sources `~/.config/vite-plus/env` from `.zshrc`, so `vp` and its node/npm/pnpm/yarn shims are on PATH. The shims pick the Node version from `.nvmrc`, `.node-version`, `engines.node` or `devEngines.runtime`, and download a missing version on first use. Vite+ itself is installed outside Nix (see Post-install).
- **php** (`home/php.nix`): PHP 8.2-8.5 (plus 8.1 on the personal machine only), each with opcache, xdebug, apcu, blackfire probe, xsl, redis, amqp, and imagick. Default unversioned `php` is 8.4. Versioned binaries (`php8.2` ... `php8.5`, and `php8.1` on perso) are on PATH so the Symfony CLI picks the right one via `.php-version`. PHP 8.1 comes from the `phps` input (EOL, dropped from nixpkgs) and is installed on perso only.
- **claude** (`home/claude.nix`): `~/.claude/settings.json`, `~/.claude/CLAUDE.md`, `~/.claude/agents/`, `~/.claude/skills/`, and `~/.claude/agent-memory/` are all out-of-store symlinks pointing back into `nix/home/claude/`. Runtime writes by Claude land in the repo, not a read-only store path.
- **docker** (`home/docker.nix`): `~/.docker/config.json` symlinked out-of-store to `nix/home/docker/config.json`, so `docker login` / `docker context use` writes land in the repo instead of failing against a read-only store path. Sets `credsStore = osxkeychain` (the helper OrbStack ships); this replaced a stray global `ecr-login` default that broke every Docker Hub pull once the Brew-installed helper disappeared in the Nix migration.
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

**Node**: on perso, install [Vite+](https://viteplus.dev), which provides Node, npm, pnpm and yarn:

```shell
curl -fsSL https://vite.plus | bash
```

On boulot, install at least one version via fnm:

```shell
fnm install --lts
```

**gh**: GitHub's stacked-PR extension isn't in the Nix config; install it by hand through `gh`. nixpkgs ships gh-stack 0.0.4, older than the current release, so installing and upgrading through `gh` is what keeps it current. Docs: https://docs.github.com/en/pull-requests/get-started/stacked-prs-quickstart

```shell
gh extension install github/gh-stack
gh extension upgrade --all      # later, to pick up new releases
```

gh-stack spots a branch that isn't on the remote yet by matching git's English "couldn't find remote ref", which the `LC_ALL=fr_FR.UTF-8` set in `home/zsh.nix` defeats, so `gh stack push` and `gh stack rebase` fail on any unpushed branch. The `gh` wrapper in `home/zsh/functions.zsh` forces `LC_ALL=C` for the `stack` subcommand only; drop it once upstream stops reading localized git output.

## Maintenance

### Update

Dependencies are pinned in `nix/flake.lock`. Updating bumps a flake input and rebuilds; there is no per-package pin, so a package's version follows whatever input it comes from. Nix still installs PHP (with composer, symfony-cli and Blackfire) and the tools home-manager configures (git, neovim, zsh, starship), from the `nixpkgs` or `phps` inputs. PHP stays on Nix on purpose: on Homebrew it would need three taps plus activation scripts for the Blackfire probe and php.ini.

`dro` previews what an update would do before you commit to it: it updates the lock, builds the would-be home-manager generation without activating it, then diffs it against the current one and prints each package's `current -> next` version, covering the whole closure (libraries included), not just what the modules declare. It needs no `sudo`, and the lock is restored to its original state afterward, so nothing is left changed.

```shell
dro
# preview version changes, applies nothing
```

`dru` skips the preview and updates in one step:

```shell
dru
# equivalent to:
nix flake update --flake "$PWD/nix"
drs
brew upgrade
```

Both use the profile baked in at build time, so they work unchanged on either machine.

Update a single input:

```shell
nix flake update nixpkgs --flake "$PWD/nix"   # bumps everything from nixpkgs: php, git, neovim, ...
# other inputs: home-manager, phps, nix-vscode-extensions
drs
```

Claude Code comes from the `claude-code@latest` cask, so `brew upgrade claude-code@latest` updates it alone.

Homebrew casks are managed by Homebrew, not the lock file. `dru` ends with `brew upgrade`, which skips casks marked `auto_updates` (Firefox, OrbStack, Rectangle Pro, JetBrains Toolbox) because they update themselves. `home/homebrew.nix` re-enables their updaters.

Roll back a bad update:

```shell
home-manager switch --rollback
```

### Garbage collection

Every `drs` creates a new home-manager generation; old generations stay on disk as GC roots and pile up. Concretely, each rebuild that changes PHP leaves stale `php-with-extensions` store paths behind, so the Symfony CLI's local PHP-discovery patch lists the same PHP version several times over.

Free the store by deleting old generations:

```shell
nix-clean   # alias for: nix-collect-garbage -d
```

`-d` deletes ALL old generations of every profile and collects garbage; there's no rollback after that. To keep a rollback window instead, delete only generations older than a few days:

```shell
nix-collect-garbage --delete-older-than 7d
```

Unlike a rebuild, garbage collection needs no flake path: it operates on the Nix store and your profiles, not on your config. It needs no `sudo` because every generation lives in your own profiles under `~/.local/state/nix/profiles`.

### Add a package

Add a CLI tool to `brews` or a GUI app to `casks` in `nix/home/homebrew.nix`, then rebuild. If it comes from a third-party tap, add the tap to `taps` and write the entry with its full `tap/name`, which marks it trusted automatically. To install it on one machine only, wrap it in `lib.optionals (profile == "perso") [ ... ]` (see the perso-only lists in `home/homebrew.nix`, `home/java.nix`, and `home/php.nix`).
