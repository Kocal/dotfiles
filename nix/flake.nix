{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # EOL PHP versions (8.1, 8.0, ...) not in nixpkgs anymore.
    phps.url = "github:fossar/nix-phps";
    phps.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    # Third-party tap for Vorssaint (not in core homebrew-cask).
    homebrew-vorssaint = {
      url = "github:vorssaint/homebrew-tap";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, phps, nix-homebrew, homebrew-core, homebrew-cask, homebrew-vorssaint }:
  let
    configuration = { config, pkgs, lib, profile, ... }:
    let
      isPerso = profile == "perso";
    in {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [
          pkgs.gnumake
          pkgs.bat
          pkgs.gh
          pkgs.rtk
          pkgs.orbstack
          pkgs.claude-code

          # CLI tools
          pkgs.ffmpeg
          pkgs.imagemagick # `magick`/`convert`/`identify`/`mogrify` CLI
          pkgs.jq
          pkgs.yq-go # mikefarah yq (`yq` command), not the python yq
          pkgs.curl
          pkgs.tree
          pkgs.uv
          pkgs.yt-dlp
          pkgs.htop
          pkgs.btop
          pkgs.fd
          pkgs.ripgrep
          pkgs.glab
          pkgs.wget
          pkgs.mkcert
          pkgs.zizmor

          # GUI apps available on nix-darwin. nix-darwin copies these into
          # /Applications/Nix Apps as real bundles, so Spotlight/Launchpad see them.
          pkgs.firefox-bin
          pkgs.jetbrains-toolbox
          pkgs.rectangle-pro
          pkgs.vscode
        ]
        # perso-only GUI apps
        ++ lib.optionals isPerso [
          pkgs.brave
        ];

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      # Allow specific unfree packages only (blackfire probe + agent match by name).
      nixpkgs.config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "vim-solarized8"
          "orbstack"
          "claude-code"
          "jetbrains-toolbox"
          "rectangle-pro"
          "vscode"
        ]
        || lib.hasInfix "blackfire" (lib.getName pkg)
        || lib.hasInfix "firefox" (lib.getName pkg);

      # PHP 8.1 is EOL; fossar/nix-phps marks it insecure. Permit it for local dev.
      # If the switch errors, copy the exact "php-8.1.xx" name from the message here.
      # PHP 8.1 is EOL and only installed on the perso profile, so scope its
      # insecure permit there too.
      nixpkgs.config.permittedInsecurePackages = lib.optionals isPerso [
        "php-8.1.33"
      ];

      # Needed so home-manager can resolve the user's home directory.
      users.users.kocal = {
        name = "kocal";
        home = "/Users/kocal";
      };

      # User running darwin-rebuild; required by the homebrew module.
      system.primaryUser = "kocal";

      # GUI apps not available/working on nix-darwin -> Homebrew casks.
      homebrew = {
        enable = true;
        onActivation.cleanup = "none"; # don't remove undeclared brew packages
        casks = [
          "1password" # strict location/signing, unreliable from a nix copy
          "cloudflare-warp" # needs the signed system network extension
          "ghostty" # nixpkgs ghostty is broken on darwin
          "imageoptim" # not in nixpkgs
          "affinity" # not in nixpkgs (proprietary Serif)
          "ankama" # nixpkgs ankama-launcher is linux-only
          "inkscape" # nixpkgs build broken on darwin (appstream/libadwaita)
          "pinta" # nixpkgs build broken on darwin (appstream/libadwaita)
          "yacreader" # nixpkgs build pulls linux-only pipewire on darwin
          "vorssaint/tap/vorssaint" # third-party vendor tap, not in core homebrew-cask
          "google-chrome" # nixpkgs google-chrome is linux-only
          "notion" # nixpkgs notion-app not available on darwin
          "transmission" # native macOS GUI app not built by nixpkgs on darwin
          "ultimaker-cura" # nixpkgs cura is linux-only
          "vlc" # nixpkgs vlc is unreliable on darwin
        ]
        # perso-only casks
        ++ lib.optionals isPerso [
          "mgba-app" # nixpkgs mgba is linux-only
        ];
      };
    };

    # One darwinSystem per machine. `profile` (perso|boulot) is threaded to the
    # system module and to home-manager so packages can diverge per machine. The
    # config name equals the machine hostname so `drs` resolves it at runtime.
    mkDarwin = { hostname, profile }: nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs profile; };
      modules = [
        configuration
        # Keep the system hostname in sync with the config name.
        {
          networking.hostName = hostname;
          networking.localHostName = hostname;
          networking.computerName = hostname;
        }
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-backup";
          home-manager.extraSpecialArgs = { inherit inputs profile; };
          home-manager.users.kocal = import ./home.nix;
        }
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
            user = "kocal";

             # Optional: Declarative tap management
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
              "vorssaint/homebrew-tap" = homebrew-vorssaint;
            };

            # Optional: Enable fully-declarative tap management
            #
            # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
            mutableTaps = false;

            # Optional: Declarative Homebrew tap trust entries.
            #
            # Note: The trust entries are _not_ removed if you remove them from those lists!
            # Use the `brew untrust` command to remove a trust entry.
            trust = {
              formulae = [ ];
              casks = [ ];
              commands = [ ];
              taps = [ ];
            };
          };
        }
        # Optional: Align homebrew taps config with nix-homebrew
        ({config, ...}: {
          homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
        })
      ];
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#MacBook-Pro-de-Hugo   (perso)
    # $ darwin-rebuild build --flake .#MacBook-Pro-de-Hugo-2 (boulot)
    darwinConfigurations."MacBook-Pro-de-Hugo"   = mkDarwin { hostname = "MacBook-Pro-de-Hugo";   profile = "perso"; };
    darwinConfigurations."MacBook-Pro-de-Hugo-2" = mkDarwin { hostname = "MacBook-Pro-de-Hugo-2"; profile = "boulot"; };
  };
}
