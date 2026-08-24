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
        ms-azuretools.vscode-docker
        jnoortheen.nix-ide
        bmewburn.vscode-intelephense-client
        waderyan.gitblame
        mblode.twig-language-2
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit # hard dependency of remote-ssh
        ms-vscode.remote-explorer
        matthewpi.caddyfile-support

        # Vue + JS/TS
        vue.volar
        bradlc.vscode-tailwindcss
        unifiedjs.vscode-mdx

        # Symfony/PHP dev extras
        symfony.language-tools
        editorconfig.editorconfig
        redhat.vscode-yaml
        neilbrayfield.php-docblocker
        devsense.composer-php-vscode

        # UX / theming / locale
        usernamehw.errorlens
        github.github-vscode-theme
        k--kato.intellij-idea-keybindings
        ms-ceintl.vscode-language-pack-fr
      ];
    };
  };
}
