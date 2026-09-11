{
  description = "Jacob's Neovim configuration";

  outputs = { self }: {
    homeModules.default = { pkgs, ... }: {
      home.packages = with pkgs; [
        gcc
        git
        neovim
        ripgrep
        roslyn-ls
        svelte-language-server
        tree-sitter
        vtsls
        wl-clipboard
      ];

      home.sessionVariables.EDITOR = "nvim";

      programs.zsh.shellAliases = {
        vi = "nvim";
        vim = "nvim";
      };

      # Keep flake.nix out of ~/.config/nvim while deploying one directory link.
      xdg.configFile."nvim" = {
        source = pkgs.linkFarm "nvim-config" [
          {
            name = "init.lua";
            path = ./init.lua;
          }
          {
            name = "lazy-lock.json";
            path = ./lazy-lock.json;
          }
          {
            name = "lsp";
            path = ./lsp;
          }
          {
            name = "lua";
            path = ./lua;
          }
        ];
        force = true;
      };
    };
  };
}
