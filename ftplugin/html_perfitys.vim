" This file is part of the Perfitys Vim plugin.
"
" Maintainer: Thierry Rascle <thierr26@free.fr>
"
" License: Unlicense. Please refer to the LICENSE file.

" Compute the root of the base name of the current script (i.e. with the
" extension removed), in lower case.
let s:script = tolower(fnamemodify(expand('<sfile>:p'), ':t:r'))

" Check the resulting name.
if s:script !~# '^[a-z][a-z0-9]*_[a-z0-9]\+$'
    throw expand('<sfile>:p')
                \ . " is not a suitable file name for the filetype plugin"
endif

" Compute the name of the main script of the plugin (plugin/perfitys.vim).
let s:main_script = substitute(s:script, '^[^_]\+_', '', "")

" Compute the plugin name (with the first letter capitalized).
let s:plugin = substitute(s:main_script, "^.", '\=toupper(submatch(0))', "")

if !exists("g:" . s:main_script . "_enabled")
    " The general enable flag for the plugin has not been set by the
    " plugin/perfitys.vim script.

    " Stop sourcing the script.
    finish
endif

if exists("b:did_ftplugin")
    " Filetype plugin already loaded for the current buffer.

    " Stop sourcing the script.
    finish
endif
let s:nodid = "_do_not_set_did_ftplugin"
if !exists("g:" . s:main_script . "_" . &filetype . s:nodid)
            \ && !exists("g:" . s:main_script . s:nodid)
    let b:did_ftplugin = 1
endif

" Store the value of cpoptions (abbreviated has cpo).
let s:save_cpo = &cpo

" Set cpoptions to its Vim default.
set cpo&vim

" -----------------------------------------------------------------------------

" Sets the encoding option to UTF-8 if the file is a HTML5 file.
"
" Return value:
" 0
function! s:ForceUTF8EncForHTML5()

    " Save the current cursor position.
    let l:cur_pos = getcurpos()

    " Move to the beginning of the file.
    call cursor(1, 1)

    if {s:main_script}#NextNonEmptyLine() =~? '<!DOCTYPE html>'
        " The first non empty line is the HTML5 doctype declaration.

        let &encoding = "utf-8"
    endif

    " Restore the cursor position.
    call cursor(l:cur_pos[1], l:cur_pos[2])

endfunction

" -----------------------------------------------------------------------------

call {s:plugin}SetTextWidth(79, 2)
call {s:plugin}SetTabPreferences(2, "expandtab")

call {s:plugin}SetLocal("comment", {'leader': "<!--", 'trailer': "-->"})

call s:ForceUTF8EncForHTML5()

" Restore the value of cpoptions.
let &cpo = s:save_cpo

unlet s:save_cpo
