chrubyversion="0.3.6"

## utility functions
function chruby_set_color {
  if [[ -t 2 ]]; then
    if tput setaf 0 >/dev/null 2>&1; then
      chrubycoff=$(tput sgr0)
      chrubybold=$(tput bold)
      chruby_set_red=${chrubybold}$(tput af 1)
      chruby_set_green=${chrubybold}$(tput af 2)
      chruby_set_yellow=${chrubybold}$(tput af 3)
      chruby_set_blue=${chrubybold}$(tput af 4)
    else
      chrubycoff="\e[1;0m"
      chrubybold="\e[1;1m"
      chruby_red="${chrubybold}\e[1;31m"
      chruby_green="${chrubybold}\e[1;32m"
      chruby_yellow="${chrubybold}\e[1;33m"
      chruby_blue="${chrubybold}\e[1;34m"
    fi
  fi
}

function chruby_clean_env_path {
  PATH=:$PATH:
  PATH=${PATH//:$RUBY_ROOT?bin:/:}
  PATH=${PATH//:$GEM_HOME?bin:/:}
  PATH=${PATH//:$GEM_ROOT?bin:/:}
  PATH=${PATH#:}
  PATH=${PATH%:}
}

function chruby_clean_env_gempath {
  GEM_PATH=:$GEM_PATH:
  GEM_PATH=${GEM_PATH//:$GEM_HOME:/:}
  GEM_PATH=${GEM_PATH//:$GEM_ROOT:/:}
  GEM_PATH=${GEM_PATH#:}
  GEM_PATH=${GEM_PATH%:}
}

function chruby_set_env {
  typeset env new_ruby_root=${1%/bin/*} ruby_opt=${*:2}
  chruby_clean_env_path
  chruby_clean_env_gempath
  RUBY_ROOT=${new_ruby_root:-$sys_ruby_root}
  RUBYOPT=${ruby_opt:-$RUBYOPT}
  while IFS= read -r env; do
    export "$env"
  done < <("$RUBY_ROOT"/bin/ruby - <<\EOR
begin; require 'rubygems'; rescue LoadError; end
ver, eng, gems =
RUBY_VERSION,
defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby',
defined?(Gem) ? Gem.default_dir : "/usr/lib/#{eng}/gems/#{ver}"
c = 0
ver.split('.').each { |v|
puts "RUBY_VERSINFO[#{(c+=1)-1}]=#{v}"
}
puts "RUBY_VERSINFO[#{(c+=1)-1}]=#{RUBY_PATCHLEVEL}"
puts "RUBY_VERSINFO[#{(c+=1)-1}]=#{RUBY_REVISION}"
puts "RUBY_VERSINFO[#{(c+=1)-1}]=#{eng}"
puts "RUBY_VERSINFO[#{(c+=1)-1}]=#{RUBY_PLATFORM}"
puts "GEM_ROOT=#{gems}"
EOR
)
  GEM_HOME=$HOME/.gem/$RUBY_ENGINE/$RUBY_VERSION
  GEM_PATH=$GEM_HOME${GEM_ROOT:+:$GEM_ROOT}${GEM_PATH:+:$GEM_PATH}
  PATH=$GEM_HOME/bin${GEM_ROOT:+:$GEM_ROOT/bin}:$RUBY_ROOT/bin:$PATH
  hash -r
}

function chruby_set_default_rubies {
  typeset dir
  rubies=()
  for dir in "$HOME"/.rubies/*; do
    [[ -e $dir && -x $dir/bin/ruby ]] && rubies+=("$dir")
  done
}

function chruby_set_default {
  sys_ruby_root=$(PATH=/usr/local/bin:/usr/bin:/bin command -v ruby)
  sys_ruby_root=${sys_ruby_root%/bin/*}
  chruby_set_env "$sys_rubyroot"
}

function chruby_auto {
  typeset ver dir=$PWD stop=${HOME%/*}
  [[ $dir == $stop* ]] || return
  until [[ $dir == $stop ]]; do
    if { IFS= read -r ver <"$dir"/.ruby-version; } 2>/dev/null; then
      chruby "$ver"
      break
    fi
    dir=${dir%/*}
  done
}

## user functions
function chruby {
  typeset o match colored optstring=:hV rb=${rubies[*]}
  [[ $1 == --* ]] && set -- "${1#-}" "${@:2}"
  if getopts $optstring o; then
    case $o in
      h)
	printf '%s\n' "usage: chruby [RUBY|VERSION|system] [RUBYOPTS]"
	return
      ;;
      V)
	printf '%s\n' "chruby version: $chrubyversion"
	return
      ;;
    esac
    # shift $((OPTIND-1))
  fi
  case $1 in
    '')
      colored=${chruby_blue}*\ ${chrubycoff}
      colored=${colored}${chruby_green}$RUBY_ROOT${chrubyoff}
      printf '%s\n' "${rubies[@]/#$RUBY_ROOT/$colored}"
    ;;
    system)
      chruby_set_default
    ;;
    *)
      while ((rb-- >= 0)); do
	[[ ${rubies[rb]} == *$1* ]] && { match=${rubies[rb]}; break; }
      done
      if [[ -n $match ]]; then
	chruby_set_env "$match" "${@:2}"
      else
	printf '%s\n' "No ruby found for '$1'"
	return 2
      fi

    ;;
  esac
}

## setup
if (($#)); then
  optstring=:acd
  while getopts $optstring o; do
    case $o in
      a) enable_auto=1 ;;
      c) enable_color=1 ;;
      d) enable_defaults=1 ;;
      r) enable_rubies=1 ;;
    esac
  done
fi

((enable_defaults)) && chruby_set_default
((enable_rubies)) && chruby_set_default_rubies
((enable_color)) && chruby_set_color
((enable_auto)) && chruby_set_preexec

unset optstring o \
  enable_auto enable_color enable_defaults enable_rubies
export GEM_HOME GEM_PATH GEMSKIP GEM_SKIP RUBY_ROOT RUBYOPT

