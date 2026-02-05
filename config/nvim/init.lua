-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

--Tabs / indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Searching
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- UX
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"

-- Leader key
vim.g.mapleader = " "

-- Show installed Treesitter parsers (replacement for :TSInstallInfo)
vim.api.nvim_create_user_command("TSInstalled", function()
  local parser_dir = vim.fn.stdpath("data") .. "/site/parser"
  local files = vim.fn.glob(parser_dir .. "/*.so", false, true)

  if #files == 0 then
    print("No Treesitter parsers found in: " .. parser_dir)
    return
  end

  local langs = {}
  for _, f in ipairs(files) do
    local name = vim.fn.fnamemodify(f, ":t"):gsub("%.so$", "")
    table.insert(langs, name)
  end
  table.sort(langs)

  print("Installed Treesitter parsers (" .. #langs .. "): " .. table.concat(langs, ", "))
end, {})

-- Install lazy.nvim if it's not present
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)


require("lazy").setup({
  -- Which-key
  { "folke/which-key.nvim", config = true },
  {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local ok, configs = pcall(require, "nvim-treesitter.configs")
    if not ok then return end
    configs.setup({ highlight = { enable = true } })
  end,
  },
  -- 1) Mason: installs language servers (inside Neovim)
  { "williamboman/mason.nvim", config = true },

  -- 2) Mason bridge: ensures servers are installed
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "ts_ls", "pyright", "bashls", },
        automatic_enable = false,
      })
    end,
  },

  -- 3) LSP configs + enable (Neovim 0.11+ style)
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

      -- LSP keymaps only when a server attaches
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local opts = { buffer = ev.buf }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        end,
      })

      -- Lua server tweaks (so it doesn't complain about global `vim`)
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
          },
        },
      })

      -- Enable the servers (Mason provides the executables)
      vim.lsp.enable({ "lua_ls", "ts_ls", "pyright", "bashls",},
      {
        capabilities = capabilities,
      }
      )
    end,
  },
  {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    local cmp = require("cmp")

    cmp.setup({
      mapping = {
        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<CR>"]  = cmp.mapping.confirm({ select = true }),
      },
      sources = {
        { name = "nvim_lsp" },
      },
    })
  end,
  },
  -- Telescope
  {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local telescope = require("telescope")
    telescope.setup({})
  end,
},
  -- neo-tree
  {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- optional, but recommended
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("neo-tree").setup({
      close_if_last_window = true,
      filesystem = {
        follow_current_file = {
          enabled = true,
        },
        hijack_netrw_behavior = "open_default",
      },
      window = {
        position = "left",
        width = 30,
        mappings = {
          ["<space>"] = "toggle_node",
          ["<CR>"] = "open",
          ["q"] = "close_window",
        },
      },
    })
  end,
},
  -- window-picker
  {
    's1n7ax/nvim-window-picker',
    name = 'window-picker',
    event = 'VeryLazy',
    version = '2.*',
    config = function()
        require'window-picker'.setup()
    end,
},
  -- bufferline (tabs)
  {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = "nvim-tree/nvim-web-devicons",
  config = function()
    require("bufferline").setup({
      options = {
        diagnostics = "nvim_lsp",
        separator_style = "slant",
        show_buffer_close_icons = false,
        show_close_icon = false,
      },
    })
  end,
},


})



vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })
vim.keymap.set("n", "<leader>ff", function()
  require("telescope.builtin").find_files()
end, { desc = "Find files" })

vim.keymap.set("n", "<leader>fg", function()
  require("telescope.builtin").live_grep()
end, { desc = "Grep text" })

vim.keymap.set("n", "<leader>fb", function()
  require("telescope.builtin").buffers()
end, { desc = "Buffers" })
vim.keymap.set(
  "n",
  "<leader>e",
  "<cmd>Neotree toggle<CR>",
  { desc = "Toggle file explorer" }
)
vim.keymap.set("n", "<leader>1", "<cmd>BufferLineGoToBuffer 1<CR>")
vim.keymap.set("n", "<leader>2", "<cmd>BufferLineGoToBuffer 2<CR>")
vim.keymap.set("n", "<leader>3", "<cmd>BufferLineGoToBuffer 3<CR>")

vim.keymap.set("n", "<Tab>",   "<cmd>BufferLineCycleNext<CR>")
vim.keymap.set("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<CR>")

