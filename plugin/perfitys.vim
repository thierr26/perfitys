" This file is part of the Perfitys Vim plugin.
"
" Maintainer: Thierry Rascle <thierr26@free.fr>
"
" License: Unlicense. Please refer to the LICENSE file.

" Compute the root of the base name of the current script (i.e. with the
" extension removed), in lower case.
let s:script = tolower(fnamemodify(expand('<sfile>:p'), ':t:r'))

" Check that the resulting name is made of lower case a to z letters and digits
" (but no digit at first position).
if s:script !~# '^[a-z][a-z0-9]*$'
    throw '<sfile>:p' . " is not a suitable file name for the plugin"
endif

if exists("g:loaded_" . s:script)
    " The user has already set g:loaded_perfitys to disable loading this plugin
    " or the plugin has already been loaded.

    " Stop sourcing the script.
    finish
endif
let g:loaded_{s:script} = 1

" Store the value of cpoptions.
let s:save_cpo = &cpo

" Set cpoptions to its Vim default.
set cpo&vim

" Compute the common prefix for all the plugin related variables, including a
" trailing underscore.
let s:prefix = s:script . "_"

" Compute the plugin name (with the first letter capitalized).
let s:plugin = substitute(s:script, "^.", '\=toupper(submatch(0))', "")

let s:common = "common"
let s:plugin_menu = "Plugin"
let s:menu_separator_count = 0
let s:added_menus_list = []

" -----------------------------------------------------------------------------

" Checks that the argument is a valid identifier for a plugin related
" parameter.
"
" Arguments:
"
" #1 - s
" Anything.
"
" Return value:
" Nonzero if the argument is a valid identifier for a plugin related parameter,
" zero otherwise.
function {s:plugin}IsParamIdent(s)
    return type(a:s) == type("") && a:s =~# '^[a-z][a-z0-9]*\(_[a-z0-9]\+\)*$'
endfunction

" -----------------------------------------------------------------------------

" Checks that the argument is an integer.
"
" Arguments:
"
" #1 - x
" Anything.
"
" Return value:
" Nonzero if the argument is an integer, zero otherwise.
function {s:plugin}IsInteger(x)
    return type(a:x) == type(0)
endfunction

" -----------------------------------------------------------------------------

" Checks that the argument is a non-negative integer.
"
" Arguments:
"
" #1 - x
" Anything.
"
" Return value:
" Nonzero if the argument is a non-negative integer, zero otherwise.
function {s:plugin}IsNatural(x)
    return {s:plugin}IsInteger(a:x) && a:x >= 0
endfunction

" -----------------------------------------------------------------------------

" Checks that the argument is a strictly positive integer.
"
" Arguments:
"
" #1 - x
" Anything.
"
" Return value:
" Nonzero if the argument is a strictly positive integer, zero otherwise.
function {s:plugin}IsPositive(x)
    return {s:plugin}IsInteger(a:x) && a:x > 0
endfunction

" -----------------------------------------------------------------------------

" Checks that the argument is a non-empty string.
"
" Arguments:
"
" #1 - s
" Anything.
"
" Return value:
" Nonzero if the argument is a non-empty string, zero otherwise.
function {s:plugin}IsNonEmptyString(s)
    return type(a:s) == type("") && strlen(a:s) > 0
endfunction

" -----------------------------------------------------------------------------

" Checks that the argument is a string.
"
" Arguments:
"
" #1 - s
" Anything.
"
" Return value:
" Nonzero if the argument is a string, zero otherwise.
function {s:plugin}IsString(s)
    return type(a:s) == type("")
endfunction

" -----------------------------------------------------------------------------

