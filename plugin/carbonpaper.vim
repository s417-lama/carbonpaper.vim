scriptencoding utf-8

if exists("g:loaded_carbonpaper")
    finish
end
let g:loaded_carbonpaper = 1

let s:save_cpo = &cpo
set cpo&vim

vmap z :<C-u>call carbonpaper#helloworld()<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
