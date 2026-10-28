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
  ]
  # perso-only packages
  ++ lib.optionals isPerso [
    pkgs.yt-dlp
  ]
  # boulot-only packages
  ++ lib.optionals isBoulot [
    pkgs.k9s # Kubernetes TUI
    pkgs.awscli2
  ];
}
