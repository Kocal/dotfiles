{ pkgs, lib, profile, ... }:
let
  isPerso = profile == "perso";
  isBoulot = profile == "boulot";
in
{
  home.packages = [
    pkgs.gnumake
    pkgs.bat
    pkgs.gh
    pkgs.rtk
    pkgs.orbstack
    # nixpkgs stable pins an old claude-code; ./claude-code-manifest.json is our
    # own version lock (fetch a new one from downloads.claude.ai to bump).
    (pkgs.claude-code.override {
      manifest = lib.importJSON ./claude-code-manifest.json;
    })

    # CLI tools
    pkgs.ffmpeg
    pkgs.imagemagick # `magick`/`convert`/`identify`/`mogrify` CLI
    pkgs.jq
    pkgs.yq-go # mikefarah yq (`yq` command), not the python yq
    pkgs.curl
    pkgs.tree
    pkgs.uv
    pkgs.htop
    pkgs.btop
    pkgs.fd
    pkgs.ripgrep
    pkgs.glab
    pkgs.wget
    pkgs.mkcert
    pkgs.zizmor
    pkgs.android-tools # `adb`/`fastboot`

    # GUI apps. home-manager copies these into ~/Applications/Home Manager Apps
    # as real bundles (see home.nix), so Spotlight/Launchpad see them.
    pkgs.firefox-bin
    pkgs.jetbrains-toolbox
    pkgs.rectangle-pro
    pkgs.utm

    # Copied into ~/Library/Fonts/HomeManager.
    pkgs.nerd-fonts.jetbrains-mono
  ]
  # perso-only packages
  ++ lib.optionals isPerso [
    pkgs.brave
    pkgs.yt-dlp
  ]
  # boulot-only packages
  ++ lib.optionals isBoulot [
    pkgs.k9s # Kubernetes TUI
  ];
}
