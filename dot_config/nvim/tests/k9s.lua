-- Run: nvim --headless -u NONE -l ~/.config/nvim/tests/k9s.lua
-- Uses a fake K9s process; never connects to a cluster or reads real kubeconfigs.
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/snacks.nvim")
require("snacks")
LazyVim = { root = vim.fn.getcwd }

local directory = vim.fn.tempname() .. " kubeconfigs"
vim.fn.mkdir(directory .. "/cache", "p")
vim.fn.writefile({}, directory .. "/alpha.yaml")
vim.fn.writefile({}, directory .. "/beta config")
vim.fn.writefile({ "#!/bin/sh", "printf '%s\\n' \"$KUBECONFIG\"", "exec sleep 60" }, directory .. "/k9s")
vim.fn.setfperm(directory .. "/k9s", "rwx------")
vim.env.PATH = directory .. ":" .. vim.env.PATH
vim.env.KUBECONFIG = directory .. "/alpha.yaml"

-- Stub only Pi; allow scheduled callbacks so eager K9s startup fails this check.
local open_terminal = Snacks.terminal.open
Snacks.terminal.open = function(cmd, opts)
  if cmd[1] == "pi" then
    return { hide = function() end }
  end
  return open_terminal(cmd, opts)
end
dofile(vim.fn.expand("~/.config/nvim/lua/config/keymaps.lua"))
vim.wait(20, function() return false end)
local toggle = vim.fn.maparg("<leader>ak", "n", false, true).callback
local select_config = vim.fn.maparg("<leader>aK", "n", false, true).callback
assert(#Snacks.terminal.list() == 0, "K9s must not start with Neovim")

local function current_terminal()
  local terminals = Snacks.terminal.list()
  assert(#terminals == 1, "Expected exactly one retained terminal")
  return terminals[1]
end
local function wait_for_output(term, expected)
  assert(vim.wait(2000, function()
    return table.concat(vim.api.nvim_buf_get_lines(term.buf, 0, -1, false), "\n"):find(expected, 1, true)
  end), "Fake K9s did not receive expected KUBECONFIG")
end
local function choose(name)
  vim.ui.select = function(items, opts, callback)
    assert(opts.prompt:find(directory, 1, true), "Picker must use KUBECONFIG parent")
    for _, path in ipairs(items) do
      assert(vim.fn.filereadable(path) == 1, "Picker must exclude directories")
      if vim.fs.basename(path) == name then
        callback(path)
        return
      end
    end
    assert(not name, "Expected file missing from picker")
    callback(nil)
  end
  select_config()
end

toggle()
local first = current_terminal()
local channel = vim.bo[first.buf].channel
wait_for_output(first, vim.env.KUBECONFIG)
toggle()
assert(not first:valid() and first:buf_valid(), "Hide must retain terminal buffer")
assert(vim.fn.jobwait({ channel }, 0)[1] == -1, "Hide must retain process")
toggle()
assert(current_terminal() == first and first:valid(), "Toggle must reuse process")
choose(nil)
assert(current_terminal() == first, "Cancel must preserve process")
choose("beta config")
local second = current_terminal()
assert(second ~= first and not first:buf_valid(), "Selection must replace old process")
wait_for_output(second, directory .. "/beta config")
assert(vim.env.KUBECONFIG == directory .. "/alpha.yaml", "Picker must not change editor environment")
choose("beta config")
assert(current_terminal() == second, "Selecting same config must reuse process")
local hide = vim.fn.maparg("<C-\\><C-k>", "t", false, true)
assert(hide.buffer == 1, "Hide chord must be terminal-buffer-local")
hide.callback()
assert(not second:valid() and second:buf_valid(), "Hide chord must retain buffer")

-- Simulate a failed process that leaves a valid terminal buffer behind.
local second_channel = vim.bo[second.buf].channel
vim.fn.jobstop(second_channel)
assert(vim.wait(2000, function()
  return vim.fn.jobwait({ second_channel }, 0)[1] ~= -1
end), "Fake process did not exit")
toggle()
local third = current_terminal()
assert(third ~= second, "Dead terminal must restart")
wait_for_output(third, directory .. "/beta config")
third:close()
vim.wait(50, function() return false end)

-- Colon-separated KUBECONFIG uses the first file's folder.
dofile(vim.fn.expand("~/.config/nvim/lua/config/keymaps.lua"))
vim.wait(20, function() return false end)
select_config = vim.fn.maparg("<leader>aK", "n", false, true).callback
vim.env.KUBECONFIG = directory .. "/alpha.yaml:" .. directory .. "/beta config"
choose(nil)
local warnings = {}
vim.notify = function(message) warnings[#warnings + 1] = message end
vim.env.KUBECONFIG = directory .. "/missing/config"
select_config()
assert(#warnings == 1 and warnings[1]:find("No kubeconfig", 1, true), "Empty folder must warn")
vim.fn.delete(directory, "rf")
print("K9s checks passed: lazy start, env, picker, hide/reuse, switch, cancel, restart")
vim.cmd("qa!")
