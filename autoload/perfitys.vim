" This file is part of the Perfitys Vim plugin.
"
" Maintainer: Thierry Rascle <thierr26@free.fr>
"
" License: Unlicense. Please refer to the LICENSE file.

" Store the value of cpoptions (abbreviated has cpo).
let s:save_cpo = &cpo

" Set cpoptions to its Vim default.
set cpo&vim

" Compute the root of the base name of the current script (i.e. with the
" extension removed), in lower case.
let s:script = tolower(fnamemodify(expand('<sfile>:p'), ':t:r'))

" Compute the common prefix for all the plugin related variables, including a
" trailing underscore.
let s:prefix = s:script . "_"

" Compute the plugin name (with the first letter capitalized).
let s:plugin = substitute(s:script, "^.", '\=toupper(submatch(0))', "")

let s:prim_sep_default_dic = {
            \ 'indent_level': 0,
            \ 'post_comment_leader_space': " ",
            \ 'repeating_sequence': "-",
            \ 'length': &textwidth,
            \ 'pre_comment_trailer_space': " ",
            \ 'empty_lines_above': 1,
            \ 'empty_lines_below': 1,
            \ }

let s:second_sep_default_dic = {
            \ 'indent_level': 0,
            \ 'post_comment_leader_space': " ",
            \ 'repeating_sequence': "-",
            \ 'length': &textwidth - 20,
            \ 'pre_comment_trailer_space': " ",
            \ 'empty_lines_above': 1,
            \ 'empty_lines_below': 1,
            \ }

let s:left_shift_reg_exp_default = "^ \\+"

" -----------------------------------------------------------------------------

" Issues a warning message.
"
" Arguments:
"
" #1 - msg
" Any string.
"
" Return value:
" 0
function s:Warning(msg)
    echohl WarningMsg
    echo a:msg
    echohl None
endfunction

" -----------------------------------------------------------------------------

" Checks that the argument is a dictionary.
"
" Arguments:
"
" #1 - d
" Anything.
"
" Return value:
" Nonzero if d is a dictionary, zero otherwise.
function s:IsDict(d)
    return type(a:d) == type({})
endfunction

" -----------------------------------------------------------------------------

" Checks that the dictionary given as first argument has at least the keys
" given in the second argument (as a list of strings).
"
" Arguments:
"
" #1 - d
" A dictionary.
"
" #2 - expected_keys
" A list of strings.
"
" Return value:
" Nonzero if the dictionary has at least the keys given in the list, zero
" otherwise.
function s:KeyMatch(d, expected_keys)
    let l:match_count = 0
    for key in keys(a:d)
        if index(a:expected_keys, key) != -1
            let l:match_count += 1
        endif
    endfor
    return l:match_count == len(a:expected_keys)
endfunction

" -----------------------------------------------------------------------------

" Checks that the argument is a dictionary containing a valid comment leader
" and a valid comment trailer. See in file ftplugin/c_perfitys.vim the
" statement:
" call {s:plugin}SetLocal("comment", ...
" for an example of such a dictionary.
"
" Arguments:
"
" #1 - d
" Anything.
"
" Return value:
" Nonzero if d is a dictionary containing a valid comment leader and a valid
" comment trailer, zero otherwise.
function s:IsCommentDict(d)
    let l:ret = s:IsDict(a:d)
    if l:ret
        let l:expected_keys = [
                    \ 'leader',
                    \ 'trailer',
                    \ ]
        let l:ret = s:KeyMatch(a:d, l:expected_keys)
    endif
    if l:ret
        let l:ret = type(a:d['leader']) == type("")
        let l:ret = l:ret && type(a:d['trailer']) == type("")
    endif
    return l:ret
endfunction

" -----------------------------------------------------------------------------

" Checks that the argument is a dictionary containing valid parameters for a
" separator line. See in file ftplugin/text_perfitys.vim the statement:
" call {s:plugin}SetLocal("second_sep", ...
" for an example of such a dictionary.
"
" Arguments:
"
" #1 - d
" Anything.
"
" Return value:
" Nonzero if d is a dictionary containing valid parameters for a separator
" line, zero otherwise.
function s:IsSepDict(d)
    let l:ret = s:IsDict(a:d)
    if l:ret
        let l:expected_keys = [
                    \ 'indent_level',
                    \ 'post_comment_leader_space',
                    \ 'repeating_sequence',
                    \ 'length',
                    \ 'pre_comment_trailer_space',
                    \ 'empty_lines_above',
                    \ 'empty_lines_below',
                    \ ]
        let l:ret = s:KeyMatch(a:d, l:expected_keys)
    endif
    if l:ret
        let l:ret = type(a:d['indent_level']) == type(0)
                    \ && a:d['indent_level'] >= 0
        let l:ret = l:ret && type(a:d['post_comment_leader_space']) == type("")
        let l:ret = l:ret && type(a:d['repeating_sequence']) == type("")
                    \ && strlen(a:d['repeating_sequence']) > 0
        let l:ret = l:ret && type(a:d['length']) == type(0)
                    \ && a:d['length'] >= 0
        let l:ret = l:ret && type(a:d['pre_comment_trailer_space']) == type("")
        let l:ret = l:ret && type(a:d['empty_lines_above']) == type(0)
                    \ && a:d['empty_lines_above'] >= 0
        let l:ret = l:ret && type(a:d['empty_lines_below']) == type(0)
                    \ && a:d['empty_lines_below'] >= 0
    endif
    return l:ret
endfunction

" -----------------------------------------------------------------------------

