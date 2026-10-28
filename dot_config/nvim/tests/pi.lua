-- Run: nvim --headless -u NONE -l ~/.config/nvim/tests/pi.lua
-- Uses a fake Pi process; never starts the real agent.
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/snacks.nvim")
require("snacks")
LazyVim = { root = vim.fn.getcwd }

local directory = vim.fn.tempname()
vim.fn.mkdir(directory, "p")
vim.fn.writefile({ "#!/bin/sh", "exec sleep 60" }, directory .. "/pi")
vim.fn.setfperm(directory .. "/pi", "rwx------")
vim.env.PATH = directory .. ":" .. vim.env.PATH
local errors = {}
Snacks.notify.error = function(message) errors[#errors + 1] = message end

dofile(vim.fn.expand("~/.config/nvim/lua/config/keymaps.lua"))
assert(vim.wait(2000, function() return #Snacks.terminal.list() == 1 end), "Pi startup did not run")
local toggle = vim.fn.maparg("<leader>ap", "n", false, true).callback
local restart = vim.fn.maparg("<leader>aP", "n", false, true).callback
local function terminal()
  local terminals = Snacks.terminal.list()
  assert(#terminals == 1, "Expected exactly one Pi terminal")
  return terminals[1]
end

local first = terminal()
assert(not first:valid() and first:buf_valid(), "Startup must retain hidden Pi")
toggle()
assert(terminal() == first and first:valid(), "Toggle must preserve existing Pi")
local first_channel = vim.bo[first.buf].channel
restart()
local second = terminal()
assert(second ~= first and not first:buf_valid(), "Restart must replace Pi buffer")
assert(vim.fn.jobwait({ first_channel }, 0)[1] ~= -1, "Restart must stop old Pi process")
assert(second:valid(), "Restart must show new Pi")
assert(vim.fn.jobwait({ vim.bo[second.buf].channel }, 0)[1] == -1, "New Pi must be running")
toggle()
assert(not second:valid(), "Toggle must hide new Pi")
restart()
local third = terminal()
assert(third ~= second and not second:buf_valid() and third:valid(), "Hidden Pi must restart too")
vim.wait(20, function() return false end)
assert(#errors == 0, "Intentional restart must not report an error: " .. table.concat(errors, "; "))

vim.api.nvim_clear_autocmds({ event = "TermClose", group = third.augroup, buffer = third.buf })
third:close()
vim.fn.delete(directory, "rf")
print("Pi checks passed: toggle, visible restart, hidden restart, stopped old process, no false errors")
vim.cmd("qa!")
