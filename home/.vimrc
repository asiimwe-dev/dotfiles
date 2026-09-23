"" ============================================================================
"" 1. AUTOMATIC PLUGIN MANAGER SETUP (vim-plug)
"" ============================================================================
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
    " 1. Fuzzy file finder (Essential for modern projects)
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'

    " 2. Easy code commenting (gcc to comment line, gc in visual mode)
    Plug 'tpope/vim-commentary'

    " 3. Surround selections with quotes, parens, brackets (cs"', ysiw])
    Plug 'tpope/vim-surround'

    " 4. Git diff indicators in sign column (+ / -)
    Plug 'airblade/vim-gitgutter'

    " 5. Minimalist & fast status line
    Plug 'itchyny/lightline.vim'
call plug#end()

"" ============================================================================
"" 2. GENERAL & UI SETTINGS
"" ============================================================================
set nocompatible
filetype plugin indent on
syntax on

set encoding=utf-8
set hidden                    " Switch buffers without saving
set number relativenumber     " Hybrid relative line numbers
set cursorline                " Highlight current line
set scrolloff=8               " Keep 8 lines visible above/below cursor
set signcolumn=yes            " Always show sign column for Git signs
set updatetime=100            " Faster update for gitgutter responsiveness

" Show relative file path in window title bar
set title
set titlestring=%f\ %m

" Status line settings for Lightline
set laststatus=2              " Always display status line
set noshowmode                " Hide default '-- INSERT --' since Lightline displays it

" Lightline config with Git branch indicator
let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'gitbranch': 'FugitiveHead'
      \ },
      \ }

" Persistent Undo across sessions
if has('persistent_undo')
    set undofile
    set undodir=~/.vim/undo//
endif

"" ============================================================================
"" 3. INDENTATION & SEARCH
"" ============================================================================
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
set autoindent
set smartindent

set ignorecase
set smartcase
set hlsearch
set incsearch

"" ============================================================================
"" 4. KEYMAPS & SHORTCUTS
"" ============================================================================
let mapleader = " "           " Set Space as leader key

" Quick escape to Normal mode
inoremap jj <Esc>
inoremap jk <Esc>

" Clear search highlight
nnoremap <Leader><Space> :nohlsearch<CR>

" Window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Buffer management
nnoremap <Leader>bn :bnext<CR>
nnoremap <Leader>bp :bprevious<CR>
nnoremap <Leader>bd :bdelete<CR>

" File Explorer & Finder Shortcuts
nnoremap <Leader>e :Lexplore 25<CR>
nnoremap <Leader>f :Files<CR>         " Search files in current project (FZF)
nnoremap <Leader>b :Buffers<CR>       " Search open buffers (FZF)

"" ============================================================================
"" 5. LANGUAGE-SPECIFIC INDENTATION
"" ============================================================================
augroup LanguageIndentation
    autocmd!
    autocmd FileType javascript,typescript,javascriptreact,typescriptreact setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
    autocmd FileType html,css,scss,vue,svelte setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
    autocmd FileType json,yaml,yml,toml setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
    autocmd FileType python,c,cpp,rust,java setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
    autocmd FileType go,make setlocal tabstop=4 shiftwidth=4 softtabstop=4 noexpandtab
augroup END

"" ============================================================================
"" 6. AUTOMATION & DIRECTORY FIXES
"" ============================================================================
augroup DeveloperConfig
    autocmd!
    autocmd BufWritePre * %s/\s\+$//e  " Remove trailing whitespace on save
    autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

    " Ensure standard directory structures exist for swap, backup, and undo
    autocmd VimEnter * call mkdir(expand('~/.vim/swap'), 'p')
    autocmd VimEnter * call mkdir(expand('~/.vim/backup'), 'p')
    autocmd VimEnter * call mkdir(expand('~/.vim/undo'), 'p')
augroup END