" Checks that the argument is a valid value for the expandtab option.
"
" Arguments:
"
" #1 - s
" Anything.
"
" Return value:
" Nonzero if s is one of "expandtab", "et", "noexpandtab", or "noet".
function {s:plugin}IsExpandTabValue(s)
    return type(a:s) == type("")
                \ && (a:s =~# '^\(no\)\?et$' || a:s =~# '^\(no\)\?expandtab$')
endfunction

" -----------------------------------------------------------------------------

" Checks that the argument is a valid value for the foldmethod option.
"
" Arguments:
"
" #1 - s
" Anything.
"
" Return value:
" Nonzero if s is one of "manual", "indent", "expr", "marker", "syntax" or
" "diff".
function {s:plugin}IsFoldingMethodValue(s)
    let l:ValidValues
                \ = ["manual", "indent", "expr", "marker", "syntax", "diff"]
    return type(a:s) == type("") && index(l:ValidValues, a:s) >= 0
endfunction

" -----------------------------------------------------------------------------

" Checks the existence of a global variable. The name of the variable is "g:"
" followed by s:prefix ("perfitys_") and followed by the argument. If a second
" argument is given, an underscore is appended to it and it is appended to
" s:prefix. Note that if the second argument is empty, it is substituted with
" "common".
"
" Arguments:
"
" #1 - ident
" Part of the variable identifier.
"
" #2 (optional)
" Optional part of the variable identifier.
"
" Return value:
" Nonzero if the global variable exists, zero otherwise.
function {s:plugin}ExistsAsGlobal(ident, ...)

    " Check the arguments.
    if !{s:plugin}IsParamIdent(a:ident)
        throw "Invalid identifier"
    elseif a:0 > 1
        throw "Too many arguments"
    elseif a:0 == 1 && type(a:1) != type("")
        throw "Invalid filetype (or filetype placeholder)
    endif

    if a:0 == 1
        if strlen(a:1) == 0
            let l:ft_placeholder = s:common . "_"
        else
            let l:ft_placeholder = a:1 . "_"
        endif
    else
        let l:ft_placeholder = ""
    endif

    return exists("g:" . s:prefix . l:ft_placeholder . a:ident)
endfunction

" -----------------------------------------------------------------------------

" Returns the value of a global variable. Designed to be only used after a call
" to the function {s:plugin}ExistsAsGlobal (with exactly the same arguments)
" that has returned a nonzero value. Use in any other condition is
" inappropriate.
"
" Arguments:
"
" #1 - ident
" Last word in the variable identifier.
"
" #2 (optional)
" Penultimate word in the variable identifier.
"
" Return value:
" Value of the global variable.
function {s:plugin}GetGlobal(ident, ...)

    if a:0 == 1
        if strlen(a:1) == 0
            let l:ft_placeholder = s:common . "_"
        else
            let l:ft_placeholder = a:1 . "_"
        endif
    else
        let l:ft_placeholder = ""
    endif

    return g:{s:prefix}{l:ft_placeholder}{a:ident}
endfunction

" -----------------------------------------------------------------------------

" Returns the value of a plugin related parameter.
"
" Example 1:
"
" The statement: let g:x = {s:plugin}Get("foo", "bar", function("len"))
" results in:
" - an exception being thrown if g:perfitys_foo exists and the len function
"   applied to it returns zero,
" - or g:x being set to the value of g:perfitys_foo if this variable exists and
"   the len function applied to it returns a nonzero value,
" - or an exception being thrown if the len function applied to "bar" returns
"   zero,
" - or g:x being set to "bar".
"
" Example 2:
"
" The statement: let g:x = {s:plugin}Get("foo", "sh", "bar", function("len"))
" results in:
" - an exception being thrown if g:perfitys_common_foo exists and the len
"   function applied to it returns zero,
" - or g:x being set to the value of g:perfitys_common_foo if this variable
"   exists and the len function applied to it returns a nonzero value,
" - an exception being thrown if g:perfitys_sh_foo exists and the len function
"   applied to it returns zero,
" - or g:x being set to the value of g:perfitys_sh_foo if this variable exists
"   and the len function applied to it returns a nonzero value,
" - or an exception being thrown if the len function applied to "bar" returns
"   zero,
" - or g:x being set to "bar".
"
" Arguments:
"
" #1 - ident
" Plugin related identifier ("foo" in the examples).
"
" #2 (optional)
" File type ("sh" in the examples).
"
" #3 (or #2 if the optional argument is absent)
" Default value for the plugin related parameter ("bar" in the examples).
"
" #4 (or #3) if the optional argument is absent)
" Reference (funcref) to a function designed to check the value of the plugin
" related parameter (function("len") in the examples). This function must
" return a nonzero value if the value of the plugin related parameter is valid
" and zero otherwise.
"
" Return value:
" Value of the plugin related parameter.
function {s:plugin}Get(ident, ...)

    " Check the arguments.
    if !{s:plugin}IsParamIdent(a:ident)
        throw "Invalid identifier"
    else
        if a:0 > 3
            throw "Too many arguments"
        elseif a:0 < 2
            throw "Argument(s) missing"
        else
            if a:0 == 3
                if type(a:1) != type("")
                    throw "Invalid file type"
                endif
            endif
            if (a:0 == 3 && type(a:3) != type(function("tr")))
                        \ || (a:0 == 2 && type(a:2) != type(function("tr")))
                throw "Last argument must be a funcref"
            endif
        endif
    endif

    let l:filetype_given = a:0 == 3
    let l:default_value = l:filetype_given ? a:2 : a:1
    let l:IsValid = l:filetype_given ? a:3 : a:2

    if l:filetype_given

        let l:filetype = a:1

        if {s:plugin}ExistsAsGlobal(a:ident, "")
            let l:ret = {s:plugin}GetGlobal(a:ident, "")
        elseif {s:plugin}ExistsAsGlobal(a:ident, l:filetype)
            let l:ret = {s:plugin}GetGlobal(a:ident, l:filetype)
        else
            let l:ret = l:default_value
        endif

    else

        if {s:plugin}ExistsAsGlobal(a:ident)
            let l:ret = {s:plugin}GetGlobal(a:ident)
        else
            let l:ret = l:default_value
        endif

    endif

    if !l:IsValid(l:ret)
        throw "Invalid custom " . a:ident . " parameter for " . s:plugin
                    \ .  " plugin"
    endif

    return l:ret
endfunction

" -----------------------------------------------------------------------------

" Checks whether a global variable exists and is set to a nonzero value. The
" name of the variable is "g:" followed by s:prefix ("perfitys_") followed by
" the function argument.
"
" Arguments:
"
" #1 - ident
" Variable identifier without the "g:perfitys_" prefix.
"
" Return value:
" Nonzero if the variable exists and is nonzero.
function {s:plugin}GlobalFlag(ident)

    " Check the argument.
    if !{s:plugin}IsParamIdent(a:ident)
        throw "Invalid identifier"
    endif

    return {s:plugin}ExistsAsGlobal(a:ident) && {s:plugin}GetGlobal(a:ident)
endfunction

" -----------------------------------------------------------------------------

" Assigns a buffer local variable (a b: variable). The name of the variable is
" "b:" followed by s:prefix ("perfitys_") followed by the first argument to the
" function.
"
" Arguments:
"
" #1 - ident
" Buffer local variable identifier without the "b:perfitys_" prefix.
"
" #2 - value
" Value to be assigned to the buffer local variable.
"
" Return value:
" 0
function {s:plugin}SetLocal(ident, value)

    " Check the arguments.
    if !{s:plugin}IsParamIdent(a:ident)
        throw "Invalid identifier"
    endif

    let b:{s:prefix}{a:ident} = a:value
endfunction

" -----------------------------------------------------------------------------

" Returns the value of a buffer local plugin related parameter. The name of the
" parameter is "b:" followed by s:prefix followed by the first argument to the
" function. If this variable does not exists, then the function returns the
" value of the second argument.
"
" Note that no validity check are performed for the buffer local variable as
" well as for the default value.
"
" Arguments:
"
" #1 - ident
" Plugin related identifier.
"
" #2 - default
" Default value.
"
" #3 - IsValid
" Reference (funcref) to a function designed to check the value of the plugin
" related parameter. This function must return a nonzero value if the value of
" the plugin related parameter is valid and zero otherwise.
"
" Return value:
" Value of the buffer local plugin related parameter.
function {s:plugin}GetLocal(ident, default, IsValid)

    " Check the arguments.
    if !{s:plugin}IsParamIdent(a:ident)
        throw "Invalid identifier"
    endif

    if exists("b:" . s:prefix . a:ident)
        let l:ret = b:{s:prefix}{a:ident}
    else
        let l:ret = a:default
    endif

    if !a:IsValid(l:ret)
        throw "Invalid local " . a:ident . " parameter for " . s:plugin
                    \ .  " plugin"
    endif

    return l:ret
endfunction

" -----------------------------------------------------------------------------

" Returns the file type with the first letter capitalized.
"
" Return value:
" File type with the first letter capitalized.
function {s:plugin}FileType()
    return substitute(&filetype, "^.", '\=toupper(submatch(0))', "")
endfunction

" -----------------------------------------------------------------------------

" Sets the colorcolumn option to the value given as argument if the colorcolumn
" option is empty, otherwise add the value given as argument if it is not
" already in the colorcolumn option.
"
" Argument
"
" #1 - column
" Integer value.
"
" Return value:
" 0
function {s:plugin}SetColorcolumn(column)

    " Check the argument.
    if !{s:plugin}IsInteger(a:column)
        throw "Argument must be an integer"
    endif

    if &colorcolumn == ""
        let &colorcolumn = a:column
    elseif &colorcolumn !~# ("^" . a:column . "$")
                \ && &colorcolumn !~# ("^" . a:column . ",")
                \ && &colorcolumn !~# ("," . a:column . "$")
        let &colorcolumn = &colorcolumn . "," . a:column
    endif

endfunction

" -----------------------------------------------------------------------------

" Sets the textwidth option for a specific file type to the value of the
" "width" argument, unless a variable named for example like
" "g:perfitys_sh_textwidth" exists (if &filetype is "sh") and is greater than
" or equal to 0. In this case, the textwidth option is set to the value of this
" variable. One last case is if a variable named "g:perfitys_common_textwidth"
" exists and is greater than or equal to 0. The value of this variable
" supersedes the values of both the argument and the file type specific
" variable.
"
" Additionally, sets the colorcolumn option if the textwidth is greater than 0.
" The value is the sum of the "width" and "colorcolumn_relative_to_width"
" arguments. If a variable named "g:perfitys_colorcolumn_relative_to_width"
" exists, then the value of this variable is used instead. Finally, if the
" global variable "g:perfitys_do_not_set_colorcolumn" exists and is nonzero,
" then the colorcolumn option is not affected.
"
" Arguments:
"
" #1 - width
" Value for the textwidth option. Must not be negative.
"
" #2 - colorcolumn_relative_to_width
" Complements the "width" argument to make the colorcolumn option value.
"
" Return value:
" 0
function {s:plugin}SetTextWidth(width, colorcolumn_relative_to_width)

    " Check the arguments.
    if !{s:plugin}IsNatural(a:width)
        throw "Text width must be a non-negative integer"
    elseif !{s:plugin}IsInteger(a:colorcolumn_relative_to_width)
        throw "2nd argument must be an integer"
    endif

    let &textwidth = {s:plugin}Get("textwidth", &filetype, a:width,
                \ function(s:plugin . "IsNatural"))

    if &textwidth > 0 && !{s:plugin}GlobalFlag("do_not_set_colorcolumn")
        call {s:plugin}SetColorcolumn(&textwidth
                    \ + {s:plugin}Get("colorcolumn_relative_to_width",
                    \ a:colorcolumn_relative_to_width,
                    \ function(s:plugin . "IsInteger")))
    endif
endfunction

" -----------------------------------------------------------------------------

" Sets tab preferences for a specific file type. The tabstop, shiftwidth and
" softtabstop options are set to the value of the "width" argument unless a
" variable named for example like "g:perfitys_sh_tabstop" exists (if &filetype
" argument is "sh"). In this case, the tabstop, shiftwidth and softtabstop
" options are set to the value of this variable. One last case is if a variable
" named "g:perfitys_common_tabstop" exists and is greater than 0. The value of
" this variable supersedes the values of both the "width" argument and the file
" type specific variable.
"
" The "expand" argument controls the setting of the expandtab option. Value
" "expandtab" or "et" causes the expandtab option to be set to expandtab and
" value "noexpandtab" or "noet" value causes the expandtab option to be set to
" noexpandtab. As for the tab width, the value of the argument can be supersede
" with a variable named like "g:perfitys_sh_expandtab" (if &filetype is "sh")
" or with a variable named "g:perfitys_common_expandtab".
"
" Arguments:
"
" #1 - width
" Tab and indentation width. Must not be lower than 1.
"
" #2 - expand
" One of "expantab", "et", "noexpandtab" or "noet".
"
" Return value:
" 0
function {s:plugin}SetTabPreferences(width, expand)

    " Check the arguments.
    if !{s:plugin}IsPositive(a:width)
        throw "Tab width must be a strictly positive integer"
    elseif !{s:plugin}IsExpandTabValue(a:expand)
        throw '3rd argument must be one of "expandtab", "et", "noexpandtab" '
                    \ . 'and "noet"'
    endif

    let l:width = {s:plugin}Get("tabstop", &filetype, a:width,
                \ function(s:plugin . "IsPositive"))
    let &tabstop = l:width
    let &shiftwidth = l:width
    let &softtabstop = l:width

    let l:expand = {s:plugin}Get("expandtab", &filetype, a:expand,
                \ function(s:plugin . "IsExpandTabValue"))
    let &expandtab = l:expand[0 : 1] !=# "no"
endfunction

" -----------------------------------------------------------------------------

" Does the appropriate comment configurations for file types with comment of
" type "end of line".
"
" This includes adding the comment leader to the comments option, with flag b.
" For example, if the comment leader given as argument is "--", then "b:--"
" will be added to the comments option.
"
" The values "*" and "-" for the argument are particular cases. They both cause
" the comments option to be set to "://,b:#,:%,:XCOMM,n:>,fb:-,fb:-,fb:*" which
" is suitable for the gitcommit file type.
"
" Argument:
"
" #1 - comment_leader
" Comment leader.
"
" Return value:
" 0
function {s:plugin}ConfigEndOfLineComment(comment_leader)

    " Check the argument.
    if !{s:plugin}IsNonEmptyString(a:comment_leader)
        throw "Argument must be a string"
    endif

    call {s:plugin}SetLocal("comment",
                \ {'leader': a:comment_leader, 'trailer': ""})

    let l:append_string = "b:" . a:comment_leader

    if a:comment_leader == "*" || a:comment_leader == "-"
        let &comments = "://,b:#,:%,:XCOMM,n:>,fb:-,fb:-,fb:*"
    elseif &comments == ""
        let &comments = l:append_string
    else
        let l:escape_list = '/*'
        let l:escaped_comment_leader = escape(a:comment_leader, l:escape_list)
        let l:cond1 = (&comments !~# ("^[^,m]*:" . l:escaped_comment_leader
                    \ . "$"))
        let l:cond2 = (&comments !~# ("^[^,m]*:" . l:escaped_comment_leader
                    \ . ","))
        let l:cond3 = (&comments !~# (",[^,m]*:" . l:escaped_comment_leader
                    \ . "$"))
        let l:cond4 = (&comments !~# (",[^,m]*:" . l:escaped_comment_leader
                    \ . ","))
        if l:cond1 && l:cond2 && l:cond3 && l:cond4
            let &comments = &comments . "," . l:append_string
        endif
    endif
