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

function center_banner(text)
   local width = 60
   local padding = math.floor((width - #text) / 2) - 2
   local line = "/*" .. string.rep(" ", padding) .. text .. string.rep(" ", width - #text - padding - 4) .. "*/"
   vim.api.nvim_set_current_line(line)
end

-- Call it like this:
-- -- :lua center_banner("Your centered message")
--

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

		-- Restore vertical split keybinding
		vim.keymap.set("n", "v", api.node.open.vertical, opts)

		-- Optional: also restore horizontal split
		vim.keymap.set("n", "s", api.node.open.horizontal, opts)
   end
})

------------------------------------------------------------
-- LSP
------------------------------------------------------------
local lspconfig = require("lspconfig")
local lsp_util = require("lspconfig.util")

local function show_all_signatures()
   local clients = vim.lsp.get_active_clients({ bufnr = 0 })
   local encoding = clients[1] and clients[1].offset_encoding or "utf-16"
   local params = lsp_util.make_position_params(0, encoding)

   vim.lsp.buf_request(0, "textDocument/signatureHelp", params, function(err, result, ctx, config)
      if err or not result or not result.signatures then return end

      local lines = {}
      for i, sig in ipairs(result.signatures) do
         local label = sig.label
         if result.activeSignature == i - 1 then
            -- Marking the active signature with this triangle thing
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
   vim.keymap.set("n", "<leader>d", vim.diagnostic.setloclist, { buffer = bufnr })
   vim.keymap.set("i", "<C-s>", show_all_signatures, { silent = true })
end

lspconfig.clangd.setup {
   on_attach = on_attach,
   cmd = { "clangd", "--compile-commands-dir=build" },
   filetypes = { "c", "cpp", "objc", "objcpp" },
   root_dir = lspconfig.util.root_pattern("compile_commands.json", ".git"),
}

vim.diagnostic.config({
   virtual_text = false,
   underline = true,
   signs = true,
   float = { border = "rounded" },
})

vim.o.completeopt = "menuone,noinsert,noselect"
vim.g.asyncomplete_auto_popup = 0

vim.api.nvim_create_autocmd("FileType", {
   pattern = { "c", "cpp" },
   callback = function()
      vim.bo.omnifunc = "v:lua.vim.lsp.omnifunc"
   end,
})

