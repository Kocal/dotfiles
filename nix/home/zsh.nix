{ config, pkgs, lib, ... }:
let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      save = 10000;
      share = true;
      ignoreDups = true;
      extended = true;
    };

    shellAliases = {
      # listing (oh-my-zsh style)
      l = "ls -lah";

      # Symfony / project shortcuts
      sf = "symfony";
      sfc = "symfony console";
      sfcp = "symfony composer";
      sfp = "symfony php";
      ux = "cd ~/workspace/symfony/ux";
      uxc = "cd ~/workspace/symfony/ux.symfony.com";
      ux-link = "~/workspace/symfony/ux/link .";
      encore = "cd ~/workspace/symfony/webpack-encore";

      # git shortcuts (oh-my-zsh git plugin style)
      g = "git";
      ga = "git add";
      gaa = "git add --all";
      gst = "git status";
      gss = "git status -s";
      gco = "git checkout";
      gcb = "git checkout -b";
      gc = "git commit -v";
      gcmsg = "git commit -m";
      gd = "git diff";
      gdca = "git diff --cached";
      gb = "git branch";
      gp = "git push";
      gpf = "git push --force-with-lease";
      gl = "git pull";
      gf = "git fetch";
      glog = "git log --oneline --decorate --graph";
      grb = "git rebase";
      grbi = "git rebase -i";
      gsta = "git stash";
      gstp = "git stash pop";

      # nix-darwin rebuild switch (absolute path, so it works from any directory)
      drs = "sudo darwin-rebuild switch --flake ${config.dotfiles.dir}/nix";
    };

    initContent = lib.mkMerge [
      # env not covered by sessionVariables/sessionPath
      (lib.mkOrder 500 ''
        export TIMEFMT=$'%J\n%U user\n%S system\n%P cpu\n%*E total'
      '')

      # shell helpers + functions (real .zsh file, no Nix escaping needed)
      (lib.mkOrder 550 (builtins.readFile ./zsh/functions.zsh))

      # oh-my-zsh-like line editing, without a plugin manager.
      (lib.mkOrder 600 ''
        # Up/Down search history for entries matching what's already typed (prefix).
        autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
        zle -N up-line-or-beginning-search
        zle -N down-line-or-beginning-search
        bindkey "^[[A" up-line-or-beginning-search
        bindkey "^[OA" up-line-or-beginning-search
        bindkey "^[[B" down-line-or-beginning-search
        bindkey "^[OB" down-line-or-beginning-search

        # Completion menu: highlighted, arrow-navigable, colored like `ls`.
        zmodload zsh/complist
        eval "$(${pkgs.coreutils}/bin/dircolors -b)"
        zstyle ':completion:*' menu select
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # case-insensitive
      '')

      # Linux-only bits (dormant on darwin), from old .zsh{env,rc}.Linux
      (lib.mkOrder 1200 (lib.optionalString isLinux ''
        # All PHP versions on PATH for the Symfony CLI (last one is default `php`).
        for version in 8.1 8.2 8.3 8.4 8.5; do
          export PATH="$HOME/.local/php-$version/bin:$PATH"
          export PATH="$HOME/.local/php-$version/sbin:$PATH"
        done

        # Homebrew on Linux
        test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
        test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
      ''))

      # machine-local overrides, if present
      (lib.mkOrder 1500 ''
        [ -f ~/.zshrc.local ] && source ~/.zshrc.local
      '')
    ];
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[✗](bold red)";
      };
    };
  };

  home.sessionVariables = {
    LANG = "fr_FR.UTF-8";
    LC_ALL = "fr_FR.UTF-8";
    GH_EDITOR = "code --wait";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.composer/vendor/bin"
  ];
}
