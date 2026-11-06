return {
  -- Peek definitions/references in a floating window (gpd, gpt, gpi, gpr, gP in keymaps.lua)
  "rmagatti/goto-preview",
  event = "BufEnter",
  config = function()
    require("goto-preview").setup({})
  end,
}
