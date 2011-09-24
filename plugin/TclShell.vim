" =============================================================================
" File:         TclShell.vim (Plugin)
" Last Changed: Thu, Sep 23, 2011
" Maintainer:   Lorance Stinson AT Gmail...
" License:      Public Domain
"
" Description:  Setup the keys to call TclShell.
"               The rest of the code is autoloaded when/if needed.
"
" Usage:        Place in plugins folder.
"               Execute :TclShell or type <Leader>tcl
"               (Leader is normally '\')
"               Ctrl-L clears the display.
"
" Note:         Can only enter one line of code.
"               Pressing Enter executes the code.
" =============================================================================

if exists("g:loadedTclShell") || &cp || !has('tcl')
    finish
endif
let g:loadedTclShell= 1

" Default key mapping to open the shell buffer
if !exists("g:TclShellKey")
    let g:TclShellKey = '<Leader>tcl'
endif

" Key mapping and command.
if g:TclShellKey != ""
    exec 'nnoremap <silent> ' . g:TclShellKey .
       \ ' :call TclShell#OpenShell()<cr>'
    exec 'vnoremap <silent> ' . g:TclShellKey .
       \ " y:call TclShell#OpenShell('<C-R>" . '"' . "')<cr>"
endif
command! -nargs=? TclShell :call TclShell#OpenShell(<f-args>)
