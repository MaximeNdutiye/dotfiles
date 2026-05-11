return {
  "yetone/avante.nvim",
  enabled = true,
  event = "VeryLazy",
  lazy = true,
  version = false, -- set this if you want to always pull the latest change
  opts = {
    -- add any opts here
    debug = true,
    provider = "shopify",
    providers = {
      shopify = {
        __inherited_from = "openai",
        endpoint = "https://proxy.shopify.ai/v1",
        api_key_name = "cmd:/opt/dev/bin/devx llm-gateway print-token --key",
      },
    },
    behaviour = {
      auto_suggestions = false, -- Experimental stage
      auto_set_highlight_group = true,
      auto_set_keymaps = true,
      auto_apply_diff_after_generation = false,
      support_paste_from_clipboard = true,
    },
    mappings = {
      ask = "<leader>aa",
      -- I don't use these, remote later
      edit = "<leader>ae",
      refresh = "<leader>ar",
      diff = {
        ours = "co",
        theirs = "ct",
        all_theirs = "ca",
        both = "cb",
        cursor = "cc",
        next = "]x",
        prev = "[x",
      },
      suggestion = {
        accept = "<M-l>",
        next = "<M-]>",
        prev = "<M-[>",
        dismiss = "<C-]>",
      },
      jump = {
        next = "]]",
        prev = "[[",
      },
      submit = {
        normal = "<CR>",
        insert = "<C-s>",
      },
      sidebar = {
        apply_all = "A",
        apply_cursor = "a",
        switch_windows = "<Tab>",
        reverse_switch_windows = "<S-Tab>",
      },
    },
  },
  -- keys: the list of keymaps will be extended with your custom keymaps
  keys = function(_, keys)
    ---@type avante.Config
    local opts =
      require("lazy.core.plugin").values(require("lazy.core.config").spec.plugins["avante.nvim"], "opts", false)

    local mappings = {
      {
        opts.mappings.ask,
        function() require("avante.api").ask() end,
        desc = "avante: ask",
        mode = { "n", "v" },
      },
      {
        opts.mappings.refresh,
        function() require("avante.api").refresh() end,
        desc = "avante: refresh",
        mode = "v",
      },
      {
        opts.mappings.edit,
        function() require("avante.api").edit() end,
        desc = "avante: edit",
        mode = { "n", "v" },
      },
    }
    mappings = vim.tbl_filter(function(m) return m[1] and #m[1] > 0 end, mappings)
    return vim.list_extend(mappings, keys)
  end,
  -- Patch avante's broken cursor-rules glob -> Lua-pattern conversion.
  -- Upstream (as of Apr 2026) doesn't strip YAML array syntax (`[`, `]`, `"`)
  -- and doesn't escape Lua pattern metacharacters before its `*` -> `[^/]*`
  -- substitution. With Shopify's .cursor/rules/*.mdc files (which use the
  -- `globs: ["**/*.rb", ...]` form), this produces malformed patterns and
  -- throws "malformed pattern (missing ']')" on every WinEnter while the
  -- avante sidebar is open. See yetone/avante.nvim lua/avante/utils/prompts.lua.
  config = function(_, opts)
    require("avante").setup(opts)

    local prompts = require("avante.utils.prompts")
    local Utils = require("avante.utils")

    -- Escape Lua pattern metacharacters except `*` (which we expand below).
    local function escape_pattern(s)
      return (s:gsub("([%^%$%(%)%%%.%[%]%+%-%?])", "%%%1"))
    end

    local function glob_to_pattern(glob)
      return escape_pattern(glob):gsub("%*%*/", ""):gsub("%*%*", ".+"):gsub("%*", "[^/]*")
    end

    prompts.get_cursor_rules_prompt = function(selected_files)
      local ok, result = pcall(function()
        local project_root = Utils.get_project_root()
        local accumulated = ""
        local mdc_files = vim.fn.globpath(
          Utils.join_paths(project_root, ".cursor/rules"),
          "*.mdc",
          false,
          true
        )
        for _, file_path in ipairs(mdc_files) do
          local content = vim.fn.readfile(file_path)
          if content[1] == "---" and content[5] == "---" then
            local header = table.concat(content, "\n", 2, 4)
            local body = table.concat(content, "\n", 6)
            local _desc, globs, alwaysApply =
              header:match("description:%s*(.*)\nglobs:%s*(.*)\nalwaysApply:%s*(.*)")
            if globs then
              -- Strip YAML array brackets and quotes: `["a", "b"]` -> `a, b`
              globs = vim.trim(globs):gsub("^%[", ""):gsub("%]$", ""):gsub('"', "")
              if globs ~= "" then
                local patterns = {}
                for _, glob in ipairs(vim.split(globs, ",%s*")) do
                  glob = vim.trim(glob)
                  if glob ~= "" then
                    patterns[#patterns + 1] = glob_to_pattern(glob)
                  end
                end
                if alwaysApply == "true" then
                  accumulated = accumulated .. "\n" .. body
                else
                  for _, sf in ipairs(selected_files) do
                    local matched = false
                    for _, p in ipairs(patterns) do
                      local mok, m = pcall(string.match, sf.path, p)
                      if mok and m then matched = true break end
                    end
                    if matched then
                      accumulated = accumulated .. "\n" .. body
                      break
                    end
                  end
                end
              end
            end
          end
        end
        return accumulated ~= "" and accumulated or nil
      end)
      if not ok then
        vim.schedule(function()
          vim.notify("avante cursor-rules patch: " .. tostring(result), vim.log.levels.DEBUG)
        end)
        return nil
      end
      return result
    end
  end,
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  build = "make",
  -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
  dependencies = {
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- The below dependencies are optional,
    "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    "MeanderingProgrammer/render-markdown.nvim",
    -- "zbirenbaum/copilot.lua", -- for providers='copilot'
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          -- required for Windows users
          use_absolute_path = true,
          verbose = false,
        },
      },
    },
  },
}
