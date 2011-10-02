" =============================================================================
" File:         TclShell.vim (Plugin)
" Last Changed: Sun, Sep 25, 2011
" Maintainer:   Lorance Stinson AT Gmail...
" License:      Public Domain
"
" Description:  Setup the keys to call TclShell.
"               The rest of the code is autoloaded when/if needed.
"
" Usage:        Execute :TclShell or type <Leader>tcl
"               (Leader is normally '\')
"               Ctrl-L clears the display.
"
" Installation: Copy the files to your ~/.vim or ~/vimfiles dorectory.
"               If using a package manager like pathogen place the whole
"               directory in the bundle directory.
"
" Note:         Can only enter one line of code.
"               Pressing Enter executes the code.
" =============================================================================

if v:version < 700
    echoerr 'TclShell requires Vim 7 or later.'
    finish
elseif exists("g:loadedTclShell") || &cp || !has('tcl')
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
