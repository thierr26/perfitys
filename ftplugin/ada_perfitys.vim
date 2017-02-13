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

" Runs a gprbuild command to check the syntax of the current file. User must
" make sure that there is a default GNAT project file in the current directory.
" It can be a default.gpr file or any .gpr file it is the only .gpr file in the
" current directory.
"
" The gprbuild command is "gprbuild -p -q -f -c -gnats -u " followed by the
" name of the current file.
"
" Return value:
" Exit status of the gprbuild command
function! {s:plugin}{s:file_type}CheckSyntax()

    let l:file_name = expand('%')
    if l:file_name == ""
        throw "No file name"
    endif

    let l:command = "gprbuild -p -q -f -c -gnats -u " . l:file_name
    let l:vim_ex_cmd = "!" . l:command
    execute l:vim_ex_cmd
    return v:shell_error

endfunction

" -----------------------------------------------------------------------------

" Runs a gprbuild command to check the semantic of the current file. User must
" make sure that there is a default GNAT project file in the current directory.
" It can be a default.gpr file or any .gpr file it is the only .gpr file in the
" current directory.
"
" The gprbuild command is "gprbuild -p -q -f -c -gnatc -u " followed by the
" name of the current file.
"
" Return value:
" Exit status of the gprbuild command
function! {s:plugin}{s:file_type}CheckSemantic()

    let l:file_name = expand('%')
    if l:file_name == ""
        throw "No file name"
    endif

    let l:command = "gprbuild -p -q -f -c -gnatc -u " . l:file_name
    let l:vim_ex_cmd = "!" . l:command
    execute l:vim_ex_cmd
    return v:shell_error

endfunction

" -----------------------------------------------------------------------------

" Runs a gprbuild command to build a program from the current file. User must
" make sure that there is a default GNAT project file in the current directory.
" It can be a default.gpr file or any .gpr file it is the only .gpr file in the
" current directory.
"
" The gprbuild command is "gprbuild -p " followed by the name of the current
" file.
"
" Return value:
" Exit status of the gprbuild command
function! {s:plugin}{s:file_type}Build()

    let l:file_name = expand('%')
    if l:file_name == ""
        throw "No file name"
    endif

    let l:command = "gprbuild -p " . l:file_name
    let l:vim_ex_cmd = "!" . l:command
    execute l:vim_ex_cmd
    return v:shell_error

endfunction

" -----------------------------------------------------------------------------

" Runs a make command.
"
" Relies on the existence of the b:perfitys_run_params dictionary.
"
" Arguments:
"
" #1 - reuse_args_without_confirm
" Non zero to run with the same arguments as in the previous call without
" requesting confirmation from the user, zero to request confirmation.
"
" Return value:
" Exit status of the script
function! {s:plugin}{s:file_type}RunWithArgs(reuse_args_without_confirm)

    let l:file_name = expand('%')
    if l:file_name == ""
        throw "No file name"
    endif

    if exists("g:" . s:plugin . s:file_type . "RunCommand")
        let l:command = g:{s:plugin}{s:file_type}RunCommand
    else
        let l:command = b:{s:main_script}_run_params["arguments"]
    endif
    if !a:reuse_args_without_confirm
        let l:command = input("", l:command, "file")
    endif
    let g:{s:plugin}{s:file_type}RunCommand = l:command

    echo "\n"
    if b:{s:main_script}_run_params["redirect_to_new_buffer"]
        let l:vim_ex_cmd = 'new | read !' . l:command
    else
        let l:vim_ex_cmd = "!" . l:command
    endif
    execute l:vim_ex_cmd
    return v:shell_error

endfunction

" -----------------------------------------------------------------------------

call {s:plugin}SetTextWidth(79, 2)
call {s:plugin}SetTabPreferences(3, "expandtab")

call {s:plugin}ConfigEndOfLineComment("--")

call {s:plugin}SetLocal("prim_sep", {
            \ 'indent_level': 1,
            \ 'post_comment_leader_space': "",
            \ 'repeating_sequence': "-",
            \ 'length': &textwidth,
            \ 'pre_comment_trailer_space': " ",
            \ 'empty_lines_above': 1,
            \ 'empty_lines_below': 1,
            \ })
call {s:plugin}SetLocal("second_sep", {
            \ 'indent_level': 2,
            \ 'post_comment_leader_space': "",
            \ 'repeating_sequence': "-",
            \ 'length': &textwidth - 20,
            \ 'pre_comment_trailer_space': " ",
            \ 'empty_lines_above': 1,
            \ 'empty_lines_below': 1,
            \ })

call {s:plugin}SetFoldingMethod("manual")

call {s:plugin}SetLocal("run_params", {
            \ 'arguments': "make ",
            \ 'redirect_to_new_buffer': 0,
            \ })

" Restore the value of cpoptions.
let &cpo = s:save_cpo

unlet s:save_cpo