endfunction

" -----------------------------------------------------------------------------

" Sets the foldmethod option for a specific file type to the value of the
" "method" argument, unless a variable named for example like
" "g:perfitys_sh_foldmethod" exists (if &filetype is "sh").
"
" Additionally, sets the foldexpr and foldtext options if the foldmethod option
" is "expr". By default they are set to "PerfitysShFoldLevel(v:lnum)"
" (respectively "PerfitysShFoldText") if those functions exist (if &filetype is
" "sh"). Those default values can be supersede with variables like
" g:perfitys_sh_foldexpr (respectively g:perfitys_sh_foldtext). If no default
" exist, the options are set to "0" (respectively "foldtext()").
"
" Arguments:
"
" #1 - method
" Value for the foldmethod option.
"
" Return value:
" 0
function {s:plugin}SetFoldingMethod(method)

    " Check the argument.
    if !{s:plugin}IsFoldingMethodValue(a:method)
        throw "Argument is not a valid value for option foldmethod"
    endif

    if !{s:plugin}GlobalFlag("do_not_set_foldmethod")

        let &foldmethod = {s:plugin}Get("foldmethod", &filetype, a:method,
                    \ function(s:plugin . "IsFoldingMethodValue"))

        if &foldmethod ==# "expr"

            let l:file_type = {s:plugin}FileType()

            let l:default_foldexpr = s:plugin . l:file_type
                        \ . "FoldLevel(v:lnum)"
            if !exists("*" . l:default_foldexpr)
                let l:default_foldexpr = "0"
            endif
            let &foldexpr = {s:plugin}Get("foldexpr", &filetype,
                        \ l:default_foldexpr,
                        \ function(s:plugin . "IsNonEmptyString"))

            let l:foldtext_for_default_foldexpr
                        \ = s:plugin . l:file_type . "FoldText()"
            if !exists("*" . l:foldtext_for_default_foldexpr)
                let l:foldtext_for_default_foldexpr = "foldtext()"
            endif
            let &foldtext = {s:plugin}Get("foldtext", &filetype,
                        \ l:foldtext_for_default_foldexpr,
                        \ function(s:plugin . "IsNonEmptyString"))

        endif
    endif

