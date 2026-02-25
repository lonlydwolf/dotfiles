return {
  "rest-nvim/rest.nvim",
  ft = { "http", "rest" },
  opts = {
    -- Use jq for formatting JSON responses
    result = {
      formatters = {
        json = "jq",
        html = function(body)
          return vim.fn.system({"tidy", "-i", "-q", "-"}, body)
        end,
      },
    },
  },
  keys = {
    {
      "<leader>rr",
      "<cmd>Rest run<cr>",
      desc = "Run HTTP Request under cursor",
      ft = { "http", "rest" },
    },
    {
      "<leader>rl",
      "<cmd>Rest run last<cr>",
      desc = "Run Last HTTP Request",
    },
  },
}