" Checks that the argument is a dictionary containing valid parameters for the
" "vimgrep in quickfix" function. See in file ftplugin/vim_perfitys.vim the
" statement: call {s:plugin}SetLocal("vimgrepinqf_params", ...
" for an example of such a dictionary.
"
" Arguments:
"
" #1 - d
" Anything.
"
" Return value:
" Nonzero if d is a dictionary containing valid parameters for the "vimgrep in
" quickfix" function, zero otherwise.
function s:IsVimgrepInQFDict(d)
    let l:ret = s:IsDict(a:d)
    if l:ret
        let l:expected_keys = [
                    \ 'reg_exp',
                    \ 'file',
                    \ 'min_cwd_depth',
                    \ 'relative_to_home',
                    \ ]
        let l:ret = s:KeyMatch(a:d, l:expected_keys)
    endif
    if l:ret
        let l:ret = type(a:d['reg_exp']) == type("")
        let l:ret = l:ret && type(a:d['file']) == type("")
        let l:ret = l:ret && type(a:d['min_cwd_depth']) == type(0)
        let l:ret = l:ret && type(a:d['relative_to_home']) == type(0)
    endif
    return l:ret
endfunction

" -----------------------------------------------------------------------------

" Adds a separator line below the current line.
"
" The function also performs a cleaning job. Supernumerary blank lines and
" separator lines are deleted.
"
" The argument is not checked."
"
" Arguments:
"
" #1 - sep
" Separator line parameters as a dictionary. See in file
" ftplugin/text_perfitys.vim the statement
" call {s:plugin}SetLocal("second_sep", ...
" for an example of separator line parameters.
"
" Return value:
" 0
function s:PutSep(sep)

    let l:reg_exp = s:SepRegExp(a:sep)
    let l:sep_line = s:Sep(a:sep)

    call s:PutLineAndCollapse(l:sep_line, l:reg_exp)
    call s:PutBelow("", a:sep['empty_lines_below'])
    call s:PutAbove("", a:sep['empty_lines_above'])

endfunction

" -----------------------------------------------------------------------------

" Adds a primary separator line below the current line.
"
" The function also performs a cleaning job. Supernumerary blank lines and
" separator lines are deleted.
"
" Return value:
" 0
function {s:script}#PrimSep()

    let l:ident = "prim_sep"
    let l:local_sep = {s:plugin}GetLocal(l:ident, s:prim_sep_default_dic,
                \ function("s:IsSepDict"))

    call s:PutSep({s:plugin}Get(l:ident, &filetype, l:local_sep,
                \ function("s:IsSepDict")))
endfunction

" -----------------------------------------------------------------------------

" Adds a secondary separator line below the current line.
"
" The function also performs a cleaning job. Supernumerary blank lines and
" separator lines are deleted.
"
" Return value:
" 0
function {s:script}#SecondSep()

    let l:ident = "second_sep"
    let l:local_sep = {s:plugin}GetLocal(l:ident, s:second_sep_default_dic,
                \ function("s:IsSepDict"))

    call s:PutSep({s:plugin}Get(l:ident, &filetype, l:local_sep,
                \ function("s:IsSepDict")))
endfunction

" -----------------------------------------------------------------------------

" Checks that the string given as argument looks like a primary separator line.
"
" Arguments
"
" #1 - s
" Any string.
"
" Return value:
" Nonzero if the string given as argument looks like a primary separator line.
function {s:script}#MatchesPrimSep(s)
    return a:s =~# s:SepRegExp(
                \ {s:plugin}GetLocal("prim_sep", s:prim_sep_default_dic,
                \ function("s:IsSepDict")))
endfunction

" -----------------------------------------------------------------------------

" Checks that the string given as argument looks like a secondary separator
" line.
"
" Arguments
"
" #1 - s
" Any string.
"
" Return value:
" Nonzero if the string given as argument looks like a secondary separator
" line.
function {s:script}#MatchesSecondSep(s)
    return a:s =~# s:SepRegExp(
                \ {s:plugin}GetLocal("second_sep", s:second_sep_default_dic,
                \ function("s:IsSepDict")))
endfunction

" -----------------------------------------------------------------------------

" Returns a separator line. Any trailing white space is removed.
"
" Arguments:
"
" #1 - sep
" Separator line parameters as a dictionary. See in file
" ftplugin/text_perfitys.vim the statement
" call {s:plugin}SetLocal("second_sep", ...
" for an example of separator line parameters.
"
" Return value:
" Separator line.
function s:Sep(sep)

    let l:comment = {s:plugin}GetLocal("comment", {'leader': "", 'trailer': ""},
                \ function("s:IsCommentDict"))

    if &expandtab
        let l:indent = repeat(" ", a:sep['indent_level'] * &shiftwidth)
    else
        let l:indent = repeat("\t", a:sep['indent_level'])
    endif

    let l:s1 = l:indent . (strlen(l:comment['leader']) > 0
                \ ? l:comment['leader'] . a:sep['post_comment_leader_space']
                \ : "")
    let l:s1_len = strlen(l:s1)

    let l:s3 = strlen(l:comment['trailer']) > 0
                \ ? a:sep['pre_comment_trailer_space'] . l:comment['trailer']
                \ : ""
    let l:s3_len = strlen(l:s3)

    let l:s2_len = a:sep['length'] - l:s1_len - l:s3_len
    let l:s2 = ""
    while strlen(l:s2) < l:s2_len
        let l:s2 .= a:sep['repeating_sequence']
    endwhile
    let l:e = '^\(.\{' . max([0, l:s2_len]) . '\}\).\+$'
    let l:s2 = substitute(l:s2, l:e, '\=submatch(1)', "")
    let l:s2 = substitute(l:s2, '\s*$', "", "")

    return l:s1 . l:s2 . l:s3
endfunction

" -----------------------------------------------------------------------------

