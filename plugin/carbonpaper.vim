scriptencoding utf-8

if exists("g:loaded_carbonpaper")
    finish
end
let g:loaded_carbonpaper = 1

let s:save_cpo = &cpo
set cpo&vim

command! -range -nargs=? CarbonPaper call carbonpaper#main(<f-args>)

let &cpo = s:save_cpo
unlet s:save_cpo
