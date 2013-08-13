function chruby_set_preexec {
  typeset hook=()
  typeset trap=$(trap -p DEBUG)
  if [[ $1 == -r ]]; then
    PROMPT_COMMAND=${PROMPT_COMMAND//chruby_auto?}
    IFS=\' read -ra hook <<<"$trap"
    IFS=\; read -ra hook <<<"${hook[@]:1:${#hook[@]}-2}"
    trap "${hook[@]//chruby_auto?(;)}" DEBUG
    return
  fi
  if {
      [[ $PROMPT_COMMAND == *chruby_auto* ]] \
	|| [[ $trap == *chruby_auto* ]];
  }; then
    chruby_set_preexec -r
  fi
  if [[ $- == *i* ]]; then
    IFS=\; read -ra hook <<<"$PROMPT_COMMAND"
    PROMPT_COMMAND="${hook[@]/%/;} chruby_auto"
    PROMPT_COMMAND="${PROMPT_COMMAND#;}"
  else
    IFS=\' read -ra hook <<<"$trap"
    IFS=\; read -ra hook <<<"${hook[@]:1:${#hook[@]}-2}"
    trap "${hook[@]/%/;} chruby_auto" DEBUG
  fi
}
shopt -s extglob
. /etc/profile.d/chruby.sh

