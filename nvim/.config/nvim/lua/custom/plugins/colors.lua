return {
  'brenoprata10/nvim-highlight-colors',
  config = function()
    require('nvim-highlight-colors').setup {
      ---Render style
      ---@usage 'background'|'foreground'|'virtual'
      render = 'virtual',
      ---Set virtual symbol (only if render is set to 'virtual')
      virtual_symbol = '󰝤',
      ---Enable tailwind colors
      enable_tailwind = true,
    }
  end,
}
