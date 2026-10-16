{ lib, profile, ... }:
let
  isPerso = profile == "perso";
in {
  # Vite+ (https://viteplus.dev), installed with `curl -fsSL https://vite.plus | bash`.
  # Its env file registers completions via `compdef`, so it belongs in .zshrc
  # after compinit, not in .zshenv.
  programs.zsh.initContent = lib.mkIf isPerso (lib.mkOrder 1010 ''
    [ -f "$HOME/.config/vite-plus/env" ] && . "$HOME/.config/vite-plus/env"
  '');
}
