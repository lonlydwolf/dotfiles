return {
  { -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    main = 'ibl',
    opts = {
      indent = {
        char = '│', -- A simple thin line
      },
      scope = {
        enabled = false, -- No more distracting scope highlights
      },
    },
  },
}
