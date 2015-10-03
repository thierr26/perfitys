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

call {s:plugin}SetTextWidth(78, 2)
call {s:plugin}SetTabPreferences(8, "expandtab")

call {s:plugin}SetLocal("prim_sep", {
            \ 'indent_level': 0,
            \ 'post_comment_leader_space': " ",
            \ 'repeating_sequence': "=",
            \ 'length': &textwidth,
            \ 'pre_comment_trailer_space': " ",
            \ 'empty_lines_above': 1,
            \ 'empty_lines_below': 0,
            \ })
call {s:plugin}SetLocal("second_sep", {
            \ 'indent_level': 0,
            \ 'post_comment_leader_space': " ",
            \ 'repeating_sequence': "-",
            \ 'length': &textwidth - 32,
            \ 'pre_comment_trailer_space': " ",
            \ 'empty_lines_above': 1,
            \ 'empty_lines_below': 0,
            \ })

call {s:plugin}SetFoldingMethod("manual")

" Restore the value of cpoptions.
let &cpo = s:save_cpo

unlet s:save_cpo
