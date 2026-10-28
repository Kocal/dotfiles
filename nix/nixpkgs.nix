{ inputs, lib, profile, ... }:
let
  isPerso = profile == "perso";
in
{
  # Exposes pkgs.vscode-marketplace.<publisher>.<name> (see home/vscode.nix).
  nixpkgs.overlays = [
    inputs.nix-vscode-extensions.overlays.default
    (final: prev: {
      jetbrains-toolbox = prev.jetbrains-toolbox.overrideAttrs (old: rec {
        version = "3.9.0.88839";
        # nixpkgs' download-cdn URL 404s; download.jetbrains.com redirects to a signed one.
        src = final.fetchurl {
          url = "https://download.jetbrains.com/toolbox/jetbrains-toolbox-${version}-arm64.dmg";
          hash = "sha256-rxouFL5G4bvKDjEKhlApsGlNRMBiEFubhH1VfzqmZ2A=";
        };
      });
    })
  ];

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
    || lib.hasInfix "firefox" (lib.getName pkg)
    # VS Code Marketplace extensions (e.g. Microsoft Remote-SSH) ship as unfree.
    || lib.hasInfix "vscode-extension" (lib.getName pkg);

  # PHP 8.1 is EOL; fossar/nix-phps marks it insecure. Permit it for local dev.
  # If the switch errors, copy the exact "php-8.1.xx" name from the message here.
  # PHP 8.1 is EOL and only installed on the perso profile, so scope its
  # insecure permit there too.
  nixpkgs.config.permittedInsecurePackages = lib.optionals isPerso [
    "php-8.1.33"
  ];
}