endfunction

" -----------------------------------------------------------------------------

" Full name of a plugin related autoloaded function.
"
" Arguments:
"
" #1 - func
" Name of the autoloaded function (without what is before "#" and without "#").
"
" #2 - map
" Map (like "<Leader>S").
"
" Return value:
" Full name of the plugin related autoloaded function.
function s:AutoloadFuncFullName(func)
    return s:script . "#" . a:func
endfunction

" -----------------------------------------------------------------------------

" Defines a map to a plugin related autoloaded function.
"
" Arguments:
"
" #1 - func
" Name of the autoloaded function (without what is before "#" and without "#").
"
" #2 - map
" Map (like "<Leader>S").
"
" Return value:
" 0
function s:DefineMapToAutoloadFunc(func, map)
    if !hasmapto('<Plug>' . s:plugin . a:func)
        execute "map <silent> <unique> " . a:map .
                    \ " <Plug>" . s:plugin . a:func
    endif
    execute "noremap <unique> <script> <Plug>" . s:plugin . a:func . " <SID>"
                \ . a:func
    execute "noremap <SID>" . a:func . " :call "
                \ . s:AutoloadFuncFullName(a:func) . "()<CR>"
endfunction

" -----------------------------------------------------------------------------

" Associates a command to a plugin related autoloaded function. The name of the
" command is the name given as argument (name of the autoloaded function
" without what is before "#" and without "#") unless another name is given via
" the optional second argument.
"
" Arguments:
"
" #1 - func
" Name of the autoloaded function (without what is before "#" and without "#").
"
" #2 (optional)
" Command name.
"
" Return value:
" 0
function s:DefineCommandForAutoloadFunc(func, ...)
    let a:name = a:0 == 1 ? a:1 : a:func
    if !exists(":" . a:name)
        execute "command " . a:name . " :call "
                    \ . s:AutoloadFuncFullName(a:func) . "()"
    endif
