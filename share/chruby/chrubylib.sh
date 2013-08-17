# {{{ safely set up some colors or fallback on raw escapes
function chrubylib_set_color {
    if [[ -t 2 ]]; then
	if tput setaf 0 >/dev/null 2>&1; then
	    chruby_coff=$(tput sgr0)
	    chruby_bold=$(tput bold)
	    chruby_red=${chruby_bold}$(tput af 1)
	    chruby_green=${chruby_bold}$(tput af 2)
	    chruby_yellow=${chruby_bold}$(tput af 3)
	    chruby_blue=${chruby_bold}$(tput af 4)
	else
	    chruby_coff="\e[1;0m"
	    chruby_bold="\e[1;1m"
	    chruby_red="${chruby_bold}\e[1;31m"
	    chruby_green="${chruby_bold}\e[1;32m"
	    chruby_yellow="${chruby_bold}\e[1;33m"
	    chruby_blue="${chruby_bold}\e[1;34m"
	fi
    fi
} # }}}

# {{{ semi-sanitize paths
function chrubylib_clean_env_path {
    typeset old path=$PATH
    PATH=:$PATH:
    for paths; do
	PATH=${PATH//:$paths\/bin:/:}
    done
    PATH=${PATH#:}
    PATH=${PATH%:}
    [[ $PATH != "$old_path" ]]
} # }}}

# {{{ set some reasonable defaults
function chrubylib_set_default_rubies {
    typeset dir
    { setopt local_options null_glob ksh_arrays; } 2>/dev/null
    rubies=()
    for dir in "$HOME"/.rubies/*; do
	[[ -e $dir && -x $dir/bin/ruby ]] && rubies+=("$dir")
    done
    [[ -n ${rubies[0]} ]]
}

function chrubylib_set_default {
    sys_ruby_root=$(PATH=/usr/local/bin:/usr/bin:/bin command -v ruby)
    sys_ruby_root=${sys_ruby_root%/bin/*}
    chrubylib_set_env "$sys_ruby_root"
} # }}}

# {{{ worker for $SHELL_set_preexec functions
function chruby_auto {
    typeset n ver dir=${1:-$PWD} stop=${HOME%/*}
    [[ $dir == $stop* ]] || return
    until [[ $dir == "$stop" ]] || (( ++n < 10 )); do
	if { IFS= read -r ver <"$dir"/.ruby-version; } 2>/dev/null; then
	    chruby "$ver"
	    break
	fi
	dir=${dir%/*}
    done
} # }}}

# {{{ the fuzzy matcher; reverse array iterator
function chrubylib_fuzzy_match {
    typeset match ruby=$1 rb=${#rubies[*]}
    { setopt local_options ksh_arrays; } 2>/dev/null
    while (( --rb >= 0 )); do
	[[ ${rubies[rb]} == *$ruby* ]] && { match=${rubies[rb]}; break; }
    done
    if [[ -n $match ]]; then
	chrubylib_set_env "$match" "${@:2}"
    else
	printf '%s\n' "No ruby found for '$ruby'" >&2
	return 2
    fi
} # }}}

# {{{ set up the RUBY_VERSINFO array into the env (like BASH_VERSINFO)
# as this is an array, it can't *actually* be put in the env
function chrubylib_set_env_rubyversinfo {
    typeset e env old_rubyvers_info=${RUBY_VERSINFO[@]}
    { setopt local_options ksh_arrays; } 2>/dev/null
    while IFS= read -r env; do
	typeset -g "$env"
    done < <("$RUBY_ROOT"/bin/ruby - <<'EOR'
eng = defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'
ver = RUBY_VERSION
(ver.split('.') + [RUBY_PATCHLEVEL, RUBY_REVISION, eng, RUBY_PLATFORM]
).each_with_index { |v, i| puts "RUBY_VERSINFO[#{i}]=#{v}" }
EOR
)
    [[ ${RUBY_VERSINFO[@]} != "$old_ruby_versinfo" ]]
} # }}}

# {{{ workhorse; sets up the whole environment
function chrubylib_set_env {
    typeset ruby_engine ruby_version new_ruby_root=${1%/bin/*} ruby_opt=${*:2}
    chrubylib_clean_env_path "$RUBY_ROOT" "$GEM_HOME" "$GEM_PATH"
    RUBY_ROOT=${new_ruby_root:-$sys_ruby_root}
    RUBYOPT=${ruby_opt:-$RUBYOPT}
    { setopt local_options ksh_arrays; } 2>/dev/null
    chrubylib_set_env_rubyversinfo
    PATH=$RUBY_ROOT/bin:$GEM_HOME/bin:$PATH
    hash -r
} # }}}

# {{{ infect the shell environment
if (($#)); then
    optstring=:acdr
    while getopts $optstring o; do
	case $o in
	    a) enable_auto=1 ;;
	    c) enable_color=1 ;;
	    d) enable_defaults=1 ;;
	    r) enable_rubies=1 ;;
	esac
    done
fi

((enable_defaults)) && chrubylib_set_default
((enable_rubies)) && chrubylib_set_default_rubies
((enable_color)) && chrubylib_set_color
((enable_auto)) && chrubylib_set_hook

unset optstring o enable_auto enable_color enable_defaults enable_rubies
export GEM_HOME GEM_PATH GEM_SKIP GEM_CACHE GEMCACHE RUBY_ROOT RUBYOPT
# }}}

# vim: ft=sh sts=4 sw=4 fdm=marker
