call plug#begin('~/.vim/plugged')
"Theme
Plug 'rakr/vim-one'
Plug 'vim-airline/vim-airline'

"NerdTree Stuff
Plug 'preservim/nerdtree'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'ryanoasis/vim-devicons'

"Language Stuff
Plug 'neoclide/coc.nvim', {'branch': 'release'}

Plug 'suan/vim-instant-markdown', {'for': 'markdown'}
call plug#end()

"Coc extensions
let g:coc_global_extensions = [
  \ 'coc-clangd',
  \ 'coc-discord-rpc',
  \ 'coc-eslint',
  \ 'coc-go',
  \ 'coc-html',
  \ 'coc-java',
  \ 'coc-json',
  \ 'coc-markdownlint',
  \ 'coc-python',
  \ 'coc-sh',
  \ 'coc-snippets',
  \ 'coc-sql',
  \ 'coc-texlab',
  \ 'coc-xml',
  \ 'coc-yaml',
  \ ]

syntax on
colorscheme one
set background=dark

let g:UltiSnipsExpandTrigger="<F2>"

"Use 24-bit (true-color) mode in Vim/Neovim when outside tmux.
"If you're using tmux version 2.2 or later, you can remove the outermost $TMUX check and use tmux's 24-bit color support
"(see < http://sunaku.github.io/tmux-24bit-color.html#usage > for more information.)
if (empty($TMUX))
  if (has("nvim"))
    "For Neovim 0.1.3 and 0.1.4 < https://github.com/neovim/neovim/pull/2198 >
    let $NVIM_TUI_ENABLE_TRUE_COLOR=1
  endif
  "For Neovim > 0.1.5 and Vim > patch 7.4.1799 < https://github.com/vim/vim/commit/61be73bb0f965a895bfb064ea3e55476ac175162 >
  "Based on Vim patch 7.4.1770 (`guicolors` option) < https://github.com/vim/vim/commit/8a633e3427b47286869aa4b96f2bfc1fe65b25cd >
  " < https://github.com/neovim/neovim/wiki/Following-HEAD#20160511 >
  if (has("termguicolors"))
    set termguicolors
  endif
endif

filetype plugin on

"Keymaps
nnoremap <C-s> :w<CR> 
nnoremap <C-s-q> :wq<CR>
nnoremap <C-q> :wq!<CR>
nmap <C-f> :NERDTreeToggle<CR>
vmap ce <plug>NERDCommenterToggle
nmap ce <plug>NERDCommenterToggle
set clipboard+=unnamedplus
