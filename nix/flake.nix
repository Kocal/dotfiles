{
  description = "macOS dotfiles (home-manager)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Full VS Code Marketplace + Open VSX as Nix packages (nixpkgs only ships a
    # small curated subset). Provides the `vscode-marketplace` overlay.
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";

    # EOL PHP versions (8.1, 8.0, ...) not in nixpkgs anymore.
    phps.url = "github:fossar/nix-phps";
    phps.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, home-manager, ... }:
  let
    # One home-manager config per machine. `profile` (perso|boulot) is threaded
    # to every module so packages can diverge per machine.
    mkHome = { username, profile }: home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      extraSpecialArgs = { inherit inputs profile; };
      modules = [
        ./home.nix
        {
          home.username = username;
          home.homeDirectory = "/Users/${username}";
        }
      ];
    };
  in
  {
    # $ home-manager switch --flake .#perso
    # $ home-manager switch --flake .#boulot
    homeConfigurations.perso = mkHome { username = "kocal"; profile = "perso"; };
    homeConfigurations.boulot = mkHome { username = "kocal"; profile = "boulot"; };
  };
}
