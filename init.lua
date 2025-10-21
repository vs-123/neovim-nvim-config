------------------------------------------------------------
-- Basic Settings
------------------------------------------------------------
vim.o.number = true
vim.o.relativenumber = true

vim.o.termguicolors = true
vim.o.mouse = 'a'
vim.cmd.colorscheme("habamax")

vim.o.shortmess = vim.o.shortmess .. 'I'
vim.o.directory = vim.fn.expand("~/.vim/swapfiles//")

local function spam_random_string(max_len)
   local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
   math.randomseed(os.time())
   local output = {}
   for _ = 1, max_len do
      local index = math.random(1, #chars)
      table.insert(output, chars:sub(index, index))
   end
   return table.concat(output)
end

-- Spam Greeting
vim.api.nvim_create_autocmd("VimEnter", {
   callback = function()
      local length = math.random(5, 50)
      print(spam_random_string(length))
   end
})

------------------------------------------------------------
-- Editor Settings
------------------------------------------------------------
vim.o.tabstop = 3
vim.o.shiftwidth = 3
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.cindent = false

vim.o.scrolloff = 3
vim.o.textwidth = 80
-- vim.o.colorcolumn = true
vim.o.cursorline = true
-- vim.o.formatoptions = vim.o.formatoptions .. 't'
vim.o.wildmenu = true
vim.o.incsearch = true
vim.o.hlsearch = true
vim.o.timeout = true
vim.o.timeoutlen = 0
vim.o.belloff = "all"

vim.o.omnifunc = ""

------------------------------------------------------------
-- Keymap Settings
------------------------------------------------------------
local paste_enabled = false

local function TogglePaste()
   paste_enabled = not paste_enabled
   if paste_enabled then
      vim.o.paste = true
      print("Paste enabled!")
   else
      vim.o.paste = false
      print("Paste disabled!")
   end
end

vim.g.mapleader = ' '
vim.keymap.set("n", "<leader>n", ":tabnew<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>h", ":tabprevious<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>l", ":tabnext<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>H", ":tabm-1<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>L", ":tabm+1<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>q", ":tabclose<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>t", ":term<CR>", { noremap = true, silent = true })
vim.keymap.set("t", "<esc>", "<C-\\><C-n>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>e", ":NERDTreeToggle<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>r", ":NERDTreeMirror<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>E", ":NERDTreeToggle %:h<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>p", TogglePaste, { noremap = true, silent = true })

vim.keymap.set('n', '<leader>yp', function()
   local path = vim.fn.expand('%:p')
   vim.fn.setreg('+', path)
   print("Yanked path: " .. path)
end, { desc = "Yank current file path to clipboard" })

function Center_banner(text)
   local width = 60
   local padding = math.floor((width - #text) / 2) - 2
   local line = "/*" .. string.rep(" ", padding) .. text .. string.rep(" ", width - #text - padding - 4) .. "*/"
   vim.api.nvim_set_current_line(line)
end

-- Call it like this:
-- -- :lua Center_banner("Your centered message")

------------------------------------------------------------
-- Plugins
------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
   { "preservim/nerdtree" },
   { "neovim/nvim-lspconfig" },
   { "folke/neodev.nvim" },
   { "tpope/vim-surround" },
   { "ray-x/lsp_signature.nvim" },
   { "mfussenegger/nvim-dap" },
   { "rcarriga/nvim-dap-ui",
      dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
   },
   { "theHamsta/nvim-dap-virtual-text", 
     dependencies = { "mfussenegger/nvim-dap" },
   },
   { "nvim-lua/plenary.nvim" },
   { "Civitasv/cmake-tools.nvim",
      dependencies = {
         "nvim-lua/plenary.nvim",
         "mfussenegger/nvim-dap",
      },
   },
   { "folke/which-key.nvim" },
   {
      "hrsh7th/nvim-cmp",
      dependencies = {
         "hrsh7th/cmp-nvim-lsp",
         "hrsh7th/cmp-buffer",
         "hrsh7th/cmp-path",
         "hrsh7th/cmp-cmdline",
         "L3MON4D3/LuaSnip",
         "saadparwaiz1/cmp_luasnip",
      },
   },
   { "hrsh7th/cmp-nvim-lsp-signature-help" },
})

------------------------------------------------------------
-- nvim-cmp
------------------------------------------------------------
local cmp = require("cmp")

cmp.setup({
   completion = { autocomplete = false },
   mapping = cmp.mapping.preset.insert({
      ["<C-y>"] = cmp.mapping.complete(),
      ["<CR>"] = cmp.mapping.confirm({ select = true }),
      ["<C-n>"] = cmp.mapping.select_next_item(),
      ["<C-p>"] = cmp.mapping.select_prev_item(),
   }),
   sources = cmp.config.sources({
      { name = "nvim_lsp" },
      { name = "nvim_lsp_signature_help" },
      { name = "buffer" },
      { name = "path" },
      { name = "luasnip" },
   }),
})

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

------------------------------------------------------------
-- LSP
------------------------------------------------------------
local lsp_util = require("lspconfig.util")

local on_attach = function(client, bufnr)
   local opts = { buffer = bufnr, silent = true }
   vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover, opts)
   vim.keymap.set("n", "<leader>K", vim.diagnostic.open_float, opts)
   vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
   vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
   vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, opts)
   vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, opts)
   vim.keymap.set("n", "<leader>d", vim.diagnostic.setloclist, opts)
   -- vim.keymap.del("i", "<C-s>")
   pcall(vim.keymap.del, "i", "<C-s>")
   require("lsp_signature").setup({
      bind = true,
      floating_window = false,
      hint_enable = false,
      toggle_key = "<C-s>"
   })
