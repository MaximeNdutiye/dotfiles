return {
  "mfussenegger/nvim-dap",
  optional = true,
  dependencies = {
    {
      "williamboman/mason.nvim",
      opts = function(_, opts)
        opts.ensure_installed = opts.ensure_installed or {}
        table.insert(opts.ensure_installed, "js-debug-adapter")
      end,
    },
  },
  opts = function()
    local dap = require "dap"

    vim.cmd "let g:cursorhold_updatetime = 100"
    if not dap.adapters["pwa-node"] then
      require("dap").adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "node",
          -- 💀 Make sure to update this path to point to your installation
          args = {
            require("mason-registry").get_package("js-debug-adapter"):get_install_path()
              .. "/js-debug/src/dapDebugServer.js",
            "${port}",
          },
        },
      }
    end
    -- vscode only has node we add this here so that we can debug with it's launch.json
    if not dap.adapters["node"] then
      dap.adapters["node"] = function(cb, config)
        if config.type == "node" then config.type = "pwa-node" end
        local nativeAdapter = dap.adapters["pwa-node"]
        if type(nativeAdapter) == "function" then
          nativeAdapter(cb, config)
        else
          cb(nativeAdapter)
        end
      end
    end
    local js_filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" }

    local vscode = require "dap.ext.vscode"
    vscode.type_to_filetypes["node"] = js_filetypes
    vscode.type_to_filetypes["pwa-node"] = js_filetypes

    for _, language in ipairs(js_filetypes) do
      if not dap.configurations[language] then
        dap.configurations[language] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file",
            program = "${file}",
            cwd = "${workspaceFolder}",
          },
          {
            type = "node-terminal",
            request = "launch",
            name = "Launch node terminal",
            program = "${file}",
            cwd = "${workspaceFolder}",
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
          {
            type = "pwa-node",
            request = "launch",
            name = "Debug Jest Tests",
            trace = true, -- include debugger info
            runtimeExecutable = "sh",
            program = "${workspaceFolder}/node_modules/.bin/jest",
            args = {
              "${relativeFile}",
              "--runInBand",
            },
            env = {
              IS_DEBUGGING_TESTS = "true",
            },
            rootPath = "${workspaceFolder}",
            cwd = "${workspaceFolder}",
            console = "integratedTerminal",
            internalConsoleOptions = "neverOpen",
            stopOnEntry = false, -- Add this line
            resolveSourceMapLocations = {
              "${workspaceFolder}/",
              "!/node_modules/**",
            },
          },
        }
      end
    end
  end,
}
