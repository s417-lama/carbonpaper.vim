scriptencoding utf-8

if !exists("g:loaded_carbonpaper")
    finish
end

let s:save_cpo = &cpo
set cpo&vim

let g:carbonpaper#save_as                = get(g:, "carbonpaper#save_as"               , "<filename>.tex")
let g:carbonpaper#filename_token         = get(g:, "carbonpaper#filename_token"        , "<filename>")
let g:carbonpaper#background             = get(g:, "carbonpaper#background"            , &background)
let g:carbonpaper#colorscheme            = get(g:, "carbonpaper#colorscheme"           , g:colors_name)
let g:carbonpaper#set_background_color   = get(g:, "carbonpaper#set_background_color"  , 1)
let g:carbonpaper#set_foreground_color   = get(g:, "carbonpaper#set_foreground_color"  , 1)
let g:carbonpaper#highlight_bold         = get(g:, "carbonpaper#highlight_bold"        , 0)
let g:carbonpaper#tex_escape_begin       = get(g:, "carbonpaper#tex_escape_begin"      , "(<cp--b>*#")
let g:carbonpaper#tex_escape_end         = get(g:, "carbonpaper#tex_escape_end"        , "#*<cp--e>)")
let g:carbonpaper#tex_listing_style_name = get(g:, "carbonpaper#tex_listing_style_name", "carbonpaper")

function! s:get_selected_lengths()
    try
        let a_save = @a
        normal! gv"ay
        let lines = split(@a, "\n")
        let lengths = map(lines, {_, line -> strlen(line)})
        return lengths
    finally
        let @a = a_save
    endtry
endfunction

function! s:parse_selected()
    let color_map                  = {}
    let text_list                  = []
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end  , column_end  ] = getpos("'>")[1:2]
    let lines                      = getline(line_start, line_end)
    let lines[-1]                  = lines[-1][:column_end - 1]
    let line_lengths               = s:get_selected_lengths()
    let row                        = line_start
    let col                        = column_start
    let col_offset                 = 0
    let last_id                    = 0
    let tmp_text                   = []
    let tmp_name                   = ""
    let is_block                   = 0

    if visualmode() == "\<c-v>"
        let is_block   = 1
        let col_offset = column_start
    endif

    let save_colorscheme = g:colors_name
    let save_background  = &background

    if exists('g:loaded_colorscheme_switcher')
        call xolox#colorscheme_switcher#find_links()
    endif
    call execute("colorscheme " . g:carbonpaper#colorscheme)
    if exists('g:loaded_colorscheme_switcher')
        call xolox#colorscheme_switcher#restore_links()
    endif

    call execute("set background=" . g:carbonpaper#background)

    if g:carbonpaper#set_background_color
        if synIDattr(hlID("NonText"), "bg#")
            let color_map["NonText"] = synIDattr(hlID("NonText"), "bg#")
        else
            let g:carbonpaper#set_background_color = 0
        endif
    endif
    if g:carbonpaper#set_foreground_color
        let color_map["Normal"] = synIDattr(hlID("Normal"), "fg#")
    endif

    for line in lines
        while col <= strlen(line) && (!is_block || col - col_offset < line_lengths[row - line_start])
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
        let col = col_offset
        let row += 1
    endfor
    call add(text_list, [tmp_name, tmp_text])

    if exists('g:loaded_colorscheme_switcher')
        call xolox#colorscheme_switcher#find_links()
    endif
    call execute("colorscheme " . save_colorscheme)
    if exists('g:loaded_colorscheme_switcher')
        call xolox#colorscheme_switcher#restore_links()
    endif

    call execute("set background=" . save_background)

    return [text_list, color_map]
endfunction

function! s:escape_char(char)
    let default_escapes = ["{", "}", "$", "#", "_", "&", "%"]
    if index(default_escapes, a:char) >= 0
        return "\\" . a:char
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
    let body = join(a:text, "")
    return g:carbonpaper#tex_escape_begin . a:color_name . "*" . body . g:carbonpaper#tex_escape_end
endfunction

function! s:gen_tex_code(text_list, color_map)
    let result = []
    for [name, text] in a:text_list
        if has_key(a:color_map, name)
            call add(result, s:gen_colored_text(text, name))
        else
            if g:carbonpaper#set_foreground_color
                call add(result, s:gen_colored_text(text, "Normal"))
            else
                call add(result, join(text, ""))
            end
        endif
    endfor
    return join(result, "")
endfunction

function! s:gen_color_definition(name, color)
    let color_code = a:color[1:]
    return "\\definecolor{cp-" . a:name . "}{HTML}{" . color_code . "}"
endfunction

function! s:gen_color_definitions(color_map)
    let def_list = []
    for [name, color] in items(a:color_map)
        call add(def_list, s:gen_color_definition(name, color))
    endfor
    return join(def_list, "\n")
endfunction

function! s:gen_moredelim(color_name, color, color_map)
    let begin = s:escape_text(g:carbonpaper#tex_escape_begin)
    let end   = s:escape_text(g:carbonpaper#tex_escape_end)
    let bold  = ""
    if g:carbonpaper#highlight_bold && a:color != a:color_map["Normal"]
        let bold = "\\bfseries"
    endif
    return "moredelim=[is][\\color{cp-" . a:color_name . "}" . bold . "]{" . begin . a:color_name . "*}{" . end . "}"
endfunction

function! s:gen_moredelims(color_map)
    let delim_list = []
    for [name, color] in items(a:color_map)
        call add(delim_list, s:gen_moredelim(name, color, a:color_map))
    endfor
    return join(delim_list, ",")
endfunction

function! s:gen_lstdefinestyle(color_map)
    let begin     = s:escape_text(g:carbonpaper#tex_escape_begin)
    let end       = s:escape_text(g:carbonpaper#tex_escape_end)
    let moredelim = s:gen_moredelims(a:color_map)
    let options   = "language="
    if g:carbonpaper#set_background_color
        let options = "backgroundcolor=\\color{cp-NonText}," . options
    endif
    return "\\lstdefinestyle{" . g:carbonpaper#tex_listing_style_name . "}{" . options . "," . moredelim . "}"
endfunction

function! s:gen_begin_listing()
    return "\\begin{lstlisting}[style=" . g:carbonpaper#tex_listing_style_name . "]"
endfunction

function! s:gen_end_listing()
    return "\\end{lstlisting}"
endfunction

function! s:save(text, filename)
    let filename = substitute(a:filename, g:carbonpaper#filename_token, expand('%:t'), "g")
    let filename = input("[carbonpaper.vim]  Save the TeX file as:\n", filename, "file")
    if filereadable(filename)
        let choice = confirm("'" . filename . "' already exists!  Would you overwrite?  Default: [N]o", "&Yes\n&No", 2)
        if choice == 0
            echo "Please enter Y or N"
        elseif choice == 2
            redraw
            echo "The TeX file not saved."
            return
        endif
    endif
    redraw
    call writefile(split(a:text, "\n"), filename)
    echo "Saved as '" . filename . "'"
endfunction

function! carbonpaper#main(...) range
    let [text_list, color_map] = s:parse_selected()
    let code_body              = s:gen_tex_code(text_list, color_map)
    let color_def              = s:gen_color_definitions(color_map)
    let lstdefinestyle         = s:gen_lstdefinestyle(color_map)

    let result = join([color_def, lstdefinestyle, s:gen_begin_listing(), code_body, s:gen_end_listing()], "\n")
    if a:0 == 0
        call s:save(result, g:carbonpaper#save_as)
    else
        call s:save(result, a:1)
    endif
endfunction

let &cpo = s:save_cpo
