return {
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    lazy = false,
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      -- The 'main' branch of textobjects exposes standalone modules.
      -- We will map them manually for maximum control and stability.
      
      -- 1. Selection (Select around/inner)
      -- Handled by mini.ai in init.lua for better performance/integration
      -- local select = require('nvim-treesitter-textobjects.select')
      -- 
      -- -- Helper to create select maps
      -- local function map_select(key, capture, desc)
      --   vim.keymap.set({'o', 'x'}, key, function()
      --     select.select_textobject(capture, 'textobjects', 'v') 
      --   end, { desc = desc })
      -- end
      -- 
      -- -- Define your text objects here
      -- map_select('af', '@function.outer', 'Select outer function')
      -- map_select('if', '@function.inner', 'Select inner function')
      -- map_select('ac', '@class.outer', 'Select outer class')
      -- map_select('ic', '@class.inner', 'Select inner class')
      -- map_select('aa', '@parameter.outer', 'Select outer argument')
      -- map_select('ia', '@parameter.inner', 'Select inner argument')

      -- 2. Movement (Go to next/prev)
      local move = require('nvim-treesitter-textobjects.move')
      
      -- Helper to create move maps
      local function map_move(key, fn, capture, desc)
        vim.keymap.set({'n', 'x', 'o'}, key, function()
          fn(capture)
        end, { desc = desc })
      end

      map_move(']f', move.goto_next_start, '@function.outer', 'Next function start')
      map_move(']c', move.goto_next_start, '@class.outer', 'Next class start')
      map_move('[f', move.goto_previous_start, '@function.outer', 'Prev function start')
      map_move('[c', move.goto_previous_start, '@class.outer', 'Prev class start')
    end
  },
}
