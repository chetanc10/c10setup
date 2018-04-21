
noremap <silent> <C-l> :call Indentuno()<CR>
noremap <silent> <C-l><C-a> :call Indentorage()<CR>

function! Indentuno()
execute ":silent! :args % | argdo normal gg=G:wall\<CR>"
endfunction

function! Indentorage()
execute ":silent! :args **/*.[ch] | argdo normal gg=G:wall\<CR>"
endfunction

