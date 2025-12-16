-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

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