endfunction

" -----------------------------------------------------------------------------

" Associates a menu entry to a plugin related autoloaded function. The menu
" entry is placed in the Plugin|Perfitys menu.
"
" Arguments:
"
" #1 - func
" Name of the autoloaded function (without what is before "#" and without "#").
"
" #2 - menu_entry
" Menu entry.
"
" Return value:
" 0
function s:DefineMenuForAutoloadFunc(func, menu_entry, AvailabilityFunc)

    let l:full_menu_entry = escape(s:plugin_menu . "." . s:plugin . "."
                \ . a:menu_entry, ' ')

    execute "noremenu <silent> <script> " . l:full_menu_entry
                \ . " :call " . s:AutoloadFuncFullName(a:func) . "()<CR>"

    " Add the newly created menu to a list, along with the availability
    " function.
    call add(s:added_menus_list, {
                \ 'entry': l:full_menu_entry,
                \ 'AvailabilityFunc': a:AvailabilityFunc,
                \ })
endfunction

" -----------------------------------------------------------------------------

" Defines a map to a plugin related autoloaded function and associates a
" command and a menu entry to the same function.
"
" Arguments:
"
" #1 - func
" Name of the autoloaded function (without what is before "#" and without "#")
" and name of the associated command.
"
" #2 - map
" Map (like "<Leader>S").
"
" #3 - menu_entry
" Menu entry, like "Plugin.Perfitys.My Menu Entry" or "Perfitys.My Menu Entry".
" It must start with "Plugin.Perfitys." or "Perfitys.".
"
" Return value:
" 0
function s:DefineMapCommandAndMenu(func, map, menu_entry, AvailabilityFunc)
    call s:DefineMapToAutoloadFunc(a:func, a:map)
    call s:DefineCommandForAutoloadFunc(a:func)
    call s:DefineMenuForAutoloadFunc(a:func, a:menu_entry, a:AvailabilityFunc)