" Returns a regular expression that separator lines match.
"
" Arguments:
"
" #1 - sep
" Separator line parameters as a dictionary. See in file
" ftplugin/text_perfitys.vim the statement
" call {s:plugin}SetLocal("second_sep", ...
" for an example of separator line parameters.
"
" Return value:
" Regular expression that separator lines match.
function s:SepRegExp(sep)

    let l:comment = {s:plugin}GetLocal("comment", {'leader': "", 'trailer': ""},
                \ function("s:IsCommentDict"))

    let l:non_escaped_repeating_sep = a:sep['repeating_sequence']
    let l:escape_list = '/*'
    let l:comment_leader = escape(l:comment['leader'], l:escape_list)
    let l:comment_trailer = escape(l:comment['trailer'], l:escape_list)
    let l:repeating_sep = escape(l:non_escaped_repeating_sep, l:escape_list)

    let l:s1 = "\\m^\\s*" . l:comment_leader . "\\s*\\(" . l:repeating_sep
                \ . "\\)\\+"
    let l:s2 = ""

    let l:repeating_sep_len = strlen(l:non_escaped_repeating_sep)
    if l:repeating_sep_len >= 2
        let l:s2 = "\\("

        for k in range(l:repeating_sep_len)

            for kk in range(k + 1)
                let l:s2 .= escape(l:non_escaped_repeating_sep[kk],
                            \ l:escape_list)
            endfor

            if k < l:repeating_sep_len - 1
                let l:s2 .= "\\|"
            endif

        endfor

        let l:s2 .= "\\)"
    endif

    let l:s3 = "\\s*" . l:comment_trailer . "$"

    return l:s1 . l:s2 . l:s3

endfunction

" -----------------------------------------------------------------------------

