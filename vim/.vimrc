"------------------------------------------------------------------------------
" Vundle plugins
"------------------------------------------------------------------------------
set nocompatible " Disable vi-compatibility.
filetype off     " Required by vundle.

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" Fuzzy searching by ctrl + p
Plugin 'ctrlp.vim'

" Autocompletion
Plugin 'Valloric/YouCompleteMe'

" NERDtree sidebar 
Plugin 'scrooloose/nerdtree'
Plugin 'tiagofumo/vim-nerdtree-syntax-highlight'

" Solarized theme
Plugin 'altercation/vim-colors-solarized'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'

" Syntax checking
Plugin 'scrooloose/syntastic'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
"-------------------------------------------------------------------------------
"ctrlp plugin
let g:ctrlp_match_window = 'bottom,order:ttb' " sort results from top to bottom
"
set t_Co=256
set guifont=menlo\ for\ powerline:h13
set linespace=13
colorscheme solarized
set background=dark

"-------------------------------------------------------------------------------
" Airline plugin
let g:airline_powerline_fonts = 1
set laststatus=2                              " Without this it cannot be shown.
set ttimeoutlen=50


set showmode                    " always show what mode we're currently editing in
set nowrap                      " don't wrap lines
set tabstop=4                   " a tab is four spaces
set smarttab
set tags=tags
set softtabstop=4               " when hitting <BS>, pretend like a tab is removed, even if spaces
set expandtab                   " expand tabs by default (overloadable per file type later)
set shiftwidth=4
set shiftround                  " use multiple of shiftwidth when indenting with '<' and '>'
set backspace=indent,eol,start  " allow backspacing over everything in insert mode
set autoindent                  " always set autoindenting on
set copyindent                  " copy the previous indentation on autoindenting
set number                      " always show line numbers
set ignorecase                  " ignore case when searching
set smartcase                   " ignore case if search pattern is all lowercase,
set timeout timeoutlen=200 ttimeoutlen=100
set visualbell           " don't beep
set noerrorbells         " don't beep
set autowrite  "Save on buffer switch
set mouse=a
"set clipboard=unnamed           " Use a system clipboard.
imap jj <Esc>
map <C-l> mzgg=G`z
"
" easier move screen up/down
nmap <C-j> <C-e>
nmap <C-k> <C-y>
syntax enable


" Display lines
set number
set numberwidth=3
highlight LineNr term=bold cterm=NONE ctermfg=DarkGrey ctermbg=NONE gui=NONE guifg=DarkGrey guibg=NONE
set wildmode=full
set shiftwidth=4
filetype plugin indent on

"---------------------------------------------------------------------------------------------------
" NERDtree settings
" 1. If the NERDtree is the last window open close it as well.
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
" 2. Open/close NERDTree by <ctrl-n> key.
map <C-n> :NERDTreeToggle<CR>

