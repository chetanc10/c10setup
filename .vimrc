
" Highlight search results
" set hlsearch

" Makes search act like search in modern browsers
set incsearch

" Show matching brackets when text indicator is over them
" set showmatch

set smartindent

set tabstop=3

" shift-width for one tab
set shiftwidth=3

" Use spaces instead of tabs
" set expandtab

" toggle paste mode; usful to copy exact text b/w vim files
set pastetoggle=<F2>

" ctrl+c to toggle highlight.
" let hlstate=0
" nnoremap <F3> :if (hlstate%2 == 0) \| set hlsearch \| else \| nohlsearch \| endif \| let hlstate=(hlstate+1)%2<cr>
"nnoremap <F3> :set hlsearch<cr>
"nnoremap <c><F3> :nohlsearch<cr>

" for Tag-list
filetype plugin on

" split window appear at right side
if 1
set splitright
endif

" insert empty line in cmd mode below current line
if 1
nmap <F8> o<Esc><Up>
endif

" insert empty line in cmd mode above current line
if 1
nmap <F9> O<Esc><Down>
endif

" short-cut key combo for exitting current vim window
" in insert or normal mode
if 1
" save changes and remain in same mode
imap <c-x><c-w> <Esc>:w<CR>i
nmap <c-x><c-w> <Esc>:w<CR>
" save changes and goto command mode - not working yet
"imap <c-s> <Esc>:w<CR>
" exit without save
imap <c-x><c-l> <Esc>:q!<CR>
nmap <c-x><c-l> <Esc>:q!<CR>
" exit with save
imap <c-x><c-z> <Esc>:wq<CR>
nmap <c-x><c-z> <Esc>:wq<CR>
" close all open windows in a vim session
imap <c-x><c-a> <Esc>:wqa!<CR>
nmap <c-x><c-a> <Esc>:wqa<CR>
endif

" window switching made easier
nmap <S-Down> <C-w><Down>
nmap <S-Up> <C-w><Up>
nmap <S-Left> <C-w><Left>
nmap <S-Right> <C-w><Right>

" vimgrep, auto-load copen, browse through code with pattern
nmap <A-Down> <C-w><Down><Down><CR>
nmap <A-Up> <C-w><Down><Up><CR>
nmap <C-x><C-Up> :vimgrep <cword> **/*.[ch] <CR><CR>:copen<CR><CR>
nmap <S-x><S-Up> :vimgrep <cword> % <CR><CR>:copen<CR><CR>
nmap <C-x><C-Down> :cclose<CR><CR>

" add space in normal mode
nnoremap <space> i<space><Esc>

" toggle diff mode inside vim session between different files multiple split windows
" using /+f
nnoremap <leader>f :call WdiffToggle()<cr>
let g:wdiffState=0
function! WdiffToggle()
    if g:wdiffState == 0
        windo diffthis
        let g:wdiffState=1
    else
        windo diffoff
        let g:wdiffState=0
    endif
endfunction

" toggle 80-column limiter in any vim window
nnoremap <leader>l :call LimiteToggle()<cr>
let g:limiteCol=0
function! LimiteToggle()
    if g:limiteCol == 0
        set colorcolumn=80
        let g:limiteCol=1
    else
        set colorcolumn=
        let g:limiteCol=0
    endif
endfunction

" toggle cursorline
nnoremap <leader>h :set cursorline!<CR>

" select qscope modes i.e. have cscope output in cwindow or as normal output
" inside vim
nnoremap <leader>q :call Qscope()<cr>
let g:qScopeNeeded=0
function! Qscope()
	if g:qScopeNeeded == 1
		set cscopequickfix=s-,c-,d-,i-,t-,e-
		copen
		let g:qScopeNeeded=0
	else
		set cscopequickfix=s0,c0,d0,i0,t0,e0
		cclose
		let g:qScopeNeeded=1
	endif
endfunction

" gblame - git-blame from within vim session on current file
" Opens a vim-split window which can later be closed normally
nnoremap <leader>g :call Gblame()<cr>
function! Gblame()
	let gbl_output = system("${c10s}/gitblame.sh " . expand('%'))
	if v:shell_error == 0
		vsp /tmp/gbl
	else
		echo gbl_output
	endif
endfunction

" comment selected lines in visual mode
" vmap <C-K> <S-i>//<Esc>

" Commenting blocks of code.
" autocmd FileType c,cpp,java,scala let b:comment_leader = '// '
" autocmd FileType sh,ruby,python   let b:comment_leader = '# '
" autocmd FileType conf,fstab       let b:comment_leader = '# '
" autocmd FileType tex              let b:comment_leader = '% '
" autocmd FileType mail             let b:comment_leader = '> '
" autocmd FileType vim              let b:comment_leader = '" '
" noremap <silent> <C-K> :<C-B>silent <C-E>s/^/<C-R>=escape(b:comment_leader,'\/')<CR>/<CR>:nohlsearch<CR>
" noremap <silent> <C-K><C-U> :<C-B>silent <C-E>s/^\V<C-R>=escape(b:comment_leader,'\/')<CR>//e<CR>:nohlsearch<CR>

" dictionary auto-complete enable
if 1
set dictionary+=/usr/share/dict/words
endif

" pathogen plugin
execute pathogen#infect()
syntax on
filetype indent on

set visualbell
set t_vb=
