# {{{ hook parser
function chrubylib_parse_hook {
  typeset n hook=() IFS=
  IFS=\'\; read -ra hook <<<"$1"
  ((${#hook[@]}>1)) && ((n=${#hook[@]}-1))
  [[ ${hook[0]} == "trap -- " ]] && unset hook[0]
  [[ ${hook[n]} == " DEBUG" ]] && unset hook[n]
  hook=("${hook[@]}")
  # declare -p hook >&2
  hook=("${hook[@]//\;\;/\;}")
  [[ ${hook[0]} ]] && printf '%s\n' "${hook[*]/%/;}"
} # }}}

# {{{ hook remover
function chrubylib_remove_hook {
  typeset func=$1 hook=$2
  # declare -p hook
  if [[ $- == *i* ]]; then
    PROMPT_COMMAND=${hook//$func\;}
  else
    trap "${hook//$func\;}" DEBUG
  fi
} # }}}

# {{{ hook adder
function chrubylib_add_hook {
  typeset func=$1 hook=$2
  if [[ $- == *i* ]]; then
    PROMPT_COMMAND="$hook$func"
  else
    trap "$hook$func" DEBUG
  fi
} # }}}

# {{{ sugar syntax wrapper
function chrubylib_set_hook {
  typeset hook func=$1 trap=$(trap -p DEBUG)
  if [[ $- == *i* && ${PROMPT_COMMAND+_} ]]; then
    hook=$(chrubylib_parse_hook "$PROMPT_COMMAND")
    chrubylib_remove_hook "$func" "$hook"
    hook=$(chrubylib_parse_hook "$PROMPT_COMMAND")
    chrubylib_add_hook "$func" "$hook"
  else
    hook=$(chrubylib_parse_hook "$trap")
    trap -p DEBUG
    chrubylib_remove_hook "$func" "$hook"
    trap -p DEBUG
    hook=$(chrubylib_parse_hook "$(trap -p DEBUG)")
    chrubylib_add_hook "$func" "$hook"
  fi
} # }}}

: "${PROMPT_COMMAND:=${PROMPT_COMMAND:-}}"
shopt -s extglob
set -T
# . /etc/profile.d/chruby.sh

# vim: ft=sh sts=2 sw=2 fdm=marker
