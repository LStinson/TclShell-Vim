# vim:foldmethod=marker
# ============================================================================
# File:         TclShell.tcl (Autoload)
# Last Changed: Fri, Dec 30, 2011
# Maintainer:   LoranceStinson@gmail.com
# License:      Public Domain
#
# Description:  The Tcl parts of TclShell.
#               Loaded from autoload/TclShell.vim
# ============================================================================

# Only define the procedures once.
if {[info procs ::_TclShellEval] eq ""} {

    # _TclShellAppend -- Append text to the TclShell buffer.
    #
    # Arguments:
    #   $text       The text to append to the buffer.
    #
    # Result:
    #   Empty String.
    #
    # Side effect:
    #   The text is appended to _TclShellOutput
    proc _TclShellAppend {text} {
        # Get the current buffer.
        set buf $::vim::current(buffer)

        # Append the text.
        foreach line [split $text "\n\r"] {
            $buf append end $line
        }
    }

    # _TclShellPuts -- Send output to the TclShell buffer.
    #   Appends the output to the global variable _TclShellOutput or to the
    #   TclShell buffer depending on the presence of -noewline.
    #
    #   If any channel other than 'stdout' is specified uses the real puts that
    #   writes a Vim message or error.
    #
    # Arguments:
    #   Normal 'puts' arguments.
    #
    # Result:
    #   Empty String.
    #
    # Side effect:
    #   Output is appended to _TclShellOutput
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
        if {$argc > 1 && [lindex $args 0] != "stdout"} {
            append result $newline
            _TclShellPutsReal -nonewline [lindex $args 0] $result
            return ""
        }
        append _TclShellOutput $result
        if {$newline ne ""} {
            _TclShellAppend $_TclShellOutput
            set _TclShellOutput ""
        }
        return ""
    }

    # _TclShellEval -- Evaluates Tcl code.
    #   Reads Tcl code from the TclShell buffer.
    #   The results and output are placed back into the buffer.
    #
    # Arguments:
    #   None
    #
    # Result:
    #   None
    #
    # Side effect:
    #   The TclShell buffer is modified.
    proc ::_TclShellEval {} {
        # Temporarily replace 'puts' with a special one.
        rename puts _TclShellPutsReal
        rename _TclShellPuts puts

        # Initialize the output variable.
        global _TclShellOutput
        set _TclShellOutput ""

        # Get the Tcl code to execute from the TclShell buffer.
        set buf $::vim::current(buffer)
        set command [$buf get end]
        $buf delete end

        # Special handling for variables.
        if {[string index $command 0] eq {$}} {
            set command "return $command"
        }

        # Attempt to evaluate the Tcl code.
        catch {
            uplevel 1 eval [list $command]
        } result

        # Write any held output to the TclShell buffer.
        if {$_TclShellOutput ne ""} {
            _TclShellAppend $_TclShellOutput
        }

        # Write the results of the eval to the TclShell buffer.
        if {$result ne ""} {
            _TclShellAppend $result
        }

        # Do some cleanup.
        rename puts _TclShellPuts
        rename _TclShellPutsReal puts
        unset _TclShellOutput
        return 0
    }

}
