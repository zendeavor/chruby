function chruby_set_preexec {
  typeset hook=()
  typeset trap=$(trap -p DEBUG)
  # {{{ hook removal
  if [[ $1 == -r ]]; then
    PROMPT_COMMAND=${PROMPT_COMMAND//chruby_auto?}
    IFS=\' read -ra hook <<<"$trap"
    IFS=\; read -ra hook <<<"${hook[@]:1:${#hook[@]}-2}"
    trap "${hook[@]//chruby_auto?(;)}" DEBUG
    return
  fi
  # }}}
  # {{{ hook detect && remove
  if {
      [[ $PROMPT_COMMAND == *chruby_auto* ]] \
	|| [[ $trap == *chruby_auto* ]];
  }; then
    chruby_set_preexec -r
  fi
  # }}}
  # {{{1 hook add
  # {{{2 interactive shells
  if [[ $- == *i* ]]; then
    IFS=\; read -ra hook <<<"$PROMPT_COMMAND"
    PROMPT_COMMAND="${hook[@]/%/;} chruby_auto"
    PROMPT_COMMAND="${PROMPT_COMMAND#;}"
  # 2}}}
  else
  # {{{2 non-interactive shells
    IFS=\' read -ra hook <<<"$trap"
    IFS=\; read -ra hook <<<"${hook[@]:1:${#hook[@]}-2}"
    trap "${hook[@]/%/;} chruby_auto" DEBUG
  # 2}}}
  fi
  # 1}}}
}
shopt -s extglob
. /etc/profile.d/chruby.sh

# vim: ft=sh sts=2 sw=2 fdm=marker
