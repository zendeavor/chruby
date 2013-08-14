# the sugar syntax
function chruby {
  typeset o colored optstring=:hV ver=0.3.6
# {{{ uninteresting details
  [[ $1 == --* ]] && set -- "${1#-}" "${@:2}"
  if { getopts $optstring o; } 2>/dev/null; then
    case $o in
      h)
	printf '%s\n' "usage: chrubylib [RUBY|VERSION|system] [RUBYOPTS]" >&2
	return
      ;;
      V)
	printf '%s\n' "chrubylib version: $ver" >&2
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

# vim: ft=sh sts=2 sw=2 fdm=marker
