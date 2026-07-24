{ ... }: {
  imports = [
    ./home/options.nix
    ./home/git.nix
    ./home/vim.nix
    ./home/zsh.nix
    ./home/node.nix
    ./home/go.nix
    ./home/java.nix
    ./home/php.nix
    ./home/ghostty.nix
    ./home/vscode.nix
    ./home/docker.nix
    ./home/claude.nix
  ];

  # Match with system.stateVersion / your nixpkgs release.
  home.stateVersion = "24.11";
}
