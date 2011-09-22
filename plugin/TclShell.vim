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
    let g:TclShellKey='<Leader>tcl'
endif

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
    " See if we are in the shell already.
    if expand("%:p:t") == "_TclShell_"
        return
    endif

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
    nnoremap <silent> <buffer> <cr> :call TclShellExec()<cr>
    inoremap <silent> <buffer> <cr> <Esc>:call TclShellExec()<cr>
    nnoremap <silent> <buffer> <C-L> :call TclShellClear()<cr>
    exec 'syn include @TclSyn syntax/tcl.vim'
    exec 'syn region TclPrompt matchgroup=TclShell keepend start="' .
       \ g:TclShellPrompt . '" end=+$+ contains=@TclSyn'
    exec "hi link TclShell Comment"
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
$::vim::current(buffer) append end $_tclshelltemp
unset _tclshelltemp
EOF
endfunction
