# Neovim IDE Setup on Arch Linux (lazy.nvim + LSP + Formatting)

> This is the raw Markdown file content for your repo.

---

## 1) Install dependencies (Arch)

### Neovim
```bash
sudo pacman -S neovim
```

### Required system tools
```bash
sudo pacman -S git curl unzip nodejs npm python python-pip
```

### Clipboard support
```bash
sudo pacman -S xclip          # X11
# or
sudo pacman -S wl-clipboard   # Wayland
```

### Formatters
```bash
sudo pacman -S shfmt
pip install --user black isort
npm install -g prettier
```

### For live grep (Telescope)
```bash
sudo pacman -S ripgrep
```

---

## 2) Create config directory
```bash
mkdir -p ~/.config/nvim
```

---

## 3) Create `~/.config/nvim/init.lua` with this content

```lua
--
================================================================================
-- Options
--
================================================================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt
opt.mouse          = "a"
opt.number         = true
opt.relativenumber = true
opt.tabstop        = 4
opt.shiftwidth     = 4
opt.expandtab      = true
opt.encoding       = "utf-8"
opt.clipboard      = "unnamedplus"
opt.cursorline     = true
opt.hlsearch       = true
opt.incsearch      = true
opt.ignorecase     = true
opt.smartcase      = true
opt.termguicolors  = true
opt.scrolloff      = 8
opt.signcolumn     = "yes"
opt.updatetime     = 250
opt.wrap           = false
opt.splitright     = true
opt.splitbelow     = true

--
================================================================================
-- Keymaps
--
================================================================================
local map = vim.keymap.set

-- Clipboard
map("v", "<C-c>", '"+y',    { desc = "Copy to clipboard" })
map("n", "<C-v>", '"+p',    { desc = "Paste from clipboard" })
map("i", "<C-v>", "<C-R>+", { desc = "Paste from clipboard (insert)" })

-- Clear search highlight
map("n", "<Esc>", ":nohlsearch<CR>", { silent = true })

-- Edit/reload config
map("n", "<leader>ev", ":edit $MYVIMRC<CR>",   { desc = "Edit config" })
map("n", "<leader>sv", ":source $MYVIMRC<CR>", { desc = "Reload config" })

-- Move lines in visual mode
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })

--
================================================================================
-- Per-filetype indentation
--
================================================================================
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "sh", "yaml", "json", "html", "css", "javascript", "typescript", "markdown" },
  callback = function()
    vim.opt_local.shiftwidth  = 2
    vim.opt_local.tabstop     = 2
    vim.opt_local.softtabstop = 2
  end,
})

--
================================================================================
-- Bootstrap lazy.nvim
--
================================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

--
================================================================================
-- Plugins
--
================================================================================
require("lazy").setup({

  -- ── Colorscheme
  ------------------------------------------------------------------------------
  {
    "catppuccin/nvim",
    name     = "catppuccin",
    priority = 1000,
    config   = function()
      require("catppuccin").setup({ flavour = "mocha" })
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },

  -- ── Treesitter
  ------------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    build  = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
        ensure_installed = {
          "python", "bash", "markdown", "markdown_inline",
          "javascript", "typescript", "lua", "json", "yaml",
          "html", "css", "vim", "vimdoc",
        },
        highlight = { enable = true },
        indent    = { enable = true },
      })
    end,
  },

  -- ── LSP: Mason (auto-install servers)
  ------------------------------------------------------------------------------
  { "williamboman/mason.nvim", config = true },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",  -- provides server definitions via vim.lsp.config
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed       = { "pyright", "bashls", "ts_ls", "lua_ls" },
        automatic_installation = true,
      })

      -- Apply capabilities to all servers (nvim 0.11+ API)
      vim.lsp.config("*", {
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
      })

      -- Lua-specific override
      vim.lsp.config("lua_ls", {
        settings = { Lua = { diagnostics = { globals = { "vim" } } } },
      })

      vim.lsp.enable({ "pyright", "bashls", "ts_ls", "lua_ls" })
    end,
  },

  { "neovim/nvim-lspconfig" },

  -- ── Autocompletion
  ------------------------------------------------------------------------------
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp     = require("cmp")
      local luasnip = require("luasnip")

      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"]     = cmp.mapping.abort(),
          ["<CR>"]      = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- ── Formatting
  ------------------------------------------------------------------------------
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          python     = { "black", "isort" },
          sh         = { "shfmt" },
          javascript = { "prettier" },
          typescript = { "prettier" },
          markdown   = { "prettier" },
          json       = { "prettier" },
          yaml       = { "prettier" },
          html       = { "prettier" },
          css        = { "prettier" },
        },
        format_on_save = {
          timeout_ms   = 500,
          lsp_fallback = true,
        },
      })
      vim.keymap.set({ "n", "v" }, "<leader>f", function()
        require("conform").format({ async = true, lsp_fallback = true })
      end, { desc = "Format buffer" })
    end,
  },

  -- ── File Explorer
  ------------------------------------------------------------------------------
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch       = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle file explorer" })
    end,
  },

  -- ── Fuzzy Finder
  ------------------------------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local b = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", b.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", b.live_grep,  { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", b.buffers,    { desc = "Find buffers" })
      vim.keymap.set("n", "<leader>fh", b.help_tags,  { desc = "Help tags" })
      vim.keymap.set("n", "<leader>fr", b.oldfiles,   { desc = "Recent files" })
    end,
  },

  -- ── Statusline
  ------------------------------------------------------------------------------
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({ options = { theme = "catppuccin" } })
    end,
  },

  -- ── Git
  ------------------------------------------------------------------------------
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          local o  = { buffer = bufnr }
          vim.keymap.set("n", "]c", gs.next_hunk,            o)
          vim.keymap.set("n", "[c", gs.prev_hunk,            o)
          vim.keymap.set("n", "<leader>hp", gs.preview_hunk, o)
          vim.keymap.set("n", "<leader>hr", gs.reset_hunk,   o)
        end,
      })
    end,
  },

  -- ── Markdown Rendering
  ------------------------------------------------------------------------------
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft     = { "markdown" },
    config = function()
      require("render-markdown").setup({
        heading = { enabled = true },
        code    = { enabled = true, style = "full" },
      })
      vim.keymap.set("n", "<leader>m", ":RenderMarkdown toggle<CR>", { desc = "Toggle markdown render" })
    end,
  },

  -- ── Auto Pairs
  ------------------------------------------------------------------------------
  { "windwp/nvim-autopairs", event = "InsertEnter", config = true },

  -- ── Comment toggle (gcc = line, gc in visual = block)
  ------------------------------------------------------------------------------
  { "numToStr/Comment.nvim", config = true },

  -- ── Indent guides
  ------------------------------------------------------------------------------
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", config = true },

  -- ── Which-key (shows available keymaps on Space)
  ------------------------------------------------------------------------------
  { "folke/which-key.nvim", event = "VeryLazy", config = true },

}, {
  ui = { border = "rounded" },
})

--
================================================================================
-- LSP keymaps (attached per-buffer when LSP connects)
--
================================================================================
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    local o = { buffer = event.buf }
    map("n", "gd",         vim.lsp.buf.definition,     vim.tbl_extend("force", o, { desc = "Go to definition" }))
    map("n", "gD",         vim.lsp.buf.declaration,    vim.tbl_extend("force", o, { desc = "Go to declaration" }))
    map("n", "gr",         vim.lsp.buf.references,     vim.tbl_extend("force", o, { desc = "References" }))
    map("n", "gi",         vim.lsp.buf.implementation, vim.tbl_extend("force", o, { desc = "Go to implementation" }))
    map("n", "K",          vim.lsp.buf.hover,          vim.tbl_extend("force", o, { desc = "Hover docs" }))
    map("n", "<leader>rn", vim.lsp.buf.rename,         vim.tbl_extend("force", o, { desc = "Rename symbol" }))
    map("n", "<leader>ca", vim.lsp.buf.code_action,    vim.tbl_extend("force", o, { desc = "Code action" }))
    map("n", "<leader>d",  vim.diagnostic.open_float,  vim.tbl_extend("force", o, { desc = "Show diagnostic" }))
    map("n", "[d",         vim.diagnostic.goto_prev,   vim.tbl_extend("force", o, { desc = "Prev diagnostic" }))
    map("n", "]d",         vim.diagnostic.goto_next,   vim.tbl_extend("force", o, { desc = "Next diagnostic" }))
  end,
})
```

---

## 4) First launch

```bash
nvim
```

lazy.nvim bootstraps itself, installs all plugins, then Mason installs the language servers (pyright, bashls, ts_ls, lua_ls) automatically.

---

## Cheatsheet

| Key | Action |
|---|---|
| Space | Show all keymaps (which-key) |
| Space e | File explorer |
| Space ff | Find files |
| Space fg | Live grep |
| Space f | Format buffer |
| gd | Go to definition |
| K | Hover docs |
| Space rn | Rename symbol |
| Space ca | Code action |
| Space d | Show diagnostic |
| gcc | Toggle comment (line) |
| gc (visual) | Toggle comment (block) |
| Space m | Toggle markdown render |
| :Mason | Manage LSP servers |
| :Lazy | Manage plugins |
