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

" -----------------------------------------------------------------------------

" Default Perfitys fold level function for the file type. Used if the fold
" method for the file type is set to "expr" and if the user has not defined its
" own fold expression. For more information, see:
" - :help foldmethod
" - :help fold-expr
" - :help perfitys-foldmethod
"
" Relies on the existence of the b:perfitys_reg_exp dictionary.
"
" Arguments:
"
" #1 - lnum
" Any integer, supposed to be a buffer line number.
"
" Return value:
" Fold level.
function! {s:plugin}{s:file_type}FoldLevel(lnum)

    " Save the current cursor position.
    let l:cur_pos = getpos('.')

    " Initialize the return value.
    let l:ret = "="

    " Get the text of the line with the number given as argument.
    let l:l = getline(a:lnum)

    " Get the text of the previous line.
    let l:l1 = {s:main_script}#GetPreviousLine(a:lnum)

    " Move the cursor to the start of the line with the number given as
    " argument.
    call cursor(a:lnum, 1)

    if (!{s:main_script}#IsEndOfLineComment(l:l1)
                \ || {s:main_script}#MatchesPrimSep(l:l1))
                \ && {s:main_script}#NextNonEmptyNonEndOfLineCommentLine() >= 0
                \ && getline('.')
                    \ =~# b:{s:main_script}_reg_exp["function_leader"]
        " The line with the number given as argument is the beginning of (or an
        " empty line preceding the beginning of) a function documentation block
        " and we want to fold such blocks.
        let l:ret = 1
    elseif l:l != "" && !{s:main_script}#IsEndOfLineComment(l:l)
                \ && l:l !~# b:{s:main_script}_reg_exp["function_leader"]
        let l:ret = 0
    endif

    " Restore the cursor position.
    call setpos('.', l:cur_pos)

    return l:ret
endfunction

" -----------------------------------------------------------------------------

" Perfitys fold text function for the file type, automatically activated if the
" Perfitys default fold level function for the file type is selected.
" For more information on fold text, see:
" - :help fold-foldtext
"
" Relies on the existence of the b:perfitys_reg_exp dictionary.
"
" Return value:
" Fold text.
function! {s:plugin}{s:file_type}FoldText()

    let l:ret = ""
    let l:k = v:foldstart
    while l:k <= v:foldend && l:ret == ""

        let l:l = getline(l:k)

        if l:l =~# b:{s:main_script}_reg_exp["function_leader"]
            " l:l is the function leader line.

            let l:ret = l:l . repeat(" ", winwidth(0) - strlen(l:l))
        endif

        let l:k += 1
    endwhile

    if l:ret == ""
        let l:ret = foldtext()
    else
        let l:ret = v:folddashes . l:ret
    endif

    return l:ret
endfunction

" -----------------------------------------------------------------------------

call {s:plugin}SetTextWidth(79, 2)
call {s:plugin}SetTabPreferences(4, "expandtab")

let s:comment_leader = "#"
let s:second_sep_repeating_sequence = "- "

call {s:plugin}ConfigEndOfLineComment(s:comment_leader)

call {s:plugin}SetLocal("prim_sep", {
            \ 'indent_level': 0,
            \ 'post_comment_leader_space': " ",
            \ 'repeating_sequence': "-",
            \ 'length': &textwidth,
            \ 'pre_comment_trailer_space': " ",
            \ 'empty_lines_above': 1,
            \ 'empty_lines_below': 1,
            \ })

call {s:plugin}SetLocal("second_sep", {
            \ 'indent_level': 1,
            \ 'post_comment_leader_space': " ",
            \ 'repeating_sequence': s:second_sep_repeating_sequence,
            \ 'length': &textwidth - 8,
            \ 'pre_comment_trailer_space': " ",
            \ 'empty_lines_above': 1,
            \ 'empty_lines_below': 1,
            \ })

let s:function_leader_reg_exp = '^\s*function\s'

" Define a dictionary of file type specific regular expressions.
call {s:plugin}SetLocal("reg_exp", {
            \ 'function_leader': s:function_leader_reg_exp,
            \ })

call {s:plugin}SetFoldingMethod("manual")

call {s:plugin}SetLocal("vimgrepinqf_params", {
            \ 'reg_exp': s:function_leader_reg_exp,
            \ 'file': '**/*.m',
            \ 'min_cwd_depth': 2,
            \ 'relative_to_home': 1,
            \ })

" Restore the value of cpoptions.
let &cpo = s:save_cpo

unlet s:save_cpo