endfunction

" -----------------------------------------------------------------------------

" Inserts a menu separator in the Plugin|Perfitys menu.
"
" Return value:
" 0
function s:InsertMenuSeparator()
    let s:menu_separator_count += 1
    execute "menu " . s:plugin_menu . "." . s:plugin
                \ . ".-" . s:menu_separator_count . "- :"
endfunction

" -----------------------------------------------------------------------------

" Updates the enable state of the menu entries added by Perfitys.
"
" Return value:
" 0
function {s:plugin}UpdateMenusEnableState()
    for menu in s:added_menus_list
        let l:AvailabilityFunc = menu['AvailabilityFunc']
        let l:state = " disable "
        if empty(l:AvailabilityFunc) || l:AvailabilityFunc()
            let l:state = " enable "
        endif
        execute "menu" . l:state . menu['entry']

        " Removing l:AvailabilityFunc is necessary to avoid a "variable type
        " mismatch" error on the next iteration of the loop, because
        " menu['AvailabilityFunc'] can be of different types (string or
        " funcref).
        unlet l:AvailabilityFunc
    endfor
endfunction

" -----------------------------------------------------------------------------

" Set the general enable flag for the plugin.
let g:{s:script}_enabled = 1

" Define maps, commands and menus.

call s:DefineMapCommandAndMenu("SourceFTPlugin", "<Leader>SP",
            \ "Source filetype plugin",
            \ function(s:AutoloadFuncFullName("FTPluginAvail")))

