# the sugar syntax
function chruby {
    typeset o usage version colored optstring=:hV ver=0.3.6
# {{{ uninteresting details
    [[ $1 == --* ]] && set -- "${1#-}" "${@:2}"
    if { getopts $optstring o; } 2>/dev/null; then
	case $o in
	    h)
		usage="usage: chrubylib [RUBY|VERSION|system] [RUBYOPTS]"
		printf '%s\n' "$usage" >&2
		return
	    ;;
	    V)
		version="chrubylib version: $ver"
		printf '%s\n' "$version" >&2
		return
	    ;;
	esac
    fi
# }}}
    case $1 in
	'')
	    colored=${chruby_blue}*\ ${chruby_coff}
	    colored=${colored}${chruby_green}$RUBY_ROOT${chruby_off}
	    printf '%s\n' "${rubies[@]/#$RUBY_ROOT/$colored}"
	;;
	system|default)
	    chrubylib_set_default
	;;
	*)
	    chrubylib_fuzzy_match "$1"
	;;
    esac
}

## setup
. /usr/share/chruby/chrubylib "$@"

# vim: ft=sh sts=4 sw=4 fdm=marker
