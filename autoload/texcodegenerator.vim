scriptencoding utf-8

if !exists("g:loaded_texcodegenerator")
    finish
end

let s:save_cpo = &cpo
set cpo&vim

function! s:get_visual_selection()
    try
        let a_save = @a
        silent! normal! gv"ay
        return @a
    finally
        let @a = a_save
    endtry
endfunction

function! texcodegenerator#helloworld()
    echo s:get_visual_selection()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
