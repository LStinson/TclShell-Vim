" ============================================================================
" File:         TclShell.vim (Autoload)
" Last Changed: Sun, Sep 25, 2011
" Maintainer:   Lorance Stinson AT Gmail...
" License:      Public Domain
"
" Description:  The functional parts of TclShell.
"               Only load it if/when the shell is called.
" ============================================================================

if exists("g:loadedTclShellAuto") || &cp || !has('tcl')
    finish
endif
let g:loadedTclShellAuto= 1

" Default prompt.
if !exists("g:TclShellPrompt")
    let g:TclShellPrompt = "Tcl Shell # "
endif

" Cache the prompt length for calculations.
" Save the prompt in case the user changes it.
let s:prompttext = g:TclShellPrompt
let s:promptlen = len(s:prompttext)

" Default to insert mode in the Shell window.
if !exists("g:TclShellInsert")
    let g:TclShellInsert = 1
endif

" Enable the extended Tcl Shell Window mappings by defailt.
if !exists("g:TclShellDisableExtMap")
    let g:TclShellDisableExtMap = 0
endif

" Default to a maximum of 50 items in the history.
" Set to 0 to disable history.
if !exists("g:TclShellHistMax")
    let g:TclShellHistMax = 50
endif

" Start with no history.
let s:TclShellHistory=[]
let s:TclShellHistPtr=-1

" Create or switch to the Tcl Shell buffer.
function! TclShell#OpenShell(...)
    " If not already in the buffer create/open it.
    if expand("%:p:t") != "_TclShell_"
        " Make the buffer or switch to it.
        if bufexists("_TclShell_")
            let winnbr = bufwinnr("_TclShell_")
            if winnbr == -1
                sbuffer _TclShell_
                call TclShell#Init()
            else
                execute winnbr . 'wincmd w'
            endif
        else
            split _TclShell_
            call TclShell#Init()
        endif

        " Reset these every time the buffer is entered.
        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal noswapfile
        call TclShell#Prompt()
    endif

    " If there is an argument execute it.
    if a:0 == 1
        let l:line = getline('$') . substitute(a:1, '[\r\n]*$', '', '')
        call setline('$', l:line)
        call TclShell#Exec()
    endif
endfunction

" Initialize a new buffer.
function! TclShell#Init()
    " Standard key mappings to execute code.
    nnoremap <silent> <buffer> <cr>             :call TclShell#Exec()<cr>
    inoremap <silent> <buffer> <cr>        <Esc>:call TclShell#Exec()<cr>

    " Extended key mappings to behave like a terminal.
    if !g:TclShellDisableExtMap
        " Control Keys.
        exec 'nnoremap <silent> <buffer> <C-A>      0' . s:promptlen . 'l'
        exec 'inoremap <silent> <buffer> <C-A> <Esc>0' . s:promptlen . 'li'
        nnoremap <silent> <buffer> <C-B>            h
        inoremap <silent> <buffer> <C-B>       <Esc>ha
        nnoremap <silent> <buffer> <C-D>            :close<cr>
        inoremap <silent> <buffer> <C-D>       <Esc>:close<cr>
        nnoremap <silent> <buffer> <C-E>            $
        inoremap <silent> <buffer> <C-E>       <Esc>A
        nnoremap <silent> <buffer> <C-F>            l
        inoremap <silent> <buffer> <C-K>       <Esc>ld$a
        nnoremap <silent> <buffer> <C-K>            d$
        inoremap <silent> <buffer> <C-F>       <Esc>la
        nnoremap <silent> <buffer> <C-L>            :call TclShell#Clear()<cr>
        inoremap <silent> <buffer> <C-L>       <Esc>:call TclShell#Clear()<cr>
        nnoremap <silent> <buffer> <C-N>            :call TclShell#Hist(0)<cr>
        inoremap <silent> <buffer> <C-N>       <Esc>:call TclShell#Hist(0)<cr>
        nnoremap <silent> <buffer> <C-P>            :call TclShell#Hist(1)<cr>
        inoremap <silent> <buffer> <C-P>       <Esc>:call TclShell#Hist(1)<cr>
        inoremap <silent> <buffer> <C-T>       <Esc>hxpa
        nnoremap <silent> <buffer> <C-T>            hxp
        exec 'nnoremap <silent> <buffer> <C-U>      0' . s:promptlen . 'lD'
        exec 'inoremap <silent> <buffer> <C-U> <Esc>0' . s:promptlen . 'lDa'

        " Alt Keys.
        inoremap <silent> <buffer> <A-b>       <Esc>Bi
        nnoremap <silent> <buffer> <A-b>            B
        inoremap <silent> <buffer> <A-d>       <Esc>ldwgi
        nnoremap <silent> <buffer> <A-d>            dw
        inoremap <silent> <buffer> <A-f>       <Esc>Ea
        nnoremap <silent> <buffer> <A-f>            El
    endif

    " Configure the syntax.
    exec 'syn include @TclSyn syntax/tcl.vim'
    exec 'syn region TclPrompt matchgroup=TclShell keepend start="' .
       \ s:prompttext . '" end=+$+ contains=@TclSyn'
    exec "hi link TclShell Comment"
    if g:TclShellInsert
        au BufEnter <buffer> startinsert!
    endif

    " Prepare the TCL code to execute Tcl Shell input.
    call TclShell#InitTcl()
