{ pkgs, ... }:
let
  # 1Password's SSH signing helper lives at a different path per OS
  # (was dotfiles/git/.gitconfig.{Darwin,Linux}).
  onePasswordSshSign =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
    else "/opt/1Password/op-ssh-sign";
in
{
  programs.git = {
    enable = true;

    # Global gitignore (was ~/.gitignore_global).
    ignores = [
      ".idea/"
      "*.iml"
      ".vscode/"
      ".DS_Store"
      "webpack-encore/.npmrc"
      "symfony-webpack-encore-*.tgz"
      "**/.claude/settings.local.json"
    ];

    # Machine-local / secret overrides, created with `touch ~/.gitconfig.local`.
    includes = [
      { path = "~/.gitconfig.local"; }
    ];

    settings = {
      user = {
        name = "Hugo Alliaume";
        email = "hugo@alliau.me";
        signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEp3XcbIyvTVZM+MOdpue98PTKaNPBtIo0puTFBk4Nvh";
      };

      core = {
        editor = "code --wait";
        autocrlf = "input";
        ignorecase = false;
      };

      init.defaultBranch = "main";
      color.ui = "auto";

      # SSH commit/tag signing, backed by 1Password's op-ssh-sign.
      gpg.format = "ssh";
      gpg.ssh.program = onePasswordSshSign;
      commit = { gpgsign = true; verbose = true; };
      tag = { gpgsign = true; forceSignAnnotated = true; };

      branch.sort = "-committerdate";
      fetch = { prune = true; pruneTags = true; all = true; };
      pull.rebase = true;
      push = { autoSetupRemote = true; default = "current"; followTags = false; };

      merge = { summary = true; conflictstyle = "zdiff3"; stat = true; };
      rebase = { updateRefs = true; autoSquash = true; autoStash = true; };
      rerere = { enabled = true; autoupdate = true; };

      diff = { tool = "default-difftool"; algorithm = "histogram"; colorMoved = "default"; };
      difftool."default-difftool".cmd = "code --wait --diff $LOCAL $REMOTE";

      gh.remote = "upstream";
      help.autocorrect = "prompt";
    };
  };
}
