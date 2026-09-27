{
  description = "Jacob's Neovim configuration";

  outputs = { self }: {
    homeModules.default = { config, lib, pkgs, ... }:
      let
        cfg = config.nvim-config.herdr;
      in
      {
        # Off by default so machines without herdr can take the config as-is;
        # the nvim side (lua/plugins/smart-splits.lua) is inert outside a herdr pane.
        options.nvim-config.herdr = {
          enable = lib.mkEnableOption "the herdr plugin for Alt+neio nvim/pane navigation";
          package = lib.mkPackageOption pkgs "herdr" { };
        };

        config = lib.mkMerge [
          {
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
          }

          (lib.mkIf cfg.enable {
            home.packages = [
              cfg.package
              pkgs.jq # herdr/nvim-navigation detects nvim with it
            ];

            # herdr half of the Alt+neio nav (lua/plugins/smart-splits.lua). herdr
            # keeps its plugin registry in a mutable plugins.json, so deploy the
            # plugin and (re-)link it on every activation. herdr resolves the
            # symlink and records the store path, so relinking each generation
            # (rollbacks too) keeps it current; linking replaces any earlier link
            # of the same id.
            xdg.dataFile."herdr/plugins/nvim-navigation".source = ./herdr/nvim-navigation;

            home.activation.herdrNvimNavigation = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
              run ${lib.getExe cfg.package} plugin link \
                ${config.xdg.dataHome}/herdr/plugins/nvim-navigation >/dev/null \
                || warnEcho "herdr plugin link nvim-navigation failed"
            '';
          })
        ];
      };
  };
}
