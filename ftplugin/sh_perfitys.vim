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

" Store the value of cpoptions.
let s:save_cpo = &cpo

" Set cpoptions to its Vim default.
set cpo&vim

" -----------------------------------------------------------------------------

" Returns the here-document delimiter if the buffer line given as argument is a
" here-document leader, otherwise returns an empty string.
"
" Relies on the existence of the b:perfitys_reg_exp dictionary.
"
" Arguments:
"
" #1 - s
" Any string, is supposed to be a buffer line.
"
" Return value:
" Here-document delimiter or empty string.
function! s:HereDocDelimiter(s)

    let l:ret = substitute(a:s,
                \ b:{s:main_script}_reg_exp["here_doc_leader"], "", "")

    if l:ret !=# a:s
        let l:ret = matchstr(l:ret, b:{s:main_script}_reg_exp["name"])
    else
        let l:ret = ""
    endif

    return l:ret
endfunction

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

    " Get the here-doc delimiter if applicable.
    let l:here_delim = s:HereDocDelimiter(l:l)

    " Get the text of the previous line.
    let l:l1 = {s:main_script}#GetPreviousLine(a:lnum)

    " Move the cursor to the start of the line with the number given as
    " argument.
    call cursor(a:lnum, 1)

    " Move the cursor to a non empty line if current line is empty.
    let l:first_non_empty = {s:main_script}#NextNonEmptyLine()

    if {s:main_script}#MatchesPrimSep(l:first_non_empty)
                \ && {s:main_script}#NextNonEmptyNonEndOfLineCommentLine()
                \ && getline('.')
                    \ =~# b:{s:main_script}_reg_exp["function_leader"]
        " The line with the number given as argument is the beginning of (or an
        " empty line preceding the beginning of) a function documentation block
        " and we want to fold such blocks.
        let l:ret = 1
    elseif l:l =~# b:{s:main_script}_reg_exp["function_leader"]
        " The line with the number given as argument is a function leader line
        " and we don't want to fold such lines.
        let l:ret = 0
    elseif l:here_delim !=# ""
                \ && {s:main_script}#NextIsolateOccurence(l:here_delim) != 0
        " The line with the number given as argument is the beginning of a
        " here-document and we want to fold here-documents.
        let l:ret = 1
    elseif l:l1 =~# b:{s:main_script}_reg_exp["here_doc_trailer"]
                \ && search(b:{s:main_script}_reg_exp["here_doc_leader"],
                    \ 'bW') != 0
                \ && s:HereDocDelimiter(getline('.'))
                    \ ==# matchstr(l:l1, b:{s:main_script}_reg_exp["name"])
        " The line before the line with the number given as argument is a
        " here-document trailer delimiter and must be the last line of a fold.
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
    let l:sep_found = 0
    let l:here_doc_leader_found = 0
    let l:here_doc = ""
    while l:k < v:foldend && l:ret == ""

        let l:l = getline(l:k)

        if l:sep_found && l:l != ""
            " l:l is the first line of the documentation block of a function.

            let l:ret = l:l
        endif

        let l:sep_found = l:sep_found || {s:main_script}#MatchesPrimSep(l:l)

        let l:here_doc_leader_found = l:here_doc_leader_found
                    \ || l:l =~# b:{s:main_script}_reg_exp["here_doc_leader"]
        if l:here_doc_leader_found
            if l:here_doc == ""
                " l:l is the leader line of a here-document.

                let l:here_doc = l:l
            elseif l:l != ""
                " l:l is a non empty line in a here-document.

                let l:here_doc = l:here_doc
                            \ . " " . substitute(l:l, '^\s*', "", "")
            endif

            if strlen(l:here_doc) >= winwidth(0)
                " We have copied enough of the here-document in l:here_doc.

                let l:ret = l:here_doc
            endif
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

" Runs the file in the buffer (which is supposed to be a shell script).
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

    let l:command = l:file_name . b:{s:main_script}_run_params["arguments"]
    if !a:reuse_args_without_confirm
        let l:command = input("", l:command, "file")
    endif

    if l:command ==# l:file_name || l:command =~# '^' . l:file_name . ' '
        " The user input is the current file with zero or more arguments.

        " Get the arguments from the user input.
        let l:args = substitute(l:command, '^' . l:file_name, "", "")

        " Save the arguments for the next time.
        let b:{s:main_script}_run_params["arguments"] = l:args

        echo "\n"
        " Run the command input by the user, but with the file name expanded to
        " full path to avoid a "command not found" error.
        let b:{s:main_script}_run_params["run_count"] += 1
        let l:actually_run_command = expand('%:p') . l:args
        if b:{s:main_script}_run_params["redirect_to_new_buffer"]
            let l:vim_ex_cmd = 'new | read !' . l:actually_run_command
        else
            let l:vim_ex_cmd = "!" . l:actually_run_command
        endif
        execute l:vim_ex_cmd
        return v:shell_error
    else
        throw "Expected the command to be the file in the current buffer"
    endif

endfunction

" -----------------------------------------------------------------------------

call {s:plugin}SetTextWidth(79, 2)
call {s:plugin}SetTabPreferences(4, "expandtab")

call {s:plugin}ConfigEndOfLineComment("#")

" Define a dictionary of file type specific regular expressions.
let s:name_reg_exp = '[A-Za-z0-9_-]\+'
call {s:plugin}SetLocal("reg_exp", {
            \ 'name': s:name_reg_exp,
            \ 'function_leader': '^\s*' . s:name_reg_exp . '\s*()',
            \ 'here_doc_leader': '^\s*\S\+\s*<<-\?\s*',
            \ 'here_doc_trailer': '^\s*' . s:name_reg_exp . '$',
            \ })

call {s:plugin}SetFoldingMethod("manual")

call {s:plugin}SetLocal("run_params", {
            \ 'arguments': " ",
            \ 'redirect_to_new_buffer': 0,
            \ 'run_count': 0,
            \ })

" Restore the value of cpoptions.
let &cpo = s:save_cpo

unlet s:save_cpo
