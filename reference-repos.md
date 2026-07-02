# Reference repositories

Local read-only clones under `.references/` (gitignored), kept as reference for our
own nix-darwin / home-manager setup. Each was studied for how it configures git, vim,
and zsh via Nix.

| Name | Remote | Local path |
|------|--------|-----------|
| neolectron-nixfiles | https://github.com/neolectron/nixfiles | `.references/neolectron-nixfiles` |
| Vincent-HD-nixfiles | https://github.com/Vincent-HD/.nixfiles | `.references/Vincent-HD-nixfiles` |
| Christopher2K-NixConfig | https://github.com/Christopher2K/NixConfig | `.references/Christopher2K-NixConfig` |
| astahmer-nixfiles | https://github.com/astahmer/nixfiles | `.references/astahmer-nixfiles` |

## Why kept

Bootstrap our git/vim/zsh home-manager config from proven setups. All four use
flake-parts + import-tree with one module per program.

## How each configures git / vim / zsh

- **neolectron** — git: inline `programs.git.settings`, no aliases, no includes. vim: **nixvim** (full neovim in Nix). zsh: native HM (`autosuggestion` + `syntaxHighlighting`, no oh-my-zsh) + **starship**.
- **Vincent-HD** — git: inline `programs.git.settings` + aliases, VS Code as diff/merge tool, unconditional include hack for `[color]` subsections. vim: package only. zsh: `programs.zsh` module is orphaned; live shell kept user-managed + starship.
- **Christopher2K** — git: inline `settings` + **conditional include** (`gitdir:**/cookunity/**`) for work identity. vim: `programs.neovim` + Lua config as **out-of-store symlink** to `assets/nvim` (native `vim.pack`). zsh: `oh-my-zsh.enable` (bare, hand-rolled git aliases) + **starship**.
- **astahmer** — git: inline `settings` + aliases + inline `ignores`, **delta** as pager. vim: package only (`EDITOR=nvim`). zsh: native HM, XDG `dotDir`, thin `~/.z*` stubs, **starship** + **mcfly** + direnv.

Common denominators: git fully inline via `programs.git.settings`; starship prompt;
per-program module split; `lib.mkIf pkgs.stdenv.hostPlatform.isDarwin` for OS forks.
