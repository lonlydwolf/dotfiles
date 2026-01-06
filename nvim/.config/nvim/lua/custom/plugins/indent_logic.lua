return {
  {
    'indent-logic', -- Virtual name for organization
    dir = vim.fn.stdpath 'config' .. '/lua/custom/plugins', -- Virtual dir
    virtual = true,
    config = function()
      -- Create an augroup for indentation rules
      local indent_group = vim.api.nvim_create_augroup('CustomIndentRules', { clear = true })

      -- Helper to set indentation
      local function set_indent(width)
        vim.opt_local.tabstop = width
        vim.opt_local.softtabstop = width
        vim.opt_local.shiftwidth = width
        vim.opt_local.expandtab = true
      end

      -- 2-Space Languages (Prettier default, JS/TS ecosystem, Lua, Web)
      vim.api.nvim_create_autocmd('FileType', {
        group = indent_group,
        pattern = {
          'javascript',
          'javascriptreact',
          'typescript',
          'typescriptreact',
          'json',
          'html',
          'css',
          'scss',
          'lua',
          'yaml',
          'markdown',
        },
        callback = function()
          set_indent(2)
        end,
      })

      -- 4-Space Languages (Python/Black default, Rust, C-family)
      vim.api.nvim_create_autocmd('FileType', {
        group = indent_group,
        pattern = {
          'python',
          'rust',
          'c',
          'cpp',
          'java',
          'cs', -- C#
        },
        callback = function()
          set_indent(4)
        end,
      })

      -- Tab-based Languages (Go, Makefile)
      vim.api.nvim_create_autocmd('FileType', {
        group = indent_group,
        pattern = { 'go', 'make' },
        callback = function()
          vim.opt_local.tabstop = 4
          vim.opt_local.shiftwidth = 4
          vim.opt_local.expandtab = false -- Real tabs
        end,
      })
    end,
  },
}