call s:InsertMenuSeparator()

call s:DefineMapCommandAndMenu("PrimSep", "<Leader>SS",
            \ "Insert Primary Separator Line", "")
call s:DefineMapCommandAndMenu("SecondSep", "<Leader>S",
            \ "Insert Secondary Separator Line", "")
call s:DefineCommandForAutoloadFunc("PrimSep", "Sep")

call s:InsertMenuSeparator()

call s:DefineMapCommandAndMenu("BeginLeftShift", "<Leader>LL",
            \ "Begin left shifted editing",
            \ function(s:AutoloadFuncFullName("BeginLeftShiftAvail")))
call s:DefineMapCommandAndMenu("EndLeftShift", "<Leader>L",
            \ "End left shifted editing",
            \ function(s:AutoloadFuncFullName("EndLeftShiftAvail")))

call s:InsertMenuSeparator()

call s:DefineMapCommandAndMenu("AltFileType", "<Leader>FT",
            \ "Switch to the alternative file type",
            \ function(s:AutoloadFuncFullName("AltFileTypeAvail")))

call s:InsertMenuSeparator()

call s:DefineMapCommandAndMenu("DoNotRedirectOutputToNewBuffer", "<Leader>RN",
            \ "Don't redirect output to new buffer",
            \ function(s:AutoloadFuncFullName("RedirectOutputAvailAndOn")))
call s:DefineMapCommandAndMenu("RedirectOutputToNewBuffer", "<Leader>RR",
            \ "Redirect output to new buffer",
            \ function(s:AutoloadFuncFullName("RedirectOutputAvailAndOff")))
call s:DefineMapCommandAndMenu("RunWithArgs", "<F8>",
            \ "Enter arguments and run the current file",
            \ function(s:AutoloadFuncFullName("RunWithArgsAvail")))
call s:DefineMapCommandAndMenu("RunAgainWithArgs", "<F9>",
            \ "Run once more with the same arguments",
            \ function(s:AutoloadFuncFullName("RunAgainWithArgsAvail")))
call s:DefineMapCommandAndMenu("CompileFile", "<F10>",
            \ "Check syntax",
            \ function(s:AutoloadFuncFullName("CompileFileAvail")))
call s:DefineMapCommandAndMenu("CompileAll", "<F11>",
            \ "Check semantic",
            \ function(s:AutoloadFuncFullName("CompileAllAvail")))
call s:DefineMapCommandAndMenu("Build", "<F12>",
            \ "Build",
            \ function(s:AutoloadFuncFullName("BuildAvail")))

autocmd FileType,BufEnter * call {s:plugin}UpdateMenusEnableState()

" Restore the value of cpoptions.
let &cpo = s:save_cpo

unlet s:save_cpo
