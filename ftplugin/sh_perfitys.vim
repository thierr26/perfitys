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
    let l:non_empty_reg_exp = '\S'
    let l:comment_reg_exp = '^\s*' . s:comment_leader
    let l:func_leader_reg_exp = '^\s*[A-Za-z0-9_-]\+\s*()'
    let l:doc_line_reg_exp = l:comment_reg_exp . '.*[A-Za-z0-9_]\+'

    " Get the number of the last line in the buffer.
    let l:last = line('$')

    " Initialize l:k and l:l_k with the number of the current line and the
    " current line respectively.
    let l:k = a:lnum
    let l:l_k = getline(l:k)

    " Initialize the function output.
    let l:ret = (l:l_k =~# l:comment_reg_exp || l:l_k !~# l:non_empty_reg_exp)
                \ ? "=" : 0

    " Move l:k to the number of the next non empty line (or do nothing if the
    " current line is not empty).
    while l:k < l:last && l:l_k !~# l:non_empty_reg_exp
        let l:k += 1
        let l:l_k = getline(l:k)
    endwhile

    if {s:main_script}#MatchesPrimSep(l:l_k)
        " The current line (number a:lnum) is an empty line preceding a primary
        " separator or is a primary separator and could be the beginning of a
        " function documentation block.

        " Initialize the documentation line counter
        let l:doc_k = 0

        " Move l:k to the number of the next non empty and non comment line.
        while l:k < l:last && (l:l_k !~# l:non_empty_reg_exp
                    \ || l:l_k =~# l:comment_reg_exp)
            let l:k += 1
            let l:l_k = getline(l:k)

            " Increment the documentation line counter if the line looks like a
            " documentation line.
            if l:l_k =~# l:doc_line_reg_exp
                let l:doc_k += 1
            endif
        endwhile

        if l:doc_k > 0 && l:l_k =~# l:func_leader_reg_exp
            let l:ret = 1
        endif
    endif

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
