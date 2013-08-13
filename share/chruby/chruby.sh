# the sugar syntax
function chruby {
  typeset o match colored optstring=:hV rb=${rubies[*]} ver=0.3.6
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
      while ((rb-- >= 0)); do
	[[ ${rubies[rb]} == *$1* ]] && { match=${rubies[rb]}; break; }
      done
      if [[ -n $match ]]; then
	chrubylib_set_env "$match" "${@:2}"
      else
	printf '%s\n' "No ruby found for '$1'" >&2
	return 2
      fi

    ;;
  esac
}

## setup
. /usr/share/chruby/chrubylib "$@"

# vim: ft=sh sts=2 sw=2 fdm=marker
