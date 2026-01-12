return {
  {
    'goolord/alpha-nvim',
    dependencies = {
      'nvim-tree/nvim-web-devicons',
      'TobinPalmer/Tip.nvim', -- Now handled by lazy via custom/plugins/tip.lua
    },
    config = function()
      local alpha = require 'alpha'
      local dashboard = require 'alpha.themes.dashboard'

      -- 1. HEADER: "LONLY D.WOLF" + "NVIM" Block
      local ascii_art = {
        [[██╗      ██████╗ ███╗   ██╗██╗  ██╗   ██╗    ██████╗    ██╗    ██╗ ██████╗ ██╗     ███████╗]],
        [[██║     ██╔═══██╗████╗  ██║██║  ╚██╗ ██╔╝    ██╔══██╗   ██║    ██║██╔═══██╗██║     ██╔════╝]],
        [[██║     ██║   ██║██╔██╗ ██║██║   ╚████╔╝     ██║  ██║   ██║ █╗ ██║██║   ██║██║     █████╗  ]],
        [[██║     ██║   ██║██║╚██╗██║██║    ╚██╔╝      ██║  ██║   ██║███╗██║██║   ██║██║     ██╔══╝  ]],
        [[███████╗╚██████╔╝██║ ╚████║███████╗██║       ██████╔╝██╗╚███╔███╔╝╚██████╔╝███████╗██║     ]],
        [[╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝       ╚═════╝ ╚═╝ ╚══╝╚══╝  ╚═════╝ ╚══════╝╚═╝     ]],
        [[                                                                                           ]],
        [[                                     ▄▄  ▄▄ ▄▄ ▄▄ ▄▄ ▄▄   ▄▄                               ]],
        [[                                     ███▄██ ██▄██ ██ ██▀▄▀██                               ]],
        [[                                     ██ ▀██  ▀█▀  ██ ██   ██                               ]],
      }
      
      dashboard.section.header.val = ascii_art
      dashboard.section.header.opts.hl = "Label"
      dashboard.section.header.opts.position = "center"

      -- 2. QUICKLINKS & BUTTONS
      dashboard.section.buttons.val = {
        dashboard.button("e", "📄  New File", ":ene <BAR> startinsert <CR>"),
        dashboard.button("f", "🔍  Find File", ":Telescope find_files <CR>"),
        dashboard.button("c", "⚙️  Config", ":e $MYVIMRC <CR>"),
        dashboard.button("m", "🧱  Mason", ":Mason<CR>"),
        dashboard.button("l", "📦  Lazy", ":Lazy<CR>"),
        dashboard.button("q", "🚪  Quit", ":qa<CR>"),
      }
      dashboard.section.buttons.opts.spacing = 0

      -- 3. TIPS (Cache -> Fallback)
      local function get_tip()
        math.randomseed(os.time())
        
        -- Try reading from cache
        local cache_file = vim.fn.stdpath("cache") .. "/tips_cache.json"
        local cached_tips = {}
        local f = io.open(cache_file, "r")
        if f then
            local content = f:read("*a")
            f:close()
            local ok, decoded = pcall(vim.json.decode, content)
            if ok and type(decoded) == "table" and #decoded > 0 then
                cached_tips = decoded
            end
        end

        if #cached_tips > 0 then
            return cached_tips[math.random(#cached_tips)]
        end

        -- Fallback: Personalized Keymaps
        local local_tips = {
          "💡 <space>sh to Search Help documentation.",
          "💡 <leader>bd deletes buffer without closing window.",
          "💡 <leader>sn searches Neovim config files.",
          "💡 <C-h/j/k/l> to navigate between splits.",
          "💡 Oil.nvim: Press '-' to open parent directory.",
          "💡 Harpoon: <leader>a to add, <C-e> to toggle menu.",
          "💡 Treesitter: 'grn' renames variable under cursor.",
          "💡 Treesitter: 'grr' shows references for symbol.",
        }
        return local_tips[math.random(#local_tips)]
      end
      
      local tip_section = {
        type = 'text',
        val = function() 
            local tip = get_tip()
            local icons = { "󰋽", "💡", "󰛨", "🌟", "󰠮" }
            local icon = icons[math.random(#icons)]
            return {
                icon .. "  " .. tip,
            }
        end,
        opts = { 
            position = 'center', 
            hl = 'Comment', -- Subtle tip text
        },
      }

      -- 4. FOOTER (Simplified)
      local function footer()
        local version = vim.version()
        local nvim_version = string.format("v%d.%d.%d", version.major, version.minor, version.patch)
        
        local stats = require("lazy").stats()
        local ms = stats.startuptime or 0
        if ms == 0 and _G.nvim_start_time then
            local elapsed = vim.fn.reltimefloat(vim.fn.reltime(_G.nvim_start_time)) * 1000
            ms = elapsed
        end
        
        return string.format("⚡ %.1fms  •  📦 %d plugins  •  %s", ms, stats.count, nvim_version)
      end

      dashboard.section.footer.val = footer()
      dashboard.section.footer.opts.hl = "Number"
      dashboard.section.footer.opts.position = "center"

      -- 5. LAYOUT
      alpha.setup {
        layout = {
          { type = "padding", val = 2 },
          dashboard.section.header,
          { type = "padding", val = 2 },
          { type = "text", val = "QuickLinks", opts = { hl = "SpecialComment", position = 'center' } },
          { type = "padding", val = 1 },
          dashboard.section.buttons,
          { type = "padding", val = 2 },
          { type = "text", val = "---  Knowledge Base  ---", opts = { hl = "NonText", position = 'center' } },
          { type = "padding", val = 1 },
          tip_section,
          { type = "padding", val = 2 },
          dashboard.section.footer,
        },
        opts = { margin = 5 },
      }

      -- 6. HOOKS: Cursor, Statusline, and Auto-Open
      vim.api.nvim_create_autocmd("User", {
        pattern = "AlphaReady",
        callback = function()
          -- Save original state
          local current_guicursor = vim.opt.guicursor:get()
          
          -- Hide UI
          vim.opt.cmdheight = 0
          vim.opt.laststatus = 0
          
          -- Hide Cursor (Blend + Guicursor Method)
          local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = 'Cursor' })
          if ok then
            hl.blend = 100
            vim.api.nvim_set_hl(0, 'Cursor', hl)
            -- Force usage of the blended Cursor group for all modes
            vim.opt.guicursor:append('a:Cursor/lCursor')
          end

          -- Setup Restore Hook (Local to this buffer)
          vim.api.nvim_create_autocmd("BufUnload", {
            buffer = 0,
            callback = function()
              vim.opt.cmdheight = 1
              vim.opt.laststatus = 3
              
              -- Restore Cursor
              if ok then
                hl.blend = 0
                vim.api.nvim_set_hl(0, 'Cursor', hl)
                vim.opt.guicursor = current_guicursor
              end
            end,
          })
        end,
      })

      -- Auto-open Alpha when landing on empty buffer (after :bd)
      vim.api.nvim_create_autocmd("BufEnter", {
        callback = function()
          local buf_name = vim.api.nvim_buf_get_name(0)
          if buf_name == "" and vim.bo.buftype == "" and vim.fn.line('$') == 1 and vim.fn.getline(1) == "" then
             local listed_buffers = 0
             for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.bo[buf].buflisted then
                    listed_buffers = listed_buffers + 1
                end
             end
             if listed_buffers <= 1 then
                vim.cmd("Alpha")
             end
          end
        end,
      })
    end,
  },
}