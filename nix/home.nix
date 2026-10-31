{ ... }: {
  imports = [
    ./nixpkgs.nix
    ./home/options.nix
    ./home/nix.nix
    ./home/homebrew.nix
    ./home/git.nix
    ./home/neovim.nix
    ./home/zsh.nix
    ./home/node.nix
    ./home/vite-plus.nix
    ./home/go.nix
    ./home/java.nix
    ./home/php.nix
    ./home/ghostty.nix
    ./home/vscode.nix
    ./home/chrome.nix
    ./home/docker.nix
    ./home/agents.nix
    ./home/claude.nix
    ./home/opencode.nix
  ];

  # Spotlight ignores symlinked apps, so copy the bundles instead.
  targets.darwin.linkApps.enable = false;
  targets.darwin.copyApps.enable = true;

  programs.home-manager.enable = true;

  # Match with your nixpkgs release.
  home.stateVersion = "24.11";
}