" Adds a line below the current line and deletes the lines immediately above
" and below the added line if they fulfill the following conditions:
" - They are empty or have only blank characters;
" - They match the regular expression given has second argument.
"
" Arguments:
"
" #1 - s
" Text of the line.
"
" #2 - reg_exp
" Regular expression.
"
" Return value:
" 0
function s:PutLineAndCollapse(s, reg_exp)

    put=a:s
    let l:line_num = line('.')

    if l:line_num < line('$')
        normal! j
        let l:cur_line = getline('.')
        while line('.') == l:line_num + 1 && (l:cur_line =~# a:reg_exp
                    \ || l:cur_line =~# '\m^\s*$')
            normal! "_dd
            let l:cur_line = getline('.')
        endwhile
        normal! k
    endif

    if l:line_num > 1
        normal! k
        let l:cur_line = getline('.')
        while line('.') == l:line_num - 1  && l:line_num > 1
                    \ && (l:cur_line =~# a:reg_exp || l:cur_line =~# '\m^\s*$')
            normal! "_dd
            let l:line_num -= 1
            normal! k
            let l:cur_line = getline('.')
        endwhile
        normal! j
    endif

endfunction

" -----------------------------------------------------------------------------

" Adds a line (or multiple copies of line) below the current line. After the
" execution, the cursor is on the same line as before the execution.
"
" Arguments:
"
" #1 - s
" Text of the line.
"
" #2 (optional)
" Number of copies of the line. Defaults to 1.
"
" Return value:
" 0
function s:PutBelow(s, ...)

    for k in range(a:0 == 1 ? a:1 : 1)
        put=a:s
        normal! k
    endfor

endfunction

" -----------------------------------------------------------------------------

" Adds a line (or multiple copies of line) above the current line. After the
" execution, the cursor is on the same line as before the execution.
"
" Arguments:
"
" #1 - s
" Text of the line.
"
" #2 (optional)
" Number of copies of the line. Defaults to 1.
"
" Return value:
" 0
function s:PutAbove(s, ...)

    for k in range(a:0 == 1 ? a:1 : 1)
        put!=a:s
        normal! j
    endfor

endfunction

" -----------------------------------------------------------------------------

" Returns the first key found in the non empty dictionary given as argument.
"
" Arguments:
"
" #1 - d
" Non empty dictionary.
"
" Return value:
" First key found in the dictionary given as argument.
function s:FirstDictKey(d)

    for [key, value] in items(a:d)
        let l:ret = key
        break
    endfor

    return l:ret
endfunction

" -----------------------------------------------------------------------------

" Returns the first value found in the non empty dictionary given as argument.
"
" Arguments:
"
" #1 - d
" Non empty dictionary, with values of type string.
"
" Return value:
" First value found in the dictionary given as argument.
function s:FirstDictVal(d)

    for [key, value] in items(a:d)
        if type(value) != type("")
            throw "Values must be of type string"
        endif
        let l:ret = value
        break
    endfor

    return l:ret
endfunction

" -----------------------------------------------------------------------------

" If the dictionnary given as first argument has a key matching the file type
" given as second argument, then the function returns the associated value if
" it is not empty.
"
" If the dictionnary given as first argument has no key matching the file type
" given as second argument, then the function looks for a value matching the
" file type and returns the associated key if such a value is found.
"
" Otherwise, returns an empty string.
"
" Arguments:
"
" #1 - d
" Dictionary.
"
" #2 - filetype
" Non empty string.
"
" Return value:
" String, might be empty.
function s:FindAltFileType(d, filetype)

    let l:d_shallow_copy_1 = copy(a:d)
    call filter(l:d_shallow_copy_1, 'v:key ==# a:filetype')
    if !empty(l:d_shallow_copy_1)
        let l:ret = s:FirstDictVal(l:d_shallow_copy_1)
    else
        let l:d_shallow_copy_2 = copy(a:d)
        call filter(l:d_shallow_copy_2, 'v:val ==# a:filetype')
        if !empty(l:d_shallow_copy_2)
            let l:ret = s:FirstDictKey(l:d_shallow_copy_2)
        else
            let l:ret = ""
        endif
    endif

    return l:ret
endfunction

" -----------------------------------------------------------------------------

" Returns the return value of function FindAltFileType unless:
" - its return value is empty (in this case returns the second argument as is),
" - another call of FindAltFileType with the second argument substituted with
"   the return value of the first call does not return the second argument (in
"   this case throws an exception).
"
" Arguments:
"
" #1 - d
" Dictionary.
"
" #2 - filetype
" Non empty string.
"
" Return value:
" Non empty string.
function s:CheckedAltFileType(d, filetype)

    let l:ret = s:FindAltFileType(a:d, a:filetype)
    if empty(l:ret)
        let l:ret = a:filetype
    elseif s:FindAltFileType(a:d, l:ret) !=# a:filetype
        throw "Invalid file type dictionary"
    endif

    return l:ret
endfunction

" -----------------------------------------------------------------------------

" Checks the availability of an alternative file type.
"
" Return value:
" Zero if no alternative file type is available, nonzero otherwise.
function {s:script}#AltFileTypeAvail()
    if &filetype != ""
        let l:alt_filetype_dict = {s:plugin}Get("alt_filetype", {
                    \ 'help': "text",
                    \ 'php': "html"
                    \ }, function("s:IsDict"))
        if s:CheckedAltFileType(l:alt_filetype_dict, &filetype) ==# &filetype
            let l:ret = 0
        else
            let l:ret = 1
        endif
    else
        let l:ret = 0
    endif
    return l:ret
endfunction

" -----------------------------------------------------------------------------

" Changes filetype to the alternative file type.
"
" Return value:
" 0
function {s:script}#AltFileType()

    if &filetype != ""
        let l:alt_filetype_dict = {s:plugin}Get("alt_filetype", {
                    \ 'help': "text",
                    \ 'php': "html"
                    \ }, function("s:IsDict"))
        let l:original_filetype = &filetype
        let &filetype = s:CheckedAltFileType(l:alt_filetype_dict,
                    \ l:original_filetype)
        if &filetype ==# l:original_filetype
            let l:unchged = " (unchanged)"
        else
            let l:unchged = ""
        endif
        echomsg "Option filetype is now set to " . &filetype . l:unchged . "."
    else
        call s:Warning("No file type detected")
    endif
endfunction

" -----------------------------------------------------------------------------

" Checks that the option to redirect the output to a new buffer is available
" for the current file type and is on.
"
" Return value:
" Zero if the option is not available or is off, nonzero otherwise.
function {s:script}#RedirectOutputAvailAndOn()
    let l:ret = 0
    if exists("b:" . s:prefix . "run_params")
        let l:d_shallow_copy = copy(b:{s:prefix}run_params)
        call filter(l:d_shallow_copy, 'v:key ==# "redirect_to_new_buffer"')
        if !empty(l:d_shallow_copy)
            let l:ret = b:{s:prefix}run_params["redirect_to_new_buffer"]
        endif
    endif
    return l:ret
endfunction

" -----------------------------------------------------------------------------

" Checks that the option to redirect the output to a new buffer is available
" for the current file type and is off.
"
" Return value:
" Non zero if the option is available and is off, zero otherwise.
function {s:script}#RedirectOutputAvailAndOff()
    let l:ret = 0
    if exists("b:" . s:prefix . "run_params")
        let l:d_shallow_copy = copy(b:{s:prefix}run_params)
        call filter(l:d_shallow_copy, 'v:key ==# "redirect_to_new_buffer"')
        if !empty(l:d_shallow_copy)
            let l:ret = !b:{s:prefix}run_params["redirect_to_new_buffer"]
        endif
    endif
    return l:ret
endfunction

" -----------------------------------------------------------------------------

" Causes the output not to be redirected when running perfitys#RunWithArgs.
"
" Return value:
" 0
function {s:script}#DoNotRedirectOutputToNewBuffer()
    if !{s:script}#RedirectOutputAvailAndOn()
                \ && !{s:script}#RedirectOutputAvailAndOff()
        throw "Not applicable to files of type " . &filetype
    endif
    let b:{s:prefix}run_params["redirect_to_new_buffer"] = 0
    echomsg "Output won't be redirected to a new buffer."
    call {s:plugin}UpdateMenusEnableState()
endfunction

" -----------------------------------------------------------------------------

" Causes the output to be redirected when running perfitys#RunWithArgs.
"
" Return value:
" 0
function {s:script}#RedirectOutputToNewBuffer()
    if !{s:script}#RedirectOutputAvailAndOn()
                \ && !{s:script}#RedirectOutputAvailAndOff()
        throw "Not applicable to files of type " . &filetype
    endif
    let b:{s:prefix}run_params["redirect_to_new_buffer"] = 1
    echomsg "Output will be redirected to a new buffer."
    call {s:plugin}UpdateMenusEnableState()
endfunction

" -----------------------------------------------------------------------------

" Checks the availability of a "RunWithArgs" function for the current file
" type.
"
" Return value:
" Zero if no "RunWithArgs" function is available for the current file type,
" nonzero otherwise.
function {s:script}#RunWithArgsAvail()
    return &filetype != "" && exists("*" . s:plugin . {s:plugin}FileType()
                \ . "RunWithArgs")
endfunction

" -----------------------------------------------------------------------------

" Identical to perfitys#RunWithArgsAvail except that the "RunWithArgs" command
" must have been run at least once to get a non zero return value.
"
" Return value:
" Zero if no "RunWithArgs" function is available for the current file type or
" if it is available but has not been run yet (if this can be determined), non
" zero otherwise.
function {s:script}#RunAgainWithArgsAvail()
    let l:ret = 0
    if exists("b:" . s:prefix . "run_params")
        let l:ret = 1
        let l:d_shallow_copy = copy(b:{s:prefix}run_params)
        call filter(l:d_shallow_copy, 'v:key ==# "run_count"')
        if !empty(l:d_shallow_copy)
            let l:ret = {s:script}#RunWithArgsAvail()
                        \ && b:{s:prefix}run_params["run_count"] > 0
        endif
    endif
    return l:ret
endfunction

" -----------------------------------------------------------------------------

" Checks the availability of a "CompileFile" function for the current file
" type.
"
" Return value:
" Zero if no "CompileFile" function is available for the current file type,
" nonzero otherwise.
function {s:script}#CompileFileAvail()
    return &filetype != "" && expand('%:e') != "gpr" &&
                \ exists("*" . s:plugin . {s:plugin}FileType() . "CompileFile")
endfunction

" -----------------------------------------------------------------------------

" Checks the availability of a "CompileAll" function for the current file
" type.
"
" Return value:
" Zero if no "CompileAll" function is available for the current file type,
" nonzero otherwise.
function {s:script}#CompileAllAvail()
    return &filetype != "" && expand('%:e') != "gpr" &&
                \ exists("*" . s:plugin . {s:plugin}FileType()
                \ . "CompileAll")
endfunction

" -----------------------------------------------------------------------------

" Checks the availability of a "Build" function for the current file type.
"
" Return value:
" Zero if no "Build" function is available for the current file type, nonzero
" otherwise.
function {s:script}#BuildAvail()
    return &filetype != "" && expand('%:e') == "adb" &&
                \ exists("*" . s:plugin . {s:plugin}FileType() . "Build")
endfunction

" -----------------------------------------------------------------------------

" Runs the current file if (example for the sh file type) function
" PerfitysShRunWithArgs exists.
"
" Return value:
" 0
function {s:script}#RunWithArgs(...)

    " Check the argument.
    if a:0 > 1
        throw "Zero or one argument expected"
    elseif a:0 == 1 && !{s:plugin}IsInteger(a:1)
        throw "Integer argument expected"
    endif

    let l:file_type = {s:plugin}FileType()
    if {s:script}#RunWithArgsAvail()
        try
            call {s:plugin}{l:file_type}RunWithArgs(a:0 == 1 ? a:1 : 0)
        catch
            throw v:exception
        endtry
        call {s:plugin}UpdateMenusEnableState()
    else
        call s:Warning("Not applicable to files of type " . &filetype)
    endif
endfunction

" -----------------------------------------------------------------------------

" Runs the current file with the same arguments as the last time if (example
" for the sh file type) function PerfitysShRunWithArgs exists. If the current
" file has not been run yet, then this function behaves like
" perfitys#RunWithArgs.
"
" Return value:
" 0
function {s:script}#RunAgainWithArgs()
    call {s:script}#RunWithArgs({s:script}#RunAgainWithArgsAvail())
endfunction

" -----------------------------------------------------------------------------

" Checks the syntax of the current file if (example for the ada file type)
" function PerfitysAdaCompileFile exists.
"
" Return value:
" 0
function {s:script}#CompileFile()

    let l:file_type = {s:plugin}FileType()
    if {s:script}#CompileFileAvail()
        try
            call {s:plugin}{l:file_type}CompileFile()
        catch
            throw v:exception
        endtry
        call {s:plugin}UpdateMenusEnableState()
    else
        call s:Warning("Applicable to files of type " . &filetype
                    \ . " (except .gpr files)")
    endif
endfunction

" -----------------------------------------------------------------------------

" Checks the semantic of the current file if (example for the ada file type)
" function PerfitysAdaCompileAll exists.
"
" Return value:
" 0
function {s:script}#CompileAll()

    let l:file_type = {s:plugin}FileType()
    if {s:script}#CompileAllAvail()
        try
            call {s:plugin}{l:file_type}CompileAll()
        catch
            throw v:exception
        endtry
        call {s:plugin}UpdateMenusEnableState()
    else
        call s:Warning("Applicable to files of type " . &filetype
                    \ . " (except .gpr files)")
    endif
endfunction

" -----------------------------------------------------------------------------

" Builds a program from the current file if (example for the ada file type)
" function PerfitysAdaBuild exists.
"
" Return value:
" 0
function {s:script}#Build()

    let l:file_type = {s:plugin}FileType()
    if {s:script}#BuildAvail()
        try
            call {s:plugin}{l:file_type}Build()
        catch
            throw v:exception
        endtry
        call {s:plugin}UpdateMenusEnableState()
    else
        call s:Warning("Applicable to .adb files")
    endif
endfunction

" -----------------------------------------------------------------------------

" For any integer argument greater than 1 and lower than or equal to the number
" of line in the current buffer, returns the text of the line with number equal
" to the argument minus 1. For other integer values, returns an empty string.
"
" Arguments:
"
" #1 - lnum
" Integer.
"
" Return value:
" Text of the line with number equal to the argument minus 1, or empty string.
function {s:script}#GetPreviousLine(lnum)

    " Check the argument.
    if !{s:plugin}IsInteger(a:lnum)
        throw "Argument must be an integer"
    endif

    return getline(a:lnum - 1)
endfunction

" -----------------------------------------------------------------------------

" Moves the cursor to the next line containing only the string given as
" argument, with zero or more spaces or tabulations at the beginning or at the
" end of the line. Does not wrap around the end of the file.
"
" Arguments:
"
" #1 - s
" Any non empty string.
"
" Return value:
" Number of the line containgin the string or 0 if such line not found.
function {s:script}#NextIsolateOccurence(s)

    " Check the argument.
    if !{s:plugin}IsNonEmptyString(a:s)
        throw "Argument must be a non empty string"
    endif

    return search('^\s*' . a:s . '\s*$')
endfunction

" -----------------------------------------------------------------------------

" Moves the cursor to the next non empty line or does not move the cursor if
" the current line is not empty. Does not wrap around the end of the file.
"
" Return value:
" Text of the next non empty line or of the current line if the current line is
" not empty (or an empty string if no non empty line is found).
function {s:script}#NextNonEmptyLine()
    let l:lnum = search('\S', 'cW')
    if l:lnum != 0
        let l:ret = getline(l:lnum)
    else
        let l:ret = ""
    endif
    return l:ret
endfunction

" -----------------------------------------------------------------------------

" Moves the cursor to the next line which is not an empty line and not an end
" of line comment line. Does not move the cursor if no such line is found. Does
" not wrap around the end of the file. In this function, what is called an end
" of line comment line is a line starting with zero or more spaces or
" tabulations followed by the comment leader, followed by zero or more
" characters. The comment leader is found in dictionary variable
" b:perfitys_comment (component "leader") or is set to an empty string if such
" a variable is not found.
"
" Return value:
" 0 if only empty lines have been found while moving to the next line which is
" not an empty line and not an end of line comment line, 1 otherwise.
function {s:script}#NextNonEmptyNonEndOfLineCommentLine()

    " Get the number of the current line.
    let l:k = line('.')

    " Initialize the comment line count.
    let l:at_least_one_comment_found = 0

    " Get the comment leader.
    let l:comment = {s:plugin}GetLocal("comment",
                \ {'leader': "", 'trailer': ""}, function("s:IsCommentDict"))
    let l:comment_leader = l:comment["leader"]

    " Define a regular expression for empty or end of line comment lines.
    let l:empty_or_comment_reg_exp = '^\s*\(' . l:comment_leader . '.*\)*$'

    " Define a regular expression for end of line comment lines.
    let l:comment_reg_exp = '^\s*' . l:comment_leader

    while search(l:empty_or_comment_reg_exp, 'W') == l:k + 1
        let l:k += 1
        if !l:at_least_one_comment_found && getline(l:k) =~# l:comment_reg_exp
            let l:at_least_one_comment_found = 1
        endif
    endwhile
    call cursor(l:k + 1, 1)

    return l:at_least_one_comment_found
endfunction

" -----------------------------------------------------------------------------

" Returns a nonzero value if the argument is an end of line comment line, zero
" otherwise.
"
" Arguments:
"
" #1 - s
" Any string.
"
" Return value:
" 1 if the argument is an end of line comment line, 0 otherwise.
function {s:script}#IsEndOfLineComment(s)

    " Check the argument.
    if type(a:s) != type("")
        throw "Argument must be a string"
    endif

    " Get the comment leader.
    let l:comment = {s:plugin}GetLocal("comment",
                \ {'leader': "", 'trailer': ""}, function("s:IsCommentDict"))

    return a:s =~# '^\s*' . l:comment["leader"]

endfunction

" -----------------------------------------------------------------------------

" Returns a nonzero value if the argument is an end of line comment line, zero
" otherwise.
"
" Arguments:
"
" #1 - s
" Any string.
"
" #2 - reg_exp
" Regular expression starting with start anchor ('^').
"
" Return value:
" Part of the string matching the regular expression, or empty string if there
" is no match. The part is at the beginning of the string.
function {s:script}#GetLeftShiftMatch(s, reg_exp)

    " Check the arguments.
    if type(a:s) != type("")
        throw "First argument must be a string"
    elseif type(a:reg_exp) != type("") || strcharpart(a:reg_exp, 0, 1) !=# "^"
        throw "Second argument must be a string (regular expression) "
                    \ . "starting with '^'"
    endif

    if empty(matchstr(a:s, a:reg_exp))
        let l:ret = ""
    else
        let l:ret = substitute(a:s, '\(' . a:reg_exp . '\)\(.*$\)',
                    \ '\=submatch(1)', "")
    endif

    return l:ret

endfunction

" -----------------------------------------------------------------------------

" Truthy if a "left shifted editing session" is on going, falsy otherwise.
"
" Return value:
" Nonzero if a "left shifted editing session" is on going, zero otherwise.
function {s:script}#EndLeftShiftAvail()

    return exists("g:" . s:prefix . "left_shift_match")
                \ && g:{s:prefix}left_shift_match != ""
                \ && g:{s:prefix}left_shift_bufname ==# bufname("%")
                \ && g:{s:prefix}left_shift_bufnr == bufnr("%")

endfunction

" -----------------------------------------------------------------------------

" Falsy if a "left shifted editing session" is on going, truthy otherwise.
"
" Return value:
" Zero if a "left shifted editing session" is on going, nonzero otherwise.
function {s:script}#BeginLeftShiftAvail()

    return !exists("g:" . s:prefix . "left_shift_match")
                \ || g:{s:prefix}left_shift_match == ""

endfunction

" -----------------------------------------------------------------------------

" Start a "left shifted editing session" (shift current line and neighbor line
" to the left according to local plugin related parameter "left_shift_reg_exp",
" decrease the textwidth option accordingly and turn syntax highlighting off).
"
" Return value:
" 0
function {s:script}#BeginLeftShift()

    if !{s:script}#BeginLeftShiftAvail()
        throw "Function currently not available in this buffer"
    endif

    let l:left_shift_reg_exp = {s:plugin}GetLocal("left_shift_reg_exp",
                \ s:left_shift_reg_exp_default,
                \ function(s:plugin . "IsString"))
    let l:left_shift_reg_exp = {s:plugin}Get("left_shift_reg_exp", &filetype,
                \ l:left_shift_reg_exp, function(s:plugin . "IsString"))

    let b:{s:prefix}left_shift_lmin = line('.')
    let g:{s:prefix}left_shift_match
                \ = {s:script}#GetLeftShiftMatch(
                \ getline(b:{s:prefix}left_shift_lmin), l:left_shift_reg_exp)

    if g:{s:prefix}left_shift_match == ""
        throw "Unable to shift to the left"
    endif

    let b:{s:prefix}left_shift_lmin = b:{s:prefix}left_shift_lmin
    while b:{s:prefix}left_shift_lmin > 1 && {s:script}#GetLeftShiftMatch(
                \ getline(b:{s:prefix}left_shift_lmin - 1),
                \ l:left_shift_reg_exp) ==# g:{s:prefix}left_shift_match
        let b:{s:prefix}left_shift_lmin -= 1
    endwhile

    let b:{s:prefix}left_shift_lmax = b:{s:prefix}left_shift_lmin
    while b:{s:prefix}left_shift_lmax < line('$')
                \ && {s:script}#GetLeftShiftMatch(
                \ getline(b:{s:prefix}left_shift_lmax + 1),
                \ l:left_shift_reg_exp) ==# g:{s:prefix}left_shift_match
        let b:{s:prefix}left_shift_lmax += 1
    endwhile

    let l:k = b:{s:prefix}left_shift_lmin
    for l:line in getline(b:{s:prefix}left_shift_lmin,
                \ b:{s:prefix}left_shift_lmax)
        call setline(l:k, strcharpart(l:line,
                    \ strchars(g:{s:prefix}left_shift_match)))
        let l:k += 1
    endfor

    let b:{s:prefix}left_shift_amount = strchars(g:{s:prefix}left_shift_match)
    let b:{s:prefix}left_shift_amount = b:{s:prefix}left_shift_amount
                \ < &textwidth ? b:{s:prefix}left_shift_amount : 0
    let &textwidth -= b:{s:prefix}left_shift_amount
    let b:{s:prefix}left_shift_syntax_ft = &syntax
    let g:{s:prefix}left_shift_bufname = bufname("%")
    let g:{s:prefix}left_shift_bufnr = bufnr("%")
    let &syntax = "off"

    call {s:plugin}UpdateMenusEnableState()

