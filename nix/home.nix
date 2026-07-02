{ pkgs, ... }: {
  # Match with system.stateVersion / your nixpkgs release.
  home.stateVersion = "24.11";

  programs.vim = {
    enable = true;

    # Plugins previously managed by vim-plug, now handled by Nix.
    plugins = with pkgs.vimPlugins; [
      vim-sensible
      vim-obsession
      vim-airline
      vim-solarized8
    ];

    # Reuse the shared .vimrc kept at the repo root.
    extraConfig = builtins.readFile ../vim/.vimrc;
  };
}
