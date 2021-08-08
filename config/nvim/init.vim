call plug#begin('~/.vim/plugged')
"Theme
Plug 'arcticicestudio/nord-vim'
Plug 'vim-airline/vim-airline'

"NerdTree Stuff
Plug 'preservim/nerdtree'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'ryanoasis/vim-devicons'

"Language Stuff
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'honza/vim-snippets'
Plug 'scrooloose/nerdcommenter'
Plug 'suan/vim-instant-markdown', {'for': 'markdown'}
Plug 'adimit/prolog.vim'
Plug 'pearofducks/ansible-vim'
call plug#end()

"Coc extensions
let g:coc_global_extensions = [
  \ 'coc-clangd',
  \ 'coc-cmake',
  \ 'coc-css',
  \ 'coc-cssmodules',
  \ 'coc-docker',
  \ 'coc-discord-rpc',
  \ 'coc-emmet',
  \ 'coc-eslint',
  \ 'coc-gist',
  \ 'coc-git',
  \ 'coc-go',
  \ 'coc-html',
  \ 'coc-htmldjango',
  \ 'coc-html-css-support',
  \ 'coc-java',
  \ 'coc-json',
  \ 'coc-markdownlint',
  \ 'coc-pairs',
  \ 'coc-prettier',
  \ 'coc-pydocstring',
  \ 'coc-pyright',
  \ 'coc-sh',
  \ 'coc-stylelintplus',
  \ 'coc-spell-checker',
  \ 'coc-snippets',
  \ 'coc-sql',
  \ 'coc-terminal',
  \ 'coc-texlab',
  \ 'coc-xml',
  \ 'coc-yaml',
  \ ]

syntax on
colorscheme nord
set background=dark

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

"Shortcuts
nnoremap <C-s> :w<CR>
nnoremap <C-s-q> :wq<CR>
nnoremap <C-q> :q!<CR>
nmap <C-f> :NERDTreeToggle<CR>
vmap ce <plug>NERDCommenterToggle
nmap ce <plug>NERDCommenterToggle
nmap t <Plug>(coc-terminal-toggle)
set clipboard+=unnamedplus

"Autocomplete
inoremap <silent><expr> <TAB>
      \ pumvisible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

let g:coc_snippet_next = '<tab>'
