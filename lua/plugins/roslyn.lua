-- roslyn.nvim — C# LSP. The Roslyn server (the one behind VS Code's C# Dev Kit)
-- replaces the discontinued OmniSharp; every audako repo is C#, so this is the
-- first real LSP in this config.
--
-- No `cmd` override: with no mason install the plugin falls back to
-- `Microsoft.CodeAnalysis.LanguageServer --stdio`, which is exactly the binary
-- name nixpkgs' `roslyn-ls` puts on PATH (flake.nix). Keep it that way —
-- installing it via mason or `dotnet tool install -g` would put a second,
-- unversioned copy ahead of the nix one.
--
-- Server-side settings go through `vim.lsp.config('roslyn', ...)` (nvim 0.12
-- interface), NOT through `opts` — `opts` is only the plugin's own behaviour
-- (target/solution picking, filewatching).
--
-- Keymaps are not here: they are server-agnostic and live in config/lsp.lua,
-- bound on LspAttach. Note K is *not* hover in this config — the layout took it
-- for prev-match, so hover is `gh`.
return {
  {
    'seblyng/roslyn.nvim',
    ft = { 'cs', 'razor' },
    init = function()
      -- roslyn.nvim enables the server while its plugin file is sourced, before
      -- lazy.nvim runs config; register our settings first.
      vim.lsp.config('roslyn', {
        settings = {
          -- Open files only. `fullSolution` is the tempting setting — errors in
          -- files you haven't opened — but on a solution the size of Inframan it
          -- pins a core for minutes after every attach. Raise it per-repo if a
          -- refactor needs solution-wide errors.
          ['csharp|background_analysis'] = {
            dotnet_analyzer_diagnostics_scope = 'openFiles',
            dotnet_compiler_diagnostics_scope = 'openFiles',
          },
          ['csharp|completion'] = {
            -- Complete types that are not imported yet and add the using.
            dotnet_show_completion_items_from_unimported_namespaces = true,
          },
          ['csharp|symbol_search'] = {
            dotnet_search_reference_assemblies = true,
          },
          -- The server only sends inlay hints if asked here; whether they are
          -- *displayed* is the per-buffer <leader>li toggle (config/lsp.lua),
          -- which starts off. Parameter names and inferred `var` types are the
          -- two that earn their line-shift in C#.
          ['csharp|inlay_hints'] = {
            csharp_enable_inlay_hints_for_implicit_variable_types = true,
            csharp_enable_inlay_hints_for_lambda_parameter_types = true,
            dotnet_enable_inlay_hints_for_parameters = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
          },
        },
      })
    end,
  },
}
