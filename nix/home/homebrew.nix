{ lib, pkgs, profile, ... }:
let
  isPerso = profile == "perso";
  isBoulot = profile == "boulot";

  taps = [
    "vorssaint/tap"
  ]
  ++ lib.optionals isPerso [
    "upsun/tap"
  ];

  brews = [
    "bat"
    "btop"
    "curl" # keg-only: not linked into /opt/homebrew/bin, home/zsh.nix adds it to PATH
    "fd"
    "ffmpeg"
    "gh"
    "glab"
    "htop"
    "imagemagick" # `magick`/`convert`/`identify`/`mogrify` CLI
    "jq"
    "make" # installs `gmake`, home/zsh.nix puts its `make` gnubin on PATH
    "mkcert"
    "ripgrep"
    "rtk"
    "tree"
    "uv"
    "wget"
    "yq" # mikefarah yq (`yq` command), not the python yq
    "zizmor"
  ]
  # perso-only brews
  ++ lib.optionals isPerso [
    "upsun/tap/upsun-cli"
    "yt-dlp"
  ]
  # boulot-only brews
  ++ lib.optionals isBoulot [
    "awscli"
    "k9s" # Kubernetes TUI
  ];

  # GUI apps (and Claude Code) -> Homebrew casks.
  casks = [
    "1password" # strict location/signing, unreliable from a nix copy
    "1password-cli" # `op`
    "claude" # desktop app, not in nixpkgs
    "cloudflare-warp" # needs the signed system network extension
    "ghostty" # nixpkgs ghostty is broken on darwin
    "handy" # not in nixpkgs
    "imageoptim" # not in nixpkgs
    "monitorcontrol" # not in nixpkgs (macOS-only app)
    "affinity" # not in nixpkgs (proprietary Serif)
    "inkscape" # nixpkgs build broken on darwin (appstream/libadwaita)
    "pinta" # nixpkgs build broken on darwin (appstream/libadwaita)
    "vorssaint/tap/vorssaint" # third-party vendor tap, not in core homebrew-cask
    "google-chrome" # nixpkgs google-chrome is linux-only
    "vlc" # nixpkgs vlc is unreliable on darwin
    "android-platform-tools" # `adb`/`fastboot`
    "claude-code@latest" # `claude`; the plain `claude-code` cask lags behind
    "firefox"
    "font-jetbrains-mono-nerd-font"
    "jetbrains-toolbox"
    "orbstack"
    "rectangle-pro"
    "utm"
    "visual-studio-code" # settings and extensions stay in home/vscode.nix
  ]
  # perso-only casks
  ++ lib.optionals isPerso [
    "mgba-app" # nixpkgs mgba is linux-only
    "ankama" # nixpkgs ankama-launcher is linux-only
    "yacreader" # nixpkgs build pulls linux-only pipewire on darwin
    "notion" # nixpkgs notion-app not available on darwin
    "transmission" # native macOS GUI app not built by nixpkgs on darwin
    "ultimaker-cura" # nixpkgs cura is linux-only
    "tailscale-app" # needs the signed system network extension
    "brave-browser"
  ];

  # Homebrew refuses to load third-party tap formulae/casks (the "tap/name"
  # ones) until trusted.
  entry = kind: name:
    ''${kind} "${name}"'' + lib.optionalString (lib.hasInfix "/" name) ", trusted: true";

  brewfile = pkgs.writeText "Brewfile" (lib.concatLines (
    map (tap: ''tap "${tap}"'') taps
    ++ map (entry "brew") brews
    ++ map (entry "cask") casks
  ));
in
{
  # Install-only: --no-upgrade leaves installed versions alone, and casks
  # removed from the list are not uninstalled.
  home.activation.homebrewBundle = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    brew=/opt/homebrew/bin/brew
    if [ -x "$brew" ]; then
      run env HOMEBREW_NO_AUTO_UPDATE=1 "$brew" bundle --file=${brewfile} --no-upgrade
    else
      warnEcho "Homebrew is not installed in /opt/homebrew, skipping the casks."
    fi
  '';
}
