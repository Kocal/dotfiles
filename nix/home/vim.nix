{ pkgs, ... }: {
  programs.vim = {
    enable = true;

    # Plugins previously managed by vim-plug, now handled by Nix.
    plugins = with pkgs.vimPlugins; [
      vim-sensible
      vim-obsession
      vim-airline
      vim-solarized8
    ];

    # Reuse the shared vimrc kept alongside this module.
    # Named *.vim so editors (PhpStorm, etc.) apply VimScript syntax highlighting.
    extraConfig = builtins.readFile ./vim/vimrc.vim;
  };
}
