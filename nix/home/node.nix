{ pkgs, lib, ... }: {
  # Node version manager (nix-native replacement for nvm). Reads .nvmrc /
  # .node-version and switches automatically when entering a directory.
  # Install a version once with e.g. `fnm install --lts` or `fnm install 22`.
  home.packages = [ pkgs.fnm ];

  programs.zsh.initContent = lib.mkOrder 1000 ''
    eval "$(fnm env --use-on-cd --shell zsh)"
  '';
}
