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

" Compute the file type with the first letter capitalized.
let s:file_type = {s:plugin}FileType()

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

let s:comment_leader = "#"

" -----------------------------------------------------------------------------

function! {s:plugin}{s:file_type}FoldLevel(lnum)

    " Check the argument.
    if type(a:lnum) != type(0)
        throw "Argument must be an integer"
    endif

    " Define some regular expressions.
    let l:name_char_reg_exp = "[A-Za-z0-9_-]"
    let l:non_empty_reg_exp = '\S'
    let l:comment_reg_exp = '^\s*' . s:comment_leader
    let l:empty_or_comment_reg_exp = '^\s*\(' . s:comment_leader . '.*\)*$'
    let l:func_leader_reg_exp = '^\s*' . l:name_char_reg_exp . '\+\s*()'

    " Save the current cursor position.
    let l:cur_pos = getcurpos()

    " Initialize the return value.
    let l:ret = "="

    " Move the cursor to the start of the line with the number given as
    " argument.
    call cursor(a:lnum, 1)

    " Move to the next non empty line and get its number and text.
    let l:first_non_empty = search(l:non_empty_reg_exp, 'cW')
    let l:l_first_non_empty = getline(l:first_non_empty)

    if {s:main_script}#MatchesPrimSep(l:l_first_non_empty)
        " The non empty line is a primary separator and may be the start of a
        " function documentation block.

        let l:k = l:first_non_empty

        " Loop over the next empty or comment lines and count the comment
        " lines.
        let l:non_empty_doc_block = 0
        while search(l:empty_or_comment_reg_exp, 'W') == l:k + 1
            let l:k = l:k + 1
            if l:non_empty_doc_block == 0 && getline(l:k) =~# l:comment_reg_exp
                let l:non_empty_doc_block = 1
            endif
        endwhile

        if l:non_empty_doc_block && l:k < line('$')
            if getline(l:k + 1) =~# l:func_leader_reg_exp
                " The line with number l:k + 1 is a function leader line.

                " The line with the number given as argument is the beginning
                " of a function documentation block which we want to fold such
                " blocks.
                let l:ret = 1
            endif
        endif
    elseif getline(a:lnum) =~# l:func_leader_reg_exp
        " The line with the number given as argument is a function leader line
        " and we don't want to fold such lines.
        let l:ret = 0
    endif

    " Restore the cursor position.
    call cursor(l:cur_pos[1], l:cur_pos[2])

    return l:ret
endfunction

" -----------------------------------------------------------------------------

call {s:plugin}SetTextWidth(79, 2)
call {s:plugin}SetTabPreferences(4, "expandtab")

call {s:plugin}ConfigEndOfLineComment(s:comment_leader)

call {s:plugin}SetFoldingMethod("expr")

" Restore the value of cpoptions.
let &cpo = s:save_cpo

unlet s:save_cpo
