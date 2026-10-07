-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

local pi_term
local pi_opts = {
  cwd = LazyVim.root(),
  start_insert = false,
  auto_insert = false,
  auto_close = true,
  win = {
    position = "float",
    width = 0.9,
    height = 0.9,
    border = "rounded",
    title = " Pi ",
    title_pos = "center",
  },
}

local function get_pi()
  if not (pi_term and pi_term:buf_valid()) then
    pi_term = Snacks.terminal.open({ "pi" }, pi_opts)
  end
  return pi_term
end

local function show_pi()
  local term = get_pi()
  term:show():focus()
  vim.cmd.startinsert()
  return term
end

vim.schedule(function()
  get_pi():hide()
end)

map("n", "<leader>ap", function()
  if pi_term and pi_term:valid() then
    pi_term:hide()
  else
    show_pi()
  end
end, { desc = "Toggle Pi" })

map("x", "<leader>ap", function()
  local selection = table.concat(
    vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getcurpos(), { type = vim.fn.mode() }),
    "\n"
  )
  local term = show_pi()
  vim.api.nvim_chan_send(vim.bo[term.buf].channel, "\27[200~" .. selection .. "\27[201~\n\n")
end, { desc = "Send selection to Pi" })

-- Disable arrow keys in normal and visual mode
map({ "n", "x" }, "<Up>", "<nop>", { desc = "Arrow Up (disabled)" })
map({ "n", "x" }, "<Down>", "<nop>", { desc = "Arrow Down (disabled)" })
map({ "n", "x" }, "<Left>", "<nop>", { desc = "Arrow Left (disabled)" })
map({ "n", "x" }, "<Right>", "<nop>", { desc = "Arrow Right (disabled)" })

-- Disable arrow keys in insert mode
map("i", "<Up>", "<nop>", { desc = "Arrow Up (disabled - Insert)" })
map("i", "<Down>", "<nop>", { desc = "Arrow Down (disabled - Insert)" })
map("i", "<Left>", "<nop>", { desc = "Arrow Left (disabled - Insert)" })
map("i", "<Right>", "<nop>", { desc = "Arrow Right (disabled - Insert)" })
