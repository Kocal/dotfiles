{ config, pkgs, lib, ... }: {
  # Node version manager (nix-native replacement for nvm). Reads .nvmrc /
  # .node-version and switches automatically when entering a directory.
  # Install a version once with e.g. `fnm install --lts` or `fnm install 22`.
  home.packages = [ pkgs.fnm ];

  # pnpm global bin dir. `pnpm setup` can't write our read-only ~/.zshrc (managed
  # by home-manager), so declare PNPM_HOME + PATH here instead of letting pnpm
  # patch the shell. Single machine-wide location, shared across corepack-managed
  # pnpm versions.
  home.sessionVariables.PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm";
  home.sessionPath = [ "${config.home.homeDirectory}/.local/share/pnpm" ];

  programs.zsh.initContent = lib.mkOrder 1000 ''
    eval "$(fnm env --use-on-cd --shell zsh)"
  '';
}
