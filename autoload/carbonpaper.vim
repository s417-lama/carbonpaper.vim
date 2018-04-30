scriptencoding utf-8

if !exists("g:loaded_carbonpaper")
    finish
end

let s:save_cpo = &cpo
set cpo&vim

let g:carbonpaper#tex_escape_begin     = get(g:, "carbonpaper#tex_escape_begin"    , "(<carbonpaper.vim--begin>*#")
let g:carbonpaper#tex_escape_end       = get(g:, "carbonpaper#tex_escape_end"      , "#*<carbonpaper.vim--end>)")
let g:carbonpaper#save_as              = get(g:, "carbonpaper#save_as"             , "<filename>.tex")
let g:carbonpaper#filename_token       = get(g:, "carbonpaper#filename_token"      , "<filename>")
let g:carbonpaper#overwrite            = get(g:, "carbonpaper#overwrite"           , 0)
let g:carbonpaper#background           = get(g:, "carbonpaper#background"          , &background)
let g:carbonpaper#colorscheme          = get(g:, "carbonpaper#colorscheme"         , g:colors_name)
let g:carbonpaper#tex_listing_options  = get(g:, "carbonpaper#tex_listing_options" , 'basicstyle=\ttfamily')
let g:carbonpaper#set_background_color = get(g:, "carbonpaper#set_background_color", 1)
let g:carbonpaper#set_foreground_color = get(g:, "carbonpaper#set_foreground_color", 1)

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

    let save_colorscheme = g:colors_name
    let save_background  = &background
    call execute(join(["colorscheme ", g:carbonpaper#colorscheme], ""))
    call execute(join(["set background=", g:carbonpaper#background], ""))

    let color_map["NonText"] = synIDattr(hlID("NonText"), "bg#")
    let color_map["Normal"]  = synIDattr(hlID("Normal"),  "fg#")

    for line in lines
        while col <= strlen(line)
            let char  = line[col - 1]
            let id    = synIDtrans(synID(row, col, 1))
            let color = synIDattr(id, "fg#")
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
        if row < line_end
            call add(text_list, ["", ["\n"]])
        endif
        let tmp_text = []
        let col = 1
        let row += 1
    endfor
    call add(text_list, [tmp_name, tmp_text])

    call execute(join(["colorscheme ", save_colorscheme], ""))
    call execute(join(["set background=", save_background], ""))

    return [text_list, color_map]
endfunction

function! s:escape_char(char)
    let default_escapes = ["{", "}", "$", "#", "_", "&", "%"]
    if index(default_escapes, a:char) >= 0
        return join(["\\", a:char], "")
    end
    if a:char == "\\"
        return "\\textbackslash{}"
    elseif a:char == "^"
        return "\\textasciicircum{}"
    elseif a:char == "~"
        return "\\textasciitilde{}"
    endif
    return a:char
endfunction

function! s:escape_text(text)
    let charlist = split(a:text, '\zs')
    call map(charlist, {_, c -> s:escape_char(c)})
    return join(charlist, "")
endfunction

function! s:gen_colored_text(text, color_name)
    call map(a:text, {_, c -> s:escape_char(c)})
    let body = join(a:text, "")
    return join([g:carbonpaper#tex_escape_begin,
                \"\\textcolor{", a:color_name, "}{", body, "}",
                \g:carbonpaper#tex_escape_end], "")
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
    let begin   = s:escape_text(g:carbonpaper#tex_escape_begin)
    let end     = s:escape_text(g:carbonpaper#tex_escape_end)
    let options = g:carbonpaper#tex_listing_options
    if g:carbonpaper#set_foreground_color
        let basic_option = 'basicstyle=\\color{Normal}'
        let options      = substitute(g:carbonpaper#tex_listing_options, "basicstyle=", basic_option, "g")
        if match(options, "basicstyle=") == -1
            let options = join([options, basic_option], ",")
        endif
    endif
    if g:carbonpaper#set_background_color
        let options = join(["backgroundcolor=\\color{NonText}", options], ",")
    endif
    return join(["\\begin{lstlisting}[language=,",
                \options,
                \",escapeinside={", begin, "}{", end, "}]"], "")
endfunction

function! s:gen_end_listing()
    return "\\end{lstlisting}"
endfunction

function! s:save(text, filename)
    let filename = substitute(a:filename, g:carbonpaper#filename_token, expand('%:t'), "g")
    if !g:carbonpaper#overwrite
        while filereadable(filename)
            let num = str2nr(split(filename, '\.')[-1])
            if num == 0
                let filename = join([filename, 1], ".")
            else
                let filename = join(split(filename, '\.')[:-2] + [num + 1], ".")
            endif
        endwhile
    endif
    call writefile(split(a:text, "\n"), filename)
    echo join(["Saved as '", filename, "'"], "")
endfunction

function! carbonpaper#main(...) range
    let [text_list, color_map] = s:parse_selected()
    let code_body = s:gen_tex_code(text_list, color_map)
    let color_def = s:gen_color_definitions(color_map)
    let result = join([color_def, s:gen_begin_listing(), code_body, s:gen_end_listing()], "\n")
    if a:0 == 0
        call s:save(result, g:carbonpaper#save_as)
    else
        call s:save(result, a:1)
    endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
