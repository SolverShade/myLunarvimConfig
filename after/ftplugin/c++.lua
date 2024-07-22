local linters = require "lvim.lsp.null-ls.linters"
linters.setup { { command = "clang-format", filetypes = { "c++" } } }
