scriptencoding utf-8

if !exists("g:loaded_tex_code_generator")
    finish
end

let s:save_cpo = &cpo
set cpo&vim

function! tex-code-generator#helloworld()
    echo "Hello world!"
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
