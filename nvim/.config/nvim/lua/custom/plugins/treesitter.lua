return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    config = function()
      -- [[ Configure Treesitter ]]
      -- The new 'main' branch removes 'ensure_installed', 'highlight', and 'indent' options.
      -- We manually install parsers and enable features via native APIs.

      -- 1. Automated Parser Installation (The "Shim")
      -- This ensures your preferred languages are always ready across devices.
      local wanted_parsers = {
        'bash',
        'c',
        'css',
        'csv',
        'diff',
        'dockerfile',
        'gitignore',
        'html',
        'ini',
        'json',
        'kdl',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'nu',
        'python',
        'query',
        'ruby',
        'rust',
        'sql',
        'ssh_config',
        'tmux',
        'toml',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
        'yaml',
      }

      local ts = require 'nvim-treesitter'
      local missing = {}

      for _, lang in ipairs(wanted_parsers) do
        -- Check for parser file (so/dylib/dll) in runtime path
        local has_parser = vim.api.nvim_get_runtime_file('parser/' .. lang .. '.*', false)[1]
        if not has_parser then
          table.insert(missing, lang)
        end
      end

      if #missing > 0 then
        -- Schedule installation to avoid blocking startup
        vim.schedule(function()
          ts.install(missing)
        end)
      end

      -- 2. Enable Features (Highlighting & Indentation)
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('nvim-treesitter-enable', { clear = true }),
        callback = function(args)
          -- Enable Highlighting (Native Neovim API)
          local ok, _ = pcall(vim.treesitter.start, args.buf)

          -- Enable Indentation (New Plugin API)
          -- Only set if highlighting was successfully started
          if ok then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
}
