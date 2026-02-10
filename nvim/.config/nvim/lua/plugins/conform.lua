-- Formatter configuration (from old config)
return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      json = { "prettier" },
      jsonc = { "prettier" },
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      html = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },
      yaml = { "prettier" },
      markdown = { "prettier" },
      lua = { "stylua" },
      python = { "black" },
      go = { "gofmt" },
      ruby = { "rubocop" },
    },
    formatters = {
      prettier = {
        prepend_args = function()
          return { "--tab-width", tostring(vim.bo.shiftwidth) }
        end,
      },
    },
    format_on_save = {
      timeout_ms = 500,
      lsp_fallback = true,
    },
  },
}
