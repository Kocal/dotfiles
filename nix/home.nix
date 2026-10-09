{ ... }: {
  imports = [
    ./nixpkgs.nix
    ./packages.nix
    ./home/options.nix
    ./home/nix.nix
    ./home/homebrew.nix
    ./home/git.nix
    ./home/neovim.nix
    ./home/zsh.nix
    ./home/node.nix
    ./home/go.nix
    ./home/java.nix
    ./home/php.nix
    ./home/ghostty.nix
    ./home/vscode.nix
    ./home/chrome.nix
    ./home/firefox.nix
    ./home/orbstack.nix
    ./home/rectangle-pro.nix
    ./home/docker.nix
    ./home/claude.nix
  ];

  # Spotlight ignores symlinked apps, so copy the bundles instead.
  targets.darwin.linkApps.enable = false;
  targets.darwin.copyApps.enable = true;

  programs.home-manager.enable = true;

  # Match with your nixpkgs release.
  home.stateVersion = "24.11";
}
