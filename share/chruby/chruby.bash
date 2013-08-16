# {{{ hook parser
function chrubylib_parse_hook {
    typeset n hook=() IFS=\;
    IFS=\'\; read -ra hook <<<"$1"
    ((${#hook[@]}>1)) && ((n=${#hook[@]}-1))
    [[ ${hook[0]} == "trap -- " ]] && unset hook[0]
    [[ ${hook[n]} == " DEBUG" ]] && unset hook[n]
    hook=("${hook[@]}")
    declare -p hook
    [[ ${hook[0]} ]] && printf '%s' "${hook[*]}"
} # }}}

# {{{ hook remover
function chrubylib_remove_hook {
    typeset func=$1 hook=$2
    if [[ $- == *i* ]]; then
	PROMPT_COMMAND=${PROMPT_COMMAND//$func\;}
    else
	trap "${hook//$func?(;)}" DEBUG
    fi
} # }}}

# {{{ hook adder
function chrubylib_add_hook {
    typeset func=$1 hook=$2
    if [[ $- == *i* ]]; then
	PROMPT_COMMAND="$hook$func"
    else
	hook=${hook#+(\;)}
	hook=${hook:+${hook:-}}
	trap "$hook$func" DEBUG
    fi
} # }}}

# {{{ sugar syntax wrapper
function chrubylib_set_hook {
    typeset hook func=$1 trap=$(trap -p DEBUG)
    if [[ $- == *i* && ]]; then
	if [[ $PROMPT_COMMAND == *"$func"* ]]; then
	    chrubylib_remove_hook "$func" "$PROMPT_COMMAND"
	fi
	hook=$(chrubylib_parse_hook "$PROMPT_COMMAND")
	chrubylib_add_hook "$func" "$hook"
    else
	if [[ $trap == *"$func"* ]]; then
	    hook=$(chrubylib_parse_hook "$trap")
	    chrubylib_remove_hook "$func" "$hook"
	fi
	trap=$(trap -p DEBUG)
	hook=$(chrubylib_parse_hook "$trap")
	chrubylib_add_hook "$func" "$hook"
    fi
} # }}}

: "${PROMPT_COMMAND:=${PROMPT_COMMAND:-}}"
shopt -s extglob
set -T
# . /etc/profile.d/chruby.sh

# vim: ft=sh sts=4 sw=4 fdm=marker
