return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      terraformls = {
        on_init = function(client, _)
          -- Override capabilities before the server is fully initialized
          client.server_capabilities.semanticTokensProvider = nil
        end,
      },
    },
  },
}
