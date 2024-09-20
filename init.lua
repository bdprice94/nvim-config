-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = ","
vim.g.maplocalleader = " "

require("lazy").setup({
    -- tpope is a saint
    "tpope/vim-fugitive",
    "tpope/vim-dispatch",
    -- debugger
    "puremourning/vimspector",

    -- necessary utils for many plugins
    "nvim-lua/plenary.nvim",

    -- fzf replacement
    "nvim-telescope/telescope.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim",
        build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release" },

    -- quick_fix preview because some things like that
    'kevinhwang91/nvim-bqf',

    -- LSP and autocomplete
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "neovim/nvim-lspconfig",
    "hrsh7th/nvim-cmp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-nvim-lsp",
    "saadparwaiz1/cmp_luasnip",
    "hrsh7th/cmp-nvim-lsp-signature-help",
    { "L3MON4D3/LuaSnip",
        build = "make install_jsregexp", },
    {
        'mrcjkb/rustaceanvim',
        version = '^5',
        lazy = false,
    },

    -- Nicer diff view
    "sindrets/diffview.nvim",

    -- Make things pretty
    "ellisonleao/gruvbox.nvim",
    "nvim-tree/nvim-web-devicons",
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

    -- small utilities
    { 'windwp/nvim-autopairs',
        event = "InsertEnter", config = true },
    "sitiom/nvim-numbertoggle"

})

require('nvim-treesitter.configs').setup {
  -- A list of parser names, or "all" (the five listed parsers should always be installed)
  auto_install = true,
  ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "toml", "rust" },
  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}

require('telescope').load_extension('fzf')

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function fzf_multi_select(prompt_bufnr)
    local picker = action_state.get_current_picker(prompt_bufnr)
    local num_selections = #picker:get_multi_selection()

    if num_selections > 1 then
        actions.send_selected_to_qflist(prompt_bufnr)
        actions.open_qflist(prompt_bufnr)
    else
        actions.file_edit(prompt_bufnr)
    end
end

require("telescope").setup {
  pickers = {
    find_files = {
      mappings = {
        i = {
          ["<C-j>"] = "move_selection_next",
          ["<C-k>"] = "move_selection_previous",
          ["<CR>"] = fzf_multi_select,
        },
      },
    },
    live_grep = {
      mappings = {
        i = {
          ["<C-j>"] = "move_selection_next",
          ["<C-k>"] = "move_selection_previous",
          ["<CR>"] = fzf_multi_select,
        },
      },
    }
  },
}

-- luasnip setup
local luasnip = require('luasnip')

-- nvim-cmp setup
local cmp = require('cmp')
cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-k>'] = cmp.mapping.scroll_docs(-4), -- Up
    ['<C-j>'] = cmp.mapping.scroll_docs(4), -- Down
    -- C-b (back) C-f (forward) for snippet placeholder navigation.
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'nvim_lsp_signature_help'},
    { name = 'buffer'},
  },
}

require('mason').setup()

require('mason-lspconfig').setup()

-- Add additional capabilities supported by nvim-cmp
local capabilities = require("cmp_nvim_lsp").default_capabilities()

require("mason-lspconfig").setup_handlers {
    -- The first entry (without a key) will be the default handler
    -- and will be called for each installed server that doesn't have
    -- a dedicated handler.
    function (server_name) -- default handler (optional)
        require("lspconfig")[server_name].setup {
            capabilities = capabilities
        }
    end,
    ["lua_ls"] = function ()
        -- This config ensures the LSP is correctly configured for nvim config files
        require('lspconfig').lua_ls.setup{
            capabilities = capabilities,
            settings = {
                Lua = {
                    runtime = {
                        version = 'LuaJit',
                    },
                    diagnostics = {
                        globals = {'vim'},
                    },
                    workspace = {
                        library = vim.api.nvim_get_runtime_file("", true),
                    },
                },
            },
        }
    end,

}

vim.g.rustaceanvim = {
  server = {
    cmd = function()
      local mason_registry = require('mason-registry')
      local ra_binary = mason_registry.is_installed('rust-analyzer')
        -- This may need to be tweaked, depending on the operating system.
        and mason_registry.get_package('rust-analyzer'):get_install_path() .. "/rust-analyzer"
        or "rust-analyzer"
      return { ra_binary } -- You can add args to the list, such as '--log-file'
    end,
  },
}

-- set options --
vim.o.shada = '\'100,<50,s10,h,n~/.vim/.viminfo'
vim.o.tabstop = 4
vim.o.shiftwidth = 0
vim.o.expandtab = true
vim.o.cursorline = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true -- caps queries turns on strict checking
vim.o.hlsearch = true
vim.o.mouse = 'a' -- all mouse interactions allowed
vim.o.number = true
vim.o.relativenumber = true
vim.o.signcolumn = "number"
vim.o.visualbell = true
vim.o.termguicolors = true
vim.o.background = 'dark'
vim.o.updatetime = 300
vim.o.signcolumn = 'yes'
vim.o.background = "dark" -- or "light" for light mode
vim.cmd([[colorscheme gruvbox]])

if (vim.fn.executable('rg')) then
    vim.o.grepformat = '+=%f:%l:%c:%m'
    vim.o.grepprg='rg --vimgrep --no-heading'
end

-- user defined commands

-- Function to quickly print the location of the file, or the linked-to file if current file is a symlink
local find_link = function ()
    return vim.fn.resolve(vim.fn.expand('%:p'))
end
vim.api.nvim_create_user_command('FindLink', function() print(find_link()) end, {})

local write_save_quit = function ()
    vim.cmd [[wa | mks! | qa]]
end

-- This function probably is not needed and can just directly send things to the '+' register
local copy_to_clickboard = function()
    if (vim.fn.has('clipboard')) then
        vim.fn.setreg('+', vim.fn.getreg('c', 1))
    end
end

-- mappings
vim.keymap.set('n', '', '<cmd>tabe<cr>')

local tel_builtin = require('telescope.builtin')
local find_files_custom = function()
    tel_builtin.find_files({hidden=true})
end
vim.keymap.set('n', '', find_files_custom, {})
vim.keymap.set('n', '灛', tel_builtin.live_grep, {})
vim.keymap.set('n', 'ZZ', write_save_quit, {})

vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, {})
        vim.keymap.set('n', '<leader>ac', vim.lsp.buf.code_action, {})
        vim.keymap.set('n', 'gr',         vim.lsp.buf.references, {})
        vim.keymap.set('i', '',         vim.lsp.buf.signature_help, {})

        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client then
            if client.supports_method('textDocument/definition') then
                vim.keymap.set('n', 'gd', vim.lsp.buf.definition)
            end
            if client.supports_method('textDocument/diagnostics') then
                vim.keymap.set('n', '[h',         vim.diagnostic.goto_prev, {})
                vim.keymap.set('n', ']h',         vim.diagnostic.goto_next, {})
            end
        end
    end
})
