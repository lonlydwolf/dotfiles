return {
  {
    "Tobin Palmer/Tip.nvim",
    event = "VimEnter",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      -- Background job to fetch and cache tips
      local cache_file = vim.fn.stdpath("cache") .. "/tips_cache.json"
      local url = "https://vtip.43z.one" -- Returns a single tip. We might need a bulk endpoint or just fetch one per session to build a history.
      
      -- Since vtip returns just one tip, we'll fetch one per session and append/rotate it in our cache.
      require("plenary.job"):new({
        command = "curl",
        args = { "-s", "-L", url },
        on_exit = function(j, return_val)
          if return_val == 0 then
            local result = table.concat(j:result(), "\n")
            if result and result ~= "" then
                -- Read existing cache
                local tips = {}
                local f = io.open(cache_file, "r")
                if f then
                    local content = f:read("*a")
                    f:close()
                    local ok, decoded = pcall(vim.json.decode, content)
                    if ok and type(decoded) == "table" then tips = decoded end
                end
                
                -- Add new tip (avoid duplicates if possible, strict set is hard with simple logic, just push)
                -- We'll keep the last 50 unique tips.
                local exists = false
                for _, t in ipairs(tips) do
                    if t == result then exists = true break end
                end
                
                if not exists then
                    table.insert(tips, result)
                    if #tips > 50 then table.remove(tips, 1) end -- Rotate
                    
                    -- Save back
                    local w = io.open(cache_file, "w")
                    if w then
                        w:write(vim.json.encode(tips))
                        w:close()
                    end
                end
            end
          end
        end,
      }):start()
    end,
  },
  -- Removed nvim-notify as we are moving tips to Alpha exclusively
}