endfunction

" -----------------------------------------------------------------------------

" End a "left shifted editing session" (shift lines of the visual selection
" back, restore the textwidth option and syntax highlighting).
"
" Return value:
" 0
function {s:script}#EndLeftShift() range

    if !{s:script}#EndLeftShiftAvail()
        throw "Function currently not available in this buffer"
    endif

    if a:firstline != b:{s:prefix}left_shift_lmin
        if !exists("b:" . s:prefix . "left_shift_not_attempted")
                    \ || !b:{s:prefix}left_shift_not_attempted
            let b:{s:prefix}left_shift_not_attempted = 1
            throw "Did not expect current visual selection. "
                        \ . "Reselect and relaunch function"
        endif
    endif

    let b:{s:prefix}left_shift_not_attempted = 0

    let l:k = a:firstline
    for l:line in getline(a:firstline, a:lastline)
        call setline(l:k,substitute(l:line, '^',
                    \ g:{s:prefix}left_shift_match, ""))
        let l:k += 1
    endfor
    let &textwidth += b:{s:prefix}left_shift_amount
    let &syntax = b:{s:prefix}left_shift_syntax_ft

    let g:{s:prefix}left_shift_match = ""

    call {s:plugin}UpdateMenusEnableState()
    let g:{s:prefix}left_shift_bufname = ""
    let g:{s:prefix}left_shift_bufnr = -1

