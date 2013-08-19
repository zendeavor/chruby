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

# {{{ split colon-separated list into components
function chrubylib_split_colon_list {
    { setopt local_options ksh_arrays; } 2>/dev/null
    typeset lists elems=() out=()
    for lists; do
        elems=("${lists%%:*}")
        until [[ $lists == "${elems[${#elems[@]}-1]}" ]]; do
            lists=${lists#*:}
            elems+=("${lists%%:*}")
        done
        out+=("${elems[@]}")
    done
    printf '%s\n' "${out[@]}"
} # }}}

# {{{ semi-sanitize paths
function chrubylib_clean_env_paths {
    typeset tail=${1:-/bin} list=$2 paths
    eval "$list=:\$$list:"
    while IFS= read -r paths; do
        eval "$list=\${$list//:\$paths\$tail:/:}"
    done < <(chrubylib_split_colon_list "${@:3}")
    eval "$list=\${list#:}"
    eval "$list=\${list%:}"
    eval [[ "\$$list" != \"$list\" ]]
} # }}}

# {{{ update a path with new bin dirs
function chrubylib_set_env_paths {
    typeset tail=${1:-/bin} list=$2
    while IFS= read -r paths; do
        eval "$list=\$paths\$tail:\$$list"
    done < <(chrubylib_split_colon_list "${@:3}")
    eval [[ "\$$list" != \"$list\" ]]
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

# {{{ set up the new ruby info
function chrubylib_set_env_ruby_info {
    typeset e ruby_root=$1 ruby_opt=${1:-${*:2}} old_ruby_root=$RUBY_ROOT old_ruby_opt=$RUBYOPT
    RUBY_ROOT=${ruby_root:-$def_ruby_root}
    RUBYOPT=${ruby_opt:-$RUBYOPT}
    [[ $RUBY_ROOT != "$old_ruby_root" ]] || e=1
    [[ $RUBYOPT != "$old_ruby_opt" ]] || e+=2
    return $e
} # }}}

# {{{ set up the RUBY_VERSINFO array into the env (like BASH_VERSINFO)
function chrubylib_set_env_ruby_versinfo {
    typeset env old_ruby_versinfo=${RUBY_VERSINFO[@]}
    { setopt local_options ksh_arrays; } 2>/dev/null
    while IFS= read -r env; do
        eval "$env"
    done < <("$RUBY_ROOT"/bin/ruby - <<'EOR'
eng = defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'
(RUBY_VERSION.split('.') + [RUBY_PATCHLEVEL, RUBY_REVISION, eng, RUBY_PLATFORM]
).each_with_index { |v, i| puts "RUBY_VERSINFO[#{i}]=#{v}" }
EOR
)
    [[ ${RUBY_VERSINFO[@]} != "$old_ruby_versinfo" ]]
} # }}}

# {{{ set some reasonable defaults
function chrubylib_set_default {
    def_ruby_root=$(PATH=/usr/local/bin:/usr/bin:/bin command -v ruby)
    def_ruby_root=${def_ruby_root%/bin/*}
    chrubylib_set_env "$def_ruby_root"
}

function chrubylib_set_default_rubies {
    typeset dir
    { setopt local_options null_glob ksh_arrays; } 2>/dev/null
    rubies=()
    for dir in "$HOME"/.rubies/*; do
        [[ -e $dir && -x $dir/bin/ruby ]] && rubies+=("$dir")
    done
    [[ -n ${rubies[0]} ]]
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

# {{{ workhorse; sets up the whole environment
function chrubylib_set_env {
    { setopt local_options ksh_arrays; } 2>/dev/null
    typeset new_ruby_root=${1%/bin/*} ruby_opt=${*:2} env_args=(
                                                            "$RUBY_ROOT"
                                                            "$GEM_HOME"
                                                            "$GEM_PATH"
                                                            )
    chrubylib_clean_env_paths /bin PATH "${env_args[@]}"
    chrubylib_set_env_ruby_info "$new_ruby_root" "$ruby_opt"
    chrubylib_set_env_ruby_versinfo "$new_ruby_root" "$ruby_opt"
    chrubylib_set_env_paths /bin PATH "${env_args[@]}"
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

RUBY_VERSINFO=()
((enable_defaults)) && chrubylib_set_default
((enable_rubies)) && chrubylib_set_default_rubies
((enable_color)) && chrubylib_set_color
((enable_auto)) && chrubylib_set_hook

unset optstring o enable_auto enable_color enable_defaults enable_rubies
export GEM_HOME GEM_PATH GEM_SKIP GEM_CACHE GEMCACHE RUBY_ROOT RUBYOPT
# }}}

# vim: ft=sh sts=4 sw=4 et fdm=marker
