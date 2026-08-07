{ pkgs, ... }: {
  # VS Code itself stays in environment.systemPackages (so it lands in
  # /Applications/Nix Apps). Here home-manager owns only settings + extensions:
  #   - package = null       -> don't install a second copy under ~/Applications.
  #   - mutableExtensionsDir  -> ~/.vscode/extensions becomes a read-only symlink,
  #     fully declarative (add/remove extensions by editing this file, not the UI).
  #   - enable*UpdateCheck    -> writes update.mode=none & extensions.autoCheckUpdates=false,
  #     because the Squirrel/extension updaters can't write into the Nix bundle.
  programs.vscode = {
    enable = true;
    package = null;
    mutableExtensionsDir = false;

    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;

      extensions = with pkgs.vscode-marketplace; [
        # Current set
        l13rary.l13-diff
        ms-azuretools.vscode-containers
        jnoortheen.nix-ide
        bmewburn.vscode-intelephense-client
        waderyan.gitblame
        mblode.twig-language-2
        ms-vscode-remote.remote-ssh
        matthewpi.caddyfile-support

        # Vue + JS/TS
        vue.volar

        # Symfony/PHP dev extras
        editorconfig.editorconfig
        redhat.vscode-yaml
        neilbrayfield.php-docblocker
      ];
    };
  };
}
