#!/bin/bash

VIMRC=~/.vimrc
cat << EOF > ${VIMRC}
" Hybrid line numbers (https://github.com/josiahdavis/dotfiles/blob/master/.vimrc)
"
" Prefer built-in over RltvNmbr as the later makes vim even slower on
" high-latency aka. cross-region instance.
:set number relativenumber
:augroup numbertoggle
:  autocmd!
:  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
:  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
:augroup END

" Relative number only on focused-windoes (see: jeffkreeftmeijer/vim-numbertoggle)
autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &number | set relativenumber   | endif
autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &number | set norelativenumber | endif

" Remap keys to navigate window aka split screens to ctrl-{h,j,k,l}
" See: https://vi.stackexchange.com/a/3815
"
" Vim defaults to ctrl-w-{h,j,k,l}. However, ctrl-w on Linux (and Windows)
" closes browser tab.
"
" NOTE: ctrl-l was "clear and redraw screen". The later can still be invoked
"       with :redr[aw][!]
nmap <C-h> <C-w>h
nmap <C-j> <C-w>j
nmap <C-k> <C-w>k
nmap <C-l> <C-w>l

" Stanza extracted from https://github.com/verdimrc/linuxcfg/blob/main/.vimrc
set laststatus=2
set hlsearch
set colorcolumn=80
set splitbelow
set splitright

set lazyredraw
set nottyfast

autocmd FileType help setlocal number
autocmd BufNewFile,BufRead *.jl set filetype=julia
autocmd BufNewFile,BufRead *.cu set filetype=cuda
autocmd BufNewFile,BufRead *.cuh set filetype=cuda
autocmd BufEnter *.yaml,*.yml :set indentkeys-=0#
if v:version >= 800
    " Smart paste mode. See Vim's xterm-bracketed-paste help topic.
    let &t_BE = "\<Esc>[?2004h"
    let &t_BD = "\<Esc>[?2004l"
    let &t_PS = "\<Esc>[200~"
    let &t_PE = "\<Esc>[201~"
endif

""" Coding style
" Prefer spaces to tabs
filetype indent on
filetype plugin indent on
set tabstop=4
set shiftwidth=4
set expandtab
set nowrap
set foldmethod=indent
set foldlevel=99
set smartindent

""" Shortcuts
map <F3> :set paste!<CR>
" Use <leader>l to toggle display of whitespace
nmap <leader>l :set list!<CR>

" Highlight trailing space without plugins -- https://stackoverflow.com/a/48951029
highlight RedundantSpaces ctermbg=red guibg=red
match RedundantSpaces /\s\+$/

" Terminado supports 256 colors
set t_Co=256
set cursorline
highlight CursorLine cterm=None ctermbg=236
highlight CursorLineNr cterm=None ctermbg=236
"colorscheme delek
"colorscheme elflord
"colorscheme murphy
"colorscheme ron
highlight colorColumn ctermbg=237

if exists('$KITTY_WINDOW_ID') || $TERM == "xterm-kitty"
    let &t_ut=''
endif
EOF
