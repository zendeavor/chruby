function chruby_set_preexec {
  typeset hook=()
  if [[ $1 == -r ]]; then
    precmd_functions=(${precmd_functions//chruby_auto})
    preexec_functions=(${preexec_functions//chruby_auto})
    return
  fi
  if {
    [[ $precmd_functions == *chruby_auto* ]] \
    || [[ $preexec_functions == *chruby_auto* ]]
  }; then
    chruby_preexec_zsh_set -r
  fi
  if [[ -o interactive ]]; then
    precmd_functions+=(chruby_auto)
  else
    preexec_functions+=(chruby_auto)
  fi
}
. /etc/profile.d/chruby.sh

