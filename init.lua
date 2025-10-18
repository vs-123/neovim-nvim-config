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
vim.o.belloff = "all"

vim.o.completeopt = "menuone,noinsert,noselect"
vim.g.asyncomplete_auto_popup = 0

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

vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>E", ":NvimTreeToggle %:h<CR>", { noremap = true, silent = true })

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
   { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" } },
   { "neovim/nvim-lspconfig" },
   { "folke/neodev.nvim" }
   -- { "Issafalcon/lsp_signature.nvim", lazy = true }
})

------------------------------------------------------------
-- File Tree
------------------------------------------------------------
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("nvim-tree").setup({
   view = { width = 30, side = "left" },
   filters = { dotfiles = false },
   renderer = { group_empty = true },
   on_attach = function(bufnr)
		local api = require("nvim-tree.api")
		local opts = { noremap = true, silent = true, buffer = bufnr }

      vim.keymap.set("n", "v", api.node.open.vertical, opts)
      vim.keymap.set("n", "s", api.node.open.horizontal, opts)
      vim.keymap.set("n", "a", api.fs.create, opts)              -- create new file or folder
      vim.keymap.set("n", "d", api.fs.remove, opts)              -- delete
      vim.keymap.set("n", "r", api.fs.rename, opts)              -- rename
      vim.keymap.set("n", "x", api.fs.cut, opts)                 -- cut
      vim.keymap.set("n", "c", api.fs.copy.node, opts)           -- copy
      vim.keymap.set("n", "p", api.fs.paste, opts)               -- paste
      vim.keymap.set("n", "y", api.fs.copy.filename, opts)       -- copy filename
   end
})

------------------------------------------------------------
-- LSP
------------------------------------------------------------
local lsp_util = require("lspconfig.util")

local function show_all_signatures()
   local clients = vim.lsp.get_active_clients({ bufnr = 0 })
   local encoding = clients[1] and clients[1].offset_encoding or "utf-16"
   local params = lsp_util.make_position_params(0, encoding)

   vim.lsp.buf_request(0, "textDocument/signatureHelp", params, function(err, result)
      if err or not result or not result.signatures then return end
      local lines = {}
      for i, sig in ipairs(result.signatures) do
         local label = sig.label
         if result.activeSignature == i - 1 then
            label = "▶ " .. label
         end
         table.insert(lines, label)
      end
      lsp_util.open_floating_preview(lines, "lua", { border = "rounded" })
   end)
end

local on_attach = function(client, bufnr)
   local opts = { buffer = bufnr, silent = true }
   vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover, opts)
   vim.keymap.set("n", "<leader>K", vim.diagnostic.open_float, opts)
   vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
   vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
   vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, opts)
   vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, opts)
   vim.keymap.set("n", "<leader>d", vim.diagnostic.setloclist, opts)
   vim.keymap.set("i", "<C-s>", show_all_signatures, { silent = true })
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
      vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
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