endfunction

" -----------------------------------------------------------------------------

" Checks the applicability of the perfitys#VimgrepInQf function for the
" current buffer.
"
" Return value:
" Zero if the perfitys#VimgrepInQf function is not applicable to the current
" buffer, nonzero if it *may* run without error.
function {s:script}#VimgrepInQFAvail()
    return exists("b:" . s:prefix . "vimgrepinqf_params")
                \ && s:IsVimgrepInQFDict(b:{s:prefix}vimgrepinqf_params)
                \ && b:{s:prefix}vimgrepinqf_params['reg_exp'] != ""
endfunction

" -----------------------------------------------------------------------------

" Executes a vimgrep command and opens the quickfix window. The vimgrep command
" is made of the information found in b:perfitys_vimgrepinqf_params.
"
" b:perfitys_vimgrepinqf_params is supposed to be a dictionary with the
" following keys:
" - reg_exp: Regular expression to be used in the vimgrep command;
" - file: File(s) to grep (can be something like **/*.vim);
" - min_cwd_depth: A current directory depth threshold. If the current
"   directory is not deep enough, the function will abort. This has been
"   implemented to minimize the risk of starting a recursive greping that would
"   last very long.
" - relative_to_home: non zero to interpret the directory the directory depth
"   threshold relative to the user's home directory.
"
" Return value:
" 0
function {s:script}#VimgrepInQF()

    let l:args = {s:plugin}GetLocal("vimgrepinqf_params", {
                \ 'reg_exp': '',
                \ 'file': '',
                \ 'min_cwd_depth': 0,
                \ 'relative_to_home': 1,
                \ }, function("s:IsVimgrepInQFDict"))

    let l:cwd = getcwd()
    let l:reduced_cwd = fnamemodify(l:cwd, ':~')
    let l:cwd_is_below_home = l:reduced_cwd !=# l:cwd
    let l:reduced_cwd = substitute(l:reduced_cwd, '^\~', '', "")
    let l:temporary = ""
    let l:depth = -1
    while l:temporary !=# l:reduced_cwd
        let l:temporary = l:reduced_cwd
        let l:reduced_cwd = fnamemodify(l:reduced_cwd, ':h')
        let l:depth += 1
    endwhile

    let l:msg = ""
    if l:args['reg_exp'] == ""
        let l:msg = "Empty regular expression"
    elseif l:args['file'] == ""
        let l:msg = "No file"
    elseif l:args['relative_to_home'] && !l:cwd_is_below_home
        let l:msg = "Current directory is not below your home directory"
    elseif l:depth < l:args['min_cwd_depth']
        let l:msg = "Insufficient directory depth"
    endif

    if l:msg == ""

        " Store the number of the current window.
        let l:cur_win = winnr()

        try
            execute "vimgrep /" . l:args['reg_exp'] . "/j " . l:args['file']
        catch
            call s:Warning("No match")
        endtry

        " Open the quickfix window if the vimgrep command above has yield
        " results.
        execute "cwindow"

        " Select back the original window.
        execute l:cur_win. "wincmd w"
    else
        call s:Warning(l:msg)
    endif

