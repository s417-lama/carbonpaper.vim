scriptencoding utf-8

if !exists("g:loaded_texcodegenerator")
    finish
end

let s:save_cpo = &cpo
set cpo&vim

let g:texcodegenerator#tex_escape_start = "(<tcg.vim__start>*-"
let g:texcodegenerator#tex_escape_end   = "-*<tcg.vim__end>)"

function! s:parse_selected()
    let color_map                  = {}
    let text_list                  = []
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end  , column_end  ] = getpos("'>")[1:2]
    let lines                      = getline(line_start, line_end)
    let lines[-1]                  = lines[-1][:column_end - 1]
    let row                        = line_start
    let col                        = column_start
    let last_id                    = 0
    let tmp_text                   = []
    let tmp_name                   = ""

    for line in lines
        while col <= strlen(line)
            let char  = line[col - 1]
            let id    = synIDtrans(synID(row, col, 1))
            let color = synIDattr(id, "fg")
            let name  = synIDattr(id, "name")
            if id == last_id || tmp_text == []
                call add(tmp_text, char)
            else
                call add(text_list, [tmp_name, tmp_text])
                let tmp_text = [char]
            endif
            if color != ""
                let color_map[name] = color
            endif
            let col += 1
            let last_id = id
            let tmp_name = name
        endwhile
        call add(text_list, [tmp_name, tmp_text])
        call add(text_list, ["", ["\n"]])
        let tmp_text = []
        let col = 1
        let row += 1
    endfor
    call add(text_list, [tmp_name, tmp_text])

    return [text_list, color_map]
endfunction

function! s:escape_text(text)
    let default_escapes = ["{", "}", "$", "#", "_", "&", "%"]
    if index(default_escapes, a:text) >= 0
        return join(["\\", a:text], "")
    end
    if a:text == "\\"
        return "\\textbackslash{}"
    elseif a:text == "^"
        return "\\textasciicircum{}"
    elseif a:text == "~"
        return "\\textasciitilde{}"
    endif
    return a:text
endfunction

function! s:gen_colored_text(text, color_name)
    call map(a:text, {_, x -> s:escape_text(x)})
    let body = join(a:text, "")
    return join([g:texcodegenerator#tex_escape_start,
                \"\\textcolor{", a:color_name, "}{", body, "}",
                \g:texcodegenerator#tex_escape_end], "")
endfunction

function! s:gen_tex_code(text_list, color_map)
    let result = []
    for [name, text] in a:text_list
        if has_key(a:color_map, name)
            call add(result, s:gen_colored_text(text, name))
        else
            call add(result, join(text, ""))
        endif
    endfor
    return join(result, "")
endfunction

function! s:gen_color_definition(name, color)
    let color_code = a:color[1:]
    return join(["\\definecolor{", a:name, "}{HTML}{", color_code, "}"], "")
endfunction

function! s:gen_color_definitions(color_map)
    let def_list = []
    for [name, color] in items(a:color_map)
        call add(def_list, s:gen_color_definition(name, color))
    endfor
    return join(def_list, "\n")
endfunction

function! s:gen_begin_listing()
    return join(["\\begin{lstlisting}[basicstyle=\\ttfamily,escapeinside={",
                \g:texcodegenerator#tex_escape_start, "}{", g:texcodegenerator#tex_escape_end, "}]"], "")
endfunction

function! s:gen_end_listing()
    return "\\end{lstlisting}"
endfunction

function! texcodegenerator#helloworld() range
    let [text_list, color_map] = s:parse_selected()
    let code_body = s:gen_tex_code(text_list, color_map)
    let color_def = s:gen_color_definitions(color_map)
    let result = join([color_def, s:gen_begin_listing(), code_body, s:gen_end_listing()], "\n")
    call writefile(split(result, "\n"), "log")
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