endfunction

" Display the prompt.
function! TclShell#Prompt()
    let l:line = getline("$")
    if matchstr(l:line, s:prompttext) == ""
        if getline("$") != ""
            call append(line('$'), "")
        endif
        call setline(line('$'), s:prompttext)
    endif
    call cursor('$',col([line('$'),'$']))
    if g:TclShellInsert
        startinsert!
    endif
    let s:TclShellHistPtr=-1
endfunction

" Move forward and back in history.
" Direction is true for up, false for down.
function! TclShell#Hist(dir)
    if len(s:TclShellHistory)
        if a:dir
            if (s:TclShellHistPtr + 1) < len(s:TclShellHistory)
                let s:TclShellHistPtr += 1
            endif
        else
            if s:TclShellHistPtr >= 0
                let s:TclShellHistPtr -= 1
            endif
        endif
        if s:TclShellHistPtr >= 0
            let l:histtext = s:TclShellHistory[s:TclShellHistPtr]
        else
            let l:histtext = ''
        endif
        call setline('.', s:prompttext . l:histtext)
    endif
    if g:TclShellInsert
        startinsert!
    endif
endfunction

" Clear the shell buffer.
function! TclShell#Clear()
    normal ggdG
    :call TclShell#Prompt()
endfunction

" Execute a line of Tcl code.
function! TclShell#Exec()
    let l:line = getline('.')
    if match(l:line, s:prompttext) < 0
        echo "Not on the command line"
        return TclShell#Prompt()
    else
        let l:tclcode = substitute(l:line, s:prompttext, '', '')
        if l:tclcode == ""
            return TclShell#Prompt()
        elseif l:tclcode =~ "^clear\\>"
            return TclShell#Clear()
        else
            if g:TclShellHistMax
                if len(s:TclShellHistory) >= g:TclShellHistMax
                    let s:TclShellHistory = remove(s:TclShellHistory, -1)
                endif
                call insert(s:TclShellHistory, l:tclcode)
            endif
            call append(line('$'), l:tclcode)
            call cursor('$',col([line('$'),'$']))
            :tcl "::_TclShellEval"
            "call append(line('$'), "")
        endif
        call TclShell#Prompt()
    endif
endfunction

" Create the procedure to evaluate commands entered in the shell.
" Since the interpreter will likely outlast the buffer check that the
" procedure does not exist first.
" Also create a replacement puts command to collect output.
" Otherwise output goes to the vim output area.
function! TclShell#InitTcl()
:tcl << EOF
if {[info procs ::_TclShellEval] eq ""} {
    proc _TclShellPuts {args} {
        global _TclShellOutput
        set newline "\n"
        set argc [llength $args]
        set result [lindex $args end]
        if {$argc > 1 && [lindex $args 0] == "-nonewline"} {
            set newline ""
            set args [lrange $args 1 end]
            incr argc -1
        }
        append result $newline
        if {$argc > 1 && [lindex $args 0] != "stdout"} {
            _TclShellPutsReal -nonewline [lindex $args 0] $result
            return ""
        }
        append _TclShellOutput $result
        return ""
    }
    proc ::_TclShellEval {} {
        rename puts _TclShellPutsReal
        rename _TclShellPuts puts
        global _TclShellOutput
        set _TclShellOutput ""
        set buf $::vim::current(buffer)
        set command [$buf get end]
        $buf delete end
        # Special handling for variables.
        if {[string index $command 0] eq {$}} {
            set command "return $command"
        }
        catch {
            uplevel 1 eval [list $command]
        } result
        if {$_TclShellOutput ne ""} {
            foreach line [split $_TclShellOutput "\n\r"] {
                $buf append end $line
            }
        }
        if {$result ne ""} {
            foreach line [split $result "\n\r"] {
                $buf append end $line
            }
        }
        rename puts _TclShellPuts
        rename _TclShellPutsReal puts
        unset _TclShellOutput
        return 0
    }
}
EOF
endfunction