endfunction

" -----------------------------------------------------------------------------

" Zero if the quickfix window is not opened, number of the quickfix window
" otherwise.
"
" Return value:
" Zero if the quickfix window is not opened, number of the quickfix window
" otherwise.
function {s:script}#QFWinNr()

    " Store the number of the current window.
    let l:cur_win = winnr()

    " Store the number of the last window.
    let l:last_win = winnr('$')

    " Move to each windows until the file type of the buffer in the window is
    " "qf" (which means that the window is probably the quickfix window).
    let l:k = 0
    let l:qf_found = 0
    while l:k < l:last_win
        let l:k += 1
        execute l:k . "wincmd w"
        if &filetype ==# "qf"
            let l:qf_found = 1
            break
        endif
    endwhile

    " Select back the original window.
    execute l:cur_win. "wincmd w"

    return l:qf_found ? l:k : 0
endfunction

" -----------------------------------------------------------------------------

" Changes the height of the quickfix window. If the argument is the string
" "taller", then the height of the quickfix window is made higher. If the
" argument is the string "smaller", then the height of the quickfix window is
" made lower.
"
" The height his changed by the value found in variable g:perfitys_qfheightstep
" or 3 if this variable does not exist. If it exists, the variable must be
" greater than 0.
"
" If the quickfix window, does not exist, issues a warning messsage.
"
" Arguments:
"
" #1 - tallerorsmaller
" "taller" or "smaller".
"
" Return value:
" 0
function s:ChangeQFHeight(tallerorsmaller)

    let l:step = {s:plugin}Get("qfheightstep", 3,
                \ function(s:plugin . "IsPositive"))

    let l:qfnr = {s:script}#QFWinNr()
    if l:qfnr > 0
        " The quickfix window is opened.

        " Store the number of the current window.
        let l:cur_win = winnr()

        " Move to the quickfix window.
        execute l:qfnr . "wincmd w"

        " Get the height of the window.
        let l:h = winheight(0)

        " Change the height of the window.
        if a:tallerorsmaller ==# "taller"
            let l:h += l:step
        else
            let l:h = max([l:step, l:h - l:step])
        endif
        execute l:h . "wincmd _"

        " Select back the original window.
        execute l:cur_win. "wincmd w"
    else
        call s:Warning("Quickfix window not opened")
    endif
