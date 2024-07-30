-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Example configs: https://github.com/LunarVim/starter.lvim
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny

lvim.plugins = {
  { "ellisonleao/gruvbox.nvim",         priority = 1000, config = true, opts = ... },
  { 'mfussenegger/nvim-dap-python' },
  { 'jbyuki/one-small-step-for-vimkind' },
  { 'davepinto/virtual-column.nvim' },
  { 'github/copilot.vim' },
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>",  "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>",  "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>",  "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>",  "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "canary",
    dependencies = {
      { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
      { "nvim-lua/plenary.nvim" },  -- for curl, log wrapper
    },
    opts = {
      debug = true, -- Enable debugging
      -- See Configuration section for rest
    },
    -- See Commands section for default commands if you want to lazy load on them
  },
}


lvim.leader = ";"

--no cut delete
lvim.keys.normal_mode["dd"] = '"_dd'
lvim.keys.visual_mode["dd"] = '"_d'
lvim.keys.normal_mode["d$"] = '"_d$'
lvim.keys.visual_mode["d$"] = '"_d$'
lvim.keys.normal_mode["dw"] = '"_dw'
lvim.keys.visual_mode["dw"] = '"_dw'

vim.api.nvim_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', { noremap = true, silent = true })

vim.cmd([[colorscheme gruvbox]])
lvim.background = "dark" -- or "light" for light mode

-- Default options:
require("gruvbox").setup({
  terminal_colors = true, -- add neovim terminal colors
  undercurl = true,
  underline = true,
  bold = true,
  italic = {
    strings = true,
    emphasis = true,
    comments = true,
    operators = false,
    folds = true,
  },
  strikethrough = true,
  invert_selection = false,
  invert_signs = false,
  invert_tabline = false,
  invert_intend_guides = false,
  inverse = true, -- invert background for search, diffs, statuslines and errors
  contrast = "",  -- can be "hard", "soft" or empty string
  palette_overrides = {},
  overrides = {},
  dim_inactive = false,
  transparent_mode = false,
})

lvim.colorscheme = "gruvbox"
lvim.builtin.project.patterns = { ">Projects", ".git" } -- defaults include other VCSs, Makefile, package.json

--require'lspconfig'.tsserver.setup{}
require 'lspconfig'.vuels.setup {}
require 'lspconfig'.vimls.setup {}
require 'lspconfig'.bashls.setup {}
require 'lspconfig'.csharp_ls.setup {}

local dap = require("dap")

dap.adapters["local-lua"] = {
  type = "executable",
  command = "node",
  args = {
    "/home/powerbox/source/tools/local-lua-debugger-vscode/extension/debugAdapter.js"
  },
  enrich_config = function(config, on_config)
    if not config["extensionPath"] then
      local c = vim.deepcopy(config)
      -- 💀 If this is missing or wrong you'll see
      -- "module 'lldebugger' not found" errors in the dap-repl when trying to launch a debug session
      c.extensionPath = "/home/powerbox/source/tools/local-lua-debugger-vscode"
      on_config(c)
    else
      on_config(config)
    end
  end,
}

dap.configurations.lua = {
  {
    name = 'Current file (local-lua-dbg, lua)',
    type = 'local-lua',
    request = 'launch',
    cwd = '${workspaceFolder}',
    program = {
      lua = 'lua5.1',
      file = '${file}',
    },
    args = {},
  },
}

dap.adapters.coreclr = {
  type = 'executable',
  command = '/home/powerbox/bin/netcoredbg/netcoredbg',
  args = { '--interpreter=vscode' }
}

dap.configurations.cs = {
  {
    type = "coreclr",
    name = "launch - netcoredbg",
    request = "launch",
    program = function()
      if vim.fn.fnamemodify(vim.fn.getcwd(), ":t") == 'build' then
        vim.api.nvim_command('cd .. ')
      end

      vim.api.nvim_command('!dotnet build . --output ./build')

      local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")

      if vim.fn.fnamemodify(vim.fn.getcwd(), ":t") ~= 'build' then
        vim.api.nvim_command('cd build')
      end
      if vim.fn.fnamemodify(vim.fn.getcwd() .. '/' .. project_name ..
            '.dll', ":t") ~= nil then
        return vim.fn.getcwd() .. '/' .. project_name .. '.dll'
      else
        return vim.fn.input('Path to dll ', vim.fn.getcwd() .. '/', 'file')
      end
    end
  },
}

dap.adapters.lldb = {
  type = 'executable',
  command = '/usr/bin/lldb-dap-18', -- adjust as needed, must be absolute path
  name = 'lldb',
}

dap.configurations.cpp = {
  {
    name = 'DEBUG',
    type = 'lldb',
    request = 'launch',
    program = function()
      if vim.fn.fnamemodify(vim.fn.getcwd(), ":t") ~= 'build' then
        vim.api.nvim_command('cd build')
      else
        vim.api.nvim_command('echo no build folder found')
      end

      vim.api.nvim_command('!cmake ..')
      vim.api.nvim_command('!make')
      return vim.fn.input('Path to executable (Remember to build before): ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    args = {},
  },
}

require('lspconfig').clangd.setup {
  cmd = { "clangd", "--compile-commands-dir= ." }, -- Assumes compile_commands.json is in the project root
}

require("dap-python").setup("python")

--fix line endings from windows to linux paste
function Trim()
  local save = vim.fn.winsaveview()
  vim.cmd("keeppatterns %s/\\s\\+$\\|\\r$//e")
  vim.fn.winrestview(save)
end

-- Define a new function to paste and trim
function Paste_and_trim()
  -- Perform the default paste action
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('p', true, false, true), 'n', false)
  -- Call the trim function
  vim.schedule(function()
    Trim()
  end)
end

-- Set the keybinding for 'p' to the new function
--vim..set('n', 'p', paste_and_trim, { noremap = true, silent = true })
--lvim.key
lvim.keys.normal_mode["p"] = ":lua Paste_and_trim()<CR>"
vim.api.nvim_create_user_command('Trim', function() Trim() end, {})

--formats
lvim.format_on_save = true
