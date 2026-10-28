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

local k9s_term
local k9s_config

local function k9s_running()
  return k9s_term
    and k9s_term:buf_valid()
    and vim.fn.jobwait({ vim.bo[k9s_term.buf].channel }, 0)[1] == -1
end

local function show_k9s()
  if not k9s_running() then
    if vim.fn.executable("k9s") ~= 1 then
      vim.notify("k9s is not available on PATH", vim.log.levels.ERROR)
      return
    end
    if k9s_term and k9s_term:buf_valid() then
      k9s_term:close()
    end
    k9s_term = Snacks.terminal.open({ "k9s" }, {
      cwd = vim.fn.getcwd(),
      env = k9s_config and { KUBECONFIG = k9s_config } or nil,
      start_insert = false,
      auto_insert = false,
      auto_close = false,
      win = {
        position = "float",
        width = 0.9,
        height = 0.9,
        border = "rounded",
        title = " K9s ",
        title_pos = "center",
        on_buf = function(term)
          term:on("TermClose", function()
            if vim.v.event.status == 0 then
              vim.schedule(function()
                term:close()
              end)
            end
          end, { buf = true })
        end,
        keys = {
          hide_k9s = { "<C-\\><C-k>", "hide", mode = "t", desc = "Hide K9s" },
        },
      },
    })
  end
  k9s_term:show():focus()
  vim.cmd.startinsert()
end

map("n", "<leader>ak", function()
  if k9s_running() and k9s_term:valid() then
    k9s_term:hide()
  else
    show_k9s()
  end
end, { desc = "Toggle K9s" })

map("n", "<leader>aK", function()
  local config = k9s_config or vim.env.KUBECONFIG
  -- KUBECONFIG may contain multiple paths; browse siblings of its first file.
  local first = config and vim.split(config, ":", { trimempty = true })[1]
  local directory = vim.fs.dirname(vim.fs.abspath(first or vim.fn.expand("~/.kube/config")))
  local files = {}
  if vim.fn.isdirectory(directory) == 1 then
    for _, name in ipairs(vim.fn.readdir(directory)) do
      local path = vim.fs.joinpath(directory, name)
      if vim.fn.filereadable(path) == 1 then
        files[#files + 1] = path
      end
    end
  end
  table.sort(files)
  if #files == 0 then
    vim.notify("No kubeconfig files found in " .. directory, vim.log.levels.WARN)
    return
  end
  vim.ui.select(files, {
    prompt = "K9s kubeconfig: " .. directory,
    format_item = vim.fs.basename,
  }, function(path)
    if not path then
      return
    end
    if path ~= k9s_config then
      if k9s_term and k9s_term:buf_valid() then
        k9s_term:close()
      end
      k9s_term = nil
      k9s_config = path
    end
    show_k9s()
  end)
end, { desc = "K9s: Select kubeconfig" })

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