endfunction

" -----------------------------------------------------------------------------

" Increases the height of the quickfix window by calling
" s:ChangeQFHeight("taller").
"
" Return value:
" 0
function {s:script}#MakeQFTaller()
    call s:ChangeQFHeight("taller")
endfunction

" -----------------------------------------------------------------------------

" Reduces the height of the quickfix window by calling
" s:ChangeQFHeight("smaller").
"
" Return value:
" 0
function {s:script}#MakeQFSmaller()
    call s:ChangeQFHeight("smaller")
endfunction

" -----------------------------------------------------------------------------

" Returns the output of the scriptnames Vim command.
"
" Return value:
" Output of the scriptnames Vim command.
function s:ScriptNames()
    redir => l:script_names
    silent scriptnames
    redir END
    return l:script_names
endfunction

" -----------------------------------------------------------------------------

" Returns a regular expression that the file name of the Perfitys filetype
" plugin for the file type of the current buffer matches.
"
" Return value:
" Regular expression.
function s:FTPluginRegExp()
    return '\W' . s:script . '\Wftplugin\W' . &filetype . '_' . s:script
                \ . '\.vim'
endfunction

" -----------------------------------------------------------------------------

" Checks whether the Perfitys filetype plugin for the file type of the current
" buffer has been loaded or not.
"
" Return value:
" 0 if the filetype plugin has not been loaded, otherwise return value of
" match() for the regular expression returned by s:FTPluginRegExp on the output
" of the scriptnames command.
function {s:script}#FTPluginAvail()
    return max([0, match(s:ScriptNames(), s:FTPluginRegExp()
                \ . '[' . nr2char(10) . nr2char(13) . ']')])
endfunction

" -----------------------------------------------------------------------------

" Sources the Perfitys filetype plugin for the current buffer.
"
" Return value:
" 0
function {s:script}#SourceFTPlugin()

    let l:n = {s:script}#FTPluginAvail()
    if l:n == 0
        call s:Warning("Unable to source the Perfitys filetype plugin")
    endif

    " Get the file name of the Perfitys filetype plugin.
    let l:script_names = s:ScriptNames()

    let l:p = l:n
    while l:p > 0 && l:script_names[l:p] != ":"
        let l:p -= 1
    endwhile
    let l:p += 1

    let l:q = l:n
    while l:q < len(l:script_names)
                \ && l:script_names[l:q] != nr2char(10)
                \ && l:script_names[l:q] != nr2char(13)
        let l:q += 1
    endwhile
    let l:q -= 1

    let l:f = substitute(l:script_names[l:p : l:q], '^\s*', '', '')
    let l:f = substitute(l:f, '\s*$', '', '')

    " Delete the b:did_ftplugin flag if it exists (necessary to allow the
    " filetype plugin to run completely).
    if exists("b:did_ftplugin")
        unlet b:did_ftplugin
    endif

    " Source the filetype plugin.
    execute "source ". l:f

endfunction

" -----------------------------------------------------------------------------

" Restore the value of cpoptions.
let &cpo = s:save_cpo

unlet s:save_cpo
