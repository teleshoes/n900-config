set ic
set history=9000
set nocompatible
set nowrap
syntax on

set number
hi LineNr ctermfg=black ctermbg=gray guifg=black guibg=gray

set hlsearch
set expandtab
set autoindent
set smarttab
set tabstop=4
set softtabstop=4
set shiftwidth=4

map  <F2> i
imap <F2> <Esc>

map  <C-X><C-C> :q!<CR>
imap <C-X><C-C> <Esc>:q!<CR>

map  <C-C> :q<CR>
imap <C-C> <Esc>:q<CR>

map  <F3> :w<CR>
imap <F3> <Esc>:w<CR>li

imap <C-D> <Esc>ddli
imap <C-P> <Esc>pli

map  <C-U> u


map  <F5> :w<CR>:RUN<CR>
imap <F5> <Esc>:w<CR>:RUN<CR>li

map  <F6> :w<CR>:RUN<Space>
imap <F6> <Esc>:w<CR>:RUN<Space>

command -nargs=* RUN call RUN(<f-args>)
function RUN(...)
    perldo `rm -rf ~/.CONSOLE.swp`
    1wincmd w
    let interpreter = strpart(getline(1),2)
    let abspath = expand("%:p")
    let arguments = join(a:000, " ")
    let runcmd = interpreter . ' ' . abspath . ' ' . arguments
    
    let sep = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
    
    let slurp = "perl -0777 -e 'print qq(" . sep . ") . <>;'"

    let encode = "perldo s/&/&amp;/g; s/;/&semi;/g; s/\n/&nl;/g;"
    let decode = "%s/&nl;/\r/ge | %s/&semi;/;/ge | %s/&amp;/&/ge"

    let format = '%s/' .
               \       '\(\_.*\)' . sep . '\(\_.*\)' .
               \   '/' .
               \       '\2' . sep . '\r' . '\1' .
               \   '/'

    if winnr("$") == 1
        below new ~/.CONSOLE
    endif
    2wincmd w

    %s/\_.*/-temp-/g

    execute 'perldo $_=`(' . runcmd . ' | ' . slurp . ') 2>&1 `;'
    
    execute encode
    execute decode
    execute format

    normal 1G
    1wincmd w
endfunction

