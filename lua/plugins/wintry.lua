-- wintry — the colorscheme.
return {
  {
    'JacobDeuchert/wintry-theme',
    lazy = false,
    priority = 1000, -- load before everything else so no other scheme flashes
    config = function()
      vim.cmd.colorscheme('wintry')
    end,
  },
}
