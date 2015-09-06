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
            \}

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
" Non-zero if d is a dictionary containing a valid comment leader and a valid
" comment trailer, zero otherwise.
function s:IsCommentDict(d)
    let l:ret = type(a:d) == type({})
    if l:ret
        let l:expected_keys = [
                    \ 'leader',
                    \ 'trailer',
                    \ ]
        let l:match_count = 0
        for key in keys(a:d)
            if index(l:expected_keys, key) != -1
                let l:match_count += 1
            endif
        endfor
        let l:ret = l:match_count == len(l:expected_keys)
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
" Non-zero if d is a dictionary containing valid parameters for a separator
" line, zero otherwise.
function s:IsSepDict(d)
    let l:ret = type(a:d) == type({})
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
        let l:match_count = 0
        for key in keys(a:d)
            if index(l:expected_keys, key) != -1
                let l:match_count += 1
            endif
        endfor
        let l:ret = l:match_count == len(l:expected_keys)
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

" Checks that the argument is a dictionary.
"
" Arguments:
"
" #1 - d
" Anything.
"
" Return value:
" Non-zero if d is a dictionary, zero otherwise.
function s:IsDict(d)
    return type(a:d) == type({})
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
    let l:local_sep = {s:plugin}GetLocal(l:ident, {
                \ 'indent_level': 0,
                \ 'post_comment_leader_space': " ",
                \ 'repeating_sequence': "-",
                \ 'length': &textwidth - 20,
                \ 'pre_comment_trailer_space': " ",
                \ 'empty_lines_above': 1,
                \ 'empty_lines_below': 1,
                \ }, function("s:IsSepDict"))

    call s:PutSep({s:plugin}Get(l:ident, &filetype, l:local_sep,
                \ function("s:IsSepDict")))
endfunction

" -----------------------------------------------------------------------------

" Checks that the string given as argument "looks like" a primary separator
" line.
"
" Arguments
"
" #1 - s
" Any string.
"
" Return value:
" Non-zero if the string matches the regular expression returned by
" s:SepRegExp(s:prim_sep_default_dic).
function {s:script}#MatchesPrimSep(s)
    return a:s =~# s:SepRegExp(s:prim_sep_default_dic)
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

    " Check the argument.
    if !s:IsSepDict(a:sep)
        throw "Invalid separator line dictionary"
    endif

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

    " Check the argument.
    if !s:IsSepDict(a:sep)
        throw "Invalid separator line dictionary"
    endif

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

    " Check the arguments.
    if (type(a:s) != type("") && type(a:s) != type(0))
                \ || (type(a:reg_exp) != type("")
                \ && type(a:reg_exp) != type(0))
        throw "Wrong type for at least one argument"
    endif

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

    " Check the arguments.
    if (type(a:s) != type("") && type(a:s) != type(0))
                \ || (a:0 == 1 && type(a:1) != type(0))
        throw "Wrong type for at least one argument"
    elseif a:0 > 1
        throw "Too many arguments"
    endif

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

    " Check the arguments.
    if (type(a:s) != type("") && type(a:s) != type(0))
                \ || (a:0 == 1 && type(a:1) != type(0))
        throw "Wrong type for at least one argument"
    elseif a:0 > 1
        throw "Too many arguments"
    endif

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

    " Check the argument.
    if type(a:d) != type({})
        throw "Dictionary expected"
    elseif empty(a:d)
        throw "Argument must be a non-empty directory"
    endif

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

    " Check the argument.
    if type(a:d) != type({})
        throw "Dictionary expected"
    elseif empty(a:d)
        throw "Argument must be a non-empty dictionary"
    endif

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
" it is not empty. If it is empty, an exception is thrown.
"
" If the dictionnary given as first argument has no key matching the file type
" given as second argument, then the function looks for a value matching the
" filetype and returns the associated key if such a value is found.
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

    " Check the arguments.
    if type(a:d) != type({}) || type(a:filetype) != type("")
        throw "Wrong type for at least one argument"
    elseif a:filetype == ""
        throw "File type argument must not be an empty string"
    endif

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

    " Check the argument.
    if type(a:d) != type({}) || type(a:filetype) != type("")
        throw "Wrong type for at least one argument"
    elseif a:filetype == ""
        throw "File type argument must not be an empty string"
    endif

    let l:ret = s:FindAltFileType(a:d, a:filetype)
    if empty(l:ret)
        let l:ret = a:filetype
    elseif s:FindAltFileType(a:d, l:ret) !=# a:filetype
        throw "Invalid file type dictionary"
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
        echohl WarningMsg | echo "No file type detected" | echohl None
    endif
endfunction

" -----------------------------------------------------------------------------

" Restore the value of cpoptions.
let &cpo = s:save_cpo

unlet s:save_cpo
