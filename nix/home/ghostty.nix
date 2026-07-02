{ ... }: {
  programs.ghostty = {
    enable = true;
    # The app itself comes from the Homebrew cask; the nixpkgs ghostty package is
    # broken on darwin. home-manager still manages the config at ~/.config/ghostty/config.
    package = null;

    settings = {
      theme = "light:Rose Pine Dawn,dark:Rose Pine";
    };
  };
}
