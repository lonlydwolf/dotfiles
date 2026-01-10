return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    -- v3 defaults are excellent, but we can customize modes here
    modes = {
      preview_float = {
        mode = "diagnostics",
        preview = {
          type = "float",
          relative = "editor",
          border = "rounded",
          title = "Preview",
          title_pos = "center",
          position = { 0, -2 },
          size = { width = 0.3, height = 0.3 },
          zindex = 200,
        },
      },
    },
  },
  cmd = "Trouble",
  keys = {
    -- Diagnostics (Project)
    {
      "<leader>xx",
      "<cmd>Trouble diagnostics toggle<cr>",
      desc = "Diagnostics (Trouble)",
    },
    -- Diagnostics (Buffer)
    {
      "<leader>xX",
      "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
      desc = "Buffer Diagnostics (Trouble)",
    },
    -- Symbols (Better than lsp_document_symbols)
    {
      "<leader>cs",
      "<cmd>Trouble symbols toggle focus=false<cr>",
      desc = "Symbols (Trouble)",
    },
    -- LSP Definitions / References
    {
      "<leader>cl",
      "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
      desc = "LSP Definitions / References (Trouble)",
    },
    -- Location List replacement
    {
      "<leader>xL",
      "<cmd>Trouble loclist toggle<cr>",
      desc = "Location List (Trouble)",
    },
    -- Quickfix List replacement
    {
      "<leader>xQ",
      "<cmd>Trouble qflist toggle<cr>",
      desc = "Quickfix List (Trouble)",
    },
  },
  config = function(_, opts)
    require("trouble").setup(opts)
    -- Transparency Fix: Force Trouble to use transparent background
    local hl_groups = { "TroubleNormal", "TroubleNormalNC", "TroubleFloat" }
    for _, hl in ipairs(hl_groups) do
      vim.api.nvim_set_hl(0, hl, { bg = "none" })
    end
  end,
}
