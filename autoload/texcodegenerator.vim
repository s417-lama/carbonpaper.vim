scriptencoding utf-8

if !exists("g:loaded_texcodegenerator")
    finish
end

let s:save_cpo = &cpo
set cpo&vim

function! texcodegenerator#helloworld()
    echo "Hello world!"
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
