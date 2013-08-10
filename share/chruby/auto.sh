unset ruby_auto_version

chruby_auto() {
  typeset dir=$PWD version

  until [[ $dir/ == / ]]; do
    if { IFS= read -r version <"$dir"/.ruby-version; } 2>/dev/null; then
      [[ $version == $ruby_auto_version ]] && return
	ruby_auto_version=$version
	chruby "$version"
	return
    fi
    dir=${dir%/*}
  done

  [[ $ruby_auto_version ]] && chruby_reset
}

if [[ $ZSH_VERSION ]]; then
  if [[ $preexec_functions != *chruby_auto* ]]; then
    preexec_functions+=(chruby_auto)
  fi
elif [[ $BASH_VERSION ]]; then
  trap '[[ $BASH_COMMAND != "$PROMPT_COMMAND" ]] && chruby_auto' DEBUG
fi
