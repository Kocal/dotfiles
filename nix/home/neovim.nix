{ pkgs, ... }: {
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withRuby = false;
    withPython3 = false;

    # Plugins previously managed by vim-plug, now handled by Nix.
    plugins = with pkgs.vimPlugins; [
      vim-sensible
      vim-obsession
      vim-airline
      vim-solarized8
      (nvim-treesitter.withPlugins (p: with p; [
        bash
        css
        diff
        dockerfile
        git_config
        git_rebase
        gitcommit
        gitignore
        html
        ini
        javascript
        json
        lua
        make
        markdown
        markdown_inline
        nix
        php
        phpdoc
        regex
        rst
        scss
        sql
        toml
        tsx
        twig
        typescript
        vim
        vimdoc
        xml
        yaml
      ]))
    ];

    # Reuse the shared vimrc kept alongside this module.
    # Named *.vim so editors (PhpStorm, etc.) apply VimScript syntax highlighting.
    extraConfig = builtins.readFile ./vim/vimrc.vim;

    # nvim-treesitter (main branch) leaves highlighting to Neovim; pcall skips filetypes without a parser.
    initLua = ''
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args) pcall(vim.treesitter.start, args.buf) end,
      })
    '';
  };
}
