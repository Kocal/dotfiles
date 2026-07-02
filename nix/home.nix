{ config, pkgs, ... }:
let
  # Live path to this repo's claude config (working tree, not the Nix store).
  claudeSrc = "${config.home.homeDirectory}/workspace/kocal/dotfiles/dotfiles/claude";
in
{
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

  # Symlink Claude config to the live repo files (out-of-store) so runtime
  # edits by Claude land back in the repo, like a manual `ln -s`.
  # A plain `home.file.<x>.source = ./file` would instead copy to a read-only
  # store path, and Claude's writes would fail and never reach the repo.
  home.file = {
    ".claude/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${claudeSrc}/settings.json";
    ".claude/statusline-command.sh".source =
      config.lib.file.mkOutOfStoreSymlink "${claudeSrc}/statusline-command.sh";
    ".claude/CLAUDE.md".source =
      config.lib.file.mkOutOfStoreSymlink "${claudeSrc}/CLAUDE.md";
  };
}
