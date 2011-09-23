" =============================================================================
" File:         TclShell.vim
" Last Changed: Thu, Sep 22, 2011
" Maintainer:   Lorance Stinson AT Gmail...
" License:      Public Domain
" Usage:        Place in plugins folder.
"               Execute :TclShell or type <Leader>tcl
"               (Leader is normally '\')
"               Ctrl-L clears the display.
" Note:         Can only enter one line of code.
"               Pressing Enter executes the code.
" =============================================================================

if exists("g:loadedTclShell") || &cp || !has('tcl')
    finish
endif
let g:loadedTclShell= 1

" Prompt text.
if !exists("g:TclShellPrompt")
    let g:TclShellPrompt = "Tcl Shell # "
endif

" Default to insert mode in the Shell window.
if !exists("g:TclShellInsert")
    let g:TclShellInsert = 1
endif

" Default key mapping to open the shell buffer
if !exists("g:TclShellKey")
    let g:TclShellKey = '<Leader>tcl'
endif

" Start with no previous command.
let g:TclShellPrevLine = ""

" Key mapping and command.
if g:TclShellKey != ""
    exec 'nnoremap <silent> ' . g:TclShellKey .
       \ ' :call TclShellInit()<cr>'
    exec 'vnoremap <silent> ' . g:TclShellKey .
       \ " y:call TclShellInit('<C-R>" . '"' . "')<cr>"
endif
command! -nargs=? TclShell :call TclShellInit(<f-args>)

" Create and prepare the buffer.
function! TclShellInit (...)
    " If not already in the buffer create/open it.
    if expand("%:p:t") != "_TclShell_"
        " Make the buffer or switch to it.
        if bufexists ("_TclShell_")
            let winnbr = bufwinnr("_TclShell_")
            if winnbr == -1
                sbuffer _TclShell_
                call TclShellInitSyntax()
            else
                execute winnbr . 'wincmd w'
            endif
        else
            split _TclShell_
            call TclShellInitSyntax()
        endif

        " Reset these every time the buffer is entered.
        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal noswapfile
        call TclShellPrompt()
    endif

    " If there is an argument execute it.
    if a:0 == 1
        let l:line = getline('$') . substitute(a:1, '[\r\n]*$', '', '')
        call setline('$', l:line)
        call TclShellExec()
    endif
endfunction

" Display the prompt.
function! TclShellPrompt ()
    let l:line = getline("$")
    if matchstr(l:line, g:TclShellPrompt) == ""
        if getline("$") != ""
            call append(line('$'), "")
        endif
        call setline(line('$'), g:TclShellPrompt)
    endif
    normal G$
    if g:TclShellInsert
        startinsert!
    endif
endfunction

" Prepare the syntax for the buffer.
function! TclShellInitSyntax()
    let l:promptlen = len(g:TclShellPrompt)
    nnoremap <silent> <buffer> <cr>             :call TclShellExec()<cr>
    inoremap <silent> <buffer> <cr>        <Esc>:call TclShellExec()<cr>
    exec 'nnoremap <silent> <buffer> <C-A>      0' . l:promptlen . 'l'
    exec 'inoremap <silent> <buffer> <C-A> <Esc>0' . l:promptlen . 'li'
    nnoremap <silent> <buffer> <C-D>            :close<cr>
    inoremap <silent> <buffer> <C-D>       <Esc>:close<cr>
    nnoremap <silent> <buffer> <C-E>            $
    inoremap <silent> <buffer> <C-E>       <Esc>:startinsert!<cr>
    nnoremap <silent> <buffer> <C-L>            :call TclShellClear()<cr>
    inoremap <silent> <buffer> <C-L>       <Esc>:call TclShellClear()<cr>
    nnoremap <silent> <buffer> <C-P>            :call TclShellPrev()<cr>
    inoremap <silent> <buffer> <C-P>       <Esc>:call TclShellPrev()<cr>
    exec 'nnoremap <silent> <buffer> <C-U>      0' . l:promptlen . 'lD'
    exec 'inoremap <silent> <buffer> <C-U> <Esc>0' . l:promptlen . 'lDa'
    "inoremap <silent> <buffer> <C-W> <Esc><C-W>
    exec 'syn include @TclSyn syntax/tcl.vim'
    exec 'syn region TclPrompt matchgroup=TclShell keepend start="' .
       \ g:TclShellPrompt . '" end=+$+ contains=@TclSyn'
    exec "hi link TclShell Comment"
    if g:TclShellInsert
        au BufEnter <buffer> startinsert!
    endif
endfunction

" Append the previous command to the current line.
function! TclShellPrev()
    exec 'normal a' . g:TclShellPrevLine
    if g:TclShellInsert
        startinsert!
    endif
endfunction

" Clear the shell buffer.
function! TclShellClear()
    normal ggdG
    :call TclShellPrompt()
endfunction

" Execute a line of Tcl code.
function! TclShellExec()
    let l:line = getline('.')
    if match(l:line, g:TclShellPrompt) < 0
        echo "Not on the command line"
        normal G$
    else
        let l:tclcode = substitute(l:line, g:TclShellPrompt, '', '')
        if l:tclcode =~ "^clear\\>"
            normal ggdG
        else
            let g:TclShellPrevLine = l:tclcode
            call append(line('$'), l:tclcode)
            normal G$
            call TclShellExecLine()
            call append(line('$'), "")
        endif
        call TclShellPrompt()
    endif
endfunction

function! TclShellExecLine()
:tcl << EOF
set _tclshelltemp [::vim::expr "getline('.')"]
if {[string index $_tclshelltemp 0] eq {$}} {
    set _tclshelltemp "return $_tclshelltemp"
}
catch {
    eval $_tclshelltemp
} _tclshelltemp
::vim::command "normal dd"
if {$_tclshelltemp ne ""} {
    foreach _tclshelltemparg [split $_tclshelltemp "\n\r"] {
        $::vim::current(buffer) append end $_tclshelltemparg
    }
    unset _tclshelltemparg
}
unset _tclshelltemp
EOF
endfunction
