function chrubylib_set_hook {
    typeset hook=()
    # {{{ hook removal
    if [[ $1 == -r ]]; then
	precmd_functions=(${precmd_functions//chruby_auto})
	preexec_functions=(${preexec_functions//chruby_auto})
	return
    fi
    # }}}
    # {{{ hook detection
    if {
	[[ $precmd_functions == *chruby_auto* ]] \
	|| [[ $preexec_functions == *chruby_auto* ]]
    }; then
	chrubylib_set_hook -r
    fi
    # }}}
    # {{{ hook addition
    # {{{ interactive mode
    if [[ -o interactive ]]; then
	precmd_functions+=(chruby_auto)
    # }}}
    # {{{ non-interactive mode
    else
	preexec_functions+=(chruby_auto)
    fi
    # }}}
    # }}}
}
# . /etc/profile.d/chruby.sh "$@"

# vim: ft=zsh sts=4 sw=4 fdm=marker
