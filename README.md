# carbonpaper.vim
Highlight LaTeX code in your favorite colorscheme of Vim!

carbonpaper.vim transfers code selected in Vim into LaTeX listings, preserving the colorscheme in Vim.
By using carbonpaper.vim, syntax highlighting becomes independent of LaTeX, so you can get beautifully highlighted code with your favorite vim colorscheme.

The example below shows the transformation of Elixir code, which is not supported by LaTeX.

![default_all](https://raw.github.com/wiki/s417-lama/carbonpaper.vim/images/carbonpaper_default_all.gif)

(The colorscheme of the above is [hybrid](https://github.com/w0ng/vim-hybrid))

Also, you can use different colorschemes or light theme that well matches LaTeX typesetting only when transferring code. See below.

## Getting Started

### Installation
Please follow the instructions of the plugin manager you use.
If your plugin manager is [dein.vim](https://github.com/Shougo/dein.vim), just add
```vim
call dein#add('s417-lama/carbonpaper.vim')
```

### Overview
1. Select code you want to transfer in visual mode.
2. Execute command `:CarbonPaper` and save an output file.
3. Include the generated file in LaTeX (using `\input` command).
4. Compile the LaTeX code!

You can select a part of the code by using visual block mode in Vim.
Also, a colorscheme and background can be configured as shown below.

![papercolor_part](https://raw.github.com/wiki/s417-lama/carbonpaper.vim/images/carbonpaper_papercolor_part.gif)

For reference, the configuration was:
```vim
let g:carbonpaper#colorscheme          = 'PaperColor'
let g:carbonpaper#background           = 'light'
let g:carbonpaper#set_background_color = 0
let g:carbonpaper#highlight_bold       = 1
```

### Insert code into LaTeX
If the name of the output file you saved is `hoge.tex`, insert the TeX code below where you want to insert the transferred code.
```latex
\input hoge.tex
```
(Assuming that `hoge.tex` is located at the same directory as the LaTeX code.)

The required packages are:
```latex
\usepackage{listings}
\usepackage{xcolor}
```

Font is also important. I recommend to use `inconsolata` font.

The LaTeX code used in the demo is [samples/demo/demo.tex](samples/demo/demo.tex). Please consult it if you need more information.

## Configuration
#### colorscheme
If you want to use another colorscheme only when transferring into LaTeX, you can specify it.
```vim
let g:carbonpaper#colorscheme = 'PaperColor'
```

#### background
`background` option in Vim (`light` or `dark`).
You can change it only when transferring.
```vim
let g:carbonpaper#background = 'light'
```

#### set_background_color, set_foreground_color
Whether or not to set the normal bg/fg color in listings.
If you want to use the default normal color specified in your `\lstset`, set
```vim
let g:carbonpaper#set_background_color = 0
let g:carbonpaper#set_foreground_color = 0
```
(default: 1)

#### highlight_bold
All colored text becomes bold (`\bfseries` in LaTeX) for visibility.
```vim
let g:carbonpaper#highlight_bold = 1
```
(default: 0)

## Documentation
You can see detailed information by entering
```
:h carbonpaper
```
in Vim.

The same document can be also seen in [samples/doc/doc.pdf](samples/doc/doc.pdf).
This document is generated from the help file by carbonpaper.vim and compiled by LaTeX.
The colorscheme is [PaperColor](https://github.com/NLKNguyen/papercolor-theme).

## License
MIT License. Copyright (c) 2018-2019 Shumpei Shiina
