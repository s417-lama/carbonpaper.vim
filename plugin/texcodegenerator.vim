scriptencoding utf-8

if exists("g:loaded_texcodegenerator")
    finish
end
let g:loaded_texcodegenerator = 1

let s:save_cpo = &cpo
set cpo&vim

vmap z :<C-u>call texcodegenerator#helloworld()<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