end

-- My root detection
local function compute_root_dir(bufnr)
   local fname = vim.api.nvim_buf_get_name(bufnr or 0)
   local start = (#fname > 0) and vim.fs.dirname(fname) or vim.loop.cwd()
   local found = vim.fs.find({ "compile_commands.json", ".git" }, { path = start, upward = true })[1]
   return found and vim.fs.dirname(found) or start
end

-- Base clangd client config
local clangd_base = {
   name = "clangd",
   cmd = { "clangd", "--compile-commands-dir=build" },
   filetypes = { "c", "cpp", "objc", "objcpp" },
   on_attach = on_attach,
   capabilities = capabilities,
}

-- Start clangd per buffer with my root_dir
vim.api.nvim_create_autocmd("FileType", {
   pattern = { "c", "cpp", "objc", "objcpp" },
   callback = function(args)
      local bufnr = args.buf
      local cfg = vim.tbl_extend("force", {}, clangd_base, {
         root_dir = compute_root_dir(bufnr),
      })
      vim.lsp.start(cfg)
   end,
})

vim.diagnostic.config({
   virtual_text = false,
   underline = true,
   signs = true,
   float = { border = "rounded" },
})

------------------------------------------------------------
-- Lua LSP (for Neovim config only)
------------------------------------------------------------
require("neodev").setup()

-- Root detection: only treat my Neovim config dir as a project
local function compute_lua_root(bufnr)
   local fname = vim.api.nvim_buf_get_name(bufnr or 0)
   if fname:match(vim.fn.stdpath("config")) then
      return vim.fn.stdpath("config")
   end
   -- Don't attach outside my config
   return nil
end

local lua_ls_base = {
   name = "lua_ls",
   cmd = { "lua-language-server" },
   filetypes = { "lua" },
   on_attach = on_attach,
   settings = {
      Lua = {
         runtime = { version = "LuaJIT" },
         diagnostics = { globals = { "vim" } },
         workspace = {
            library = {
               vim.env.VIMRUNTIME,
               vim.fn.stdpath("config"),
            },
            checkThirdParty = false,
         },
         telemetry = { enable = false },
      },
   },
   capabilities = capabilities,
}

vim.api.nvim_create_autocmd("FileType", {
   pattern = "lua",
   callback = function(args)
      local bufnr = args.buf
      local root = compute_lua_root(bufnr)
      if not root then return end  -- skip random Lua scripts
      local cfg = vim.tbl_extend("force", {}, lua_ls_base, { root_dir = root })
      vim.lsp.start(cfg)
      vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
   end,
})

------------------------------------------------------------
-- DAP
------------------------------------------------------------
local dap = require("dap")

dap.adapters.lldb = {
   type = "executable",
   command = "lldb-dap",
   name = "lldb"
}

dap.configurations.cpp = {
   {
      name = "Launch with LLDB",
      type = "lldb",
      request = "launch",
      program = function()
         return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "\\", "file")
      end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
      args = {},
   },
}

local dapui = require("dapui")
dapui.setup()

dap.listeners.after.event_initialized["dapui_config"] = function()
   dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
   dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
   dapui.close()
end

require("nvim-dap-virtual-text").setup()

------------------------------------------------------------
-- cmake-tools
------------------------------------------------------------

require("cmake-tools").setup {
   cmake_command = "cmake",
   cmake_build_directory = "build",
   -- always export compile_commands.json
   cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" },
   cmake_build_options = {},
   cmake_console_size = 10,
   cmake_show_console = "always", -- "always", "only_on_error"
   cmake_dap_configuration = {
      name = "Launch with LLDB",
      type = "lldb",
      request = "launch",
      stopOnEntry = false,
      runInTerminal = false,
   },
}

------------------------------------------------------------
-- which-key (Keybinds)
------------------------------------------------------------
local wk = require("which-key")

require("which-key").setup({
   win = {
      border = "rounded",
      title = true,
      title_pos = "center",
      zindex = 1000,
      row = 1,
      col = -1,
      width = 40,
      padding = { 1, 2 },
   },
   layout = {
      align = "right",
      spacing = 3,
   },
   delay = 0
})

wk.add({
   { "<leader>d",  group = "Debug (DAP)" },
   { "<leader>dc", "<cmd>lua require('dap').continue()<CR>", desc = "Continue" },
   { "<leader>db", "<cmd>lua require('dap').toggle_breakpoint()<CR>", desc = "Toggle Breakpoint" },
   { "<leader>dB", "<cmd>lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>", desc = "Breakpoint with Condition" },
   { "<leader>do", "<cmd>lua require('dap').step_over()<CR>", desc = "Step Over" },
   { "<leader>di", "<cmd>lua require('dap').step_into()<CR>", desc = "Step Into" },
   { "<leader>dO", "<cmd>lua require('dap').step_out()<CR>", desc = "Step Out" },
   { "<leader>du", "<cmd>lua require('dapui').toggle()<CR>", desc = "Toggle DAP UI" },
})

