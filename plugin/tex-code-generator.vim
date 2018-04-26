scriptencoding utf-8

if exists("g:loaded_tex_code_generator")
    finish
end
let g:loaded_tex_code_generator = 1

let s:save_cpo = &cpo
set cpo&vim

nmap z :call tex-code-generator#helloworld()<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
