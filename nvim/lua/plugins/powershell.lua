return {
  "TheLeoP/powershell.nvim",
  ---@type powershell.user_config,
  config = function()
    local dataPath = vim.fn.stdpath("data")
    require("powershell").setup({
      capabilities = vim.lsp.protocol.make_client_capabilities(),
      init_options = vim.empty_dict(),
      shell = "pwsh",
      handlers = base_handlers, -- see lua/powershell/handlers.lua
      --root_dir = function(buf)
      --  return fs.dirname(
      --    fs.find({ ".git" }, { upward = true, path = fs.dirname(api.nvim_buf_get_name(buf)) })[1]
      --  )
      --end,
      bundle_path = dataPath .. "\\mason\\packages\\powershell-editor-services",
      on_attach = function(client, bufnr)
        vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
      end,
      settings = { powershell = { codeFormatting = { Preset = "OTBS" } } },
    })
  end,
}
