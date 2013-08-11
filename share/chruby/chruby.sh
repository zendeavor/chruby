chruby_version="0.3.6"

## utility functions
function chruby_color_set {
  if [[ -t 2 ]]; then
    if tput setaf 0 >/dev/null 2>&1; then
      chruby_coff=$(tput sgr0)
      chruby_bold=$(tput bold)
      chruby_red=${chruby_bold}$(tput setaf 1)
      chruby_green=${chruby_bold}$(tput setaf 2)
      chruby_yellow=${chruby_bold}$(tput setaf 3)
      chruby_blue=${chruby_bold}$(tput setaf 4)
    else
      chruby_coff="\e[1;0m"
      chruby_bold="\e[1;1m"
      chruby_red="${chruby_bold}\e[1;31m"
      chruby_green="${chruby_bold}\e[1;32m"
      chruby_yellow="${chruby_bold}\e[1;33m"
      chruby_blue="${chruby_bold}\e[1;34m"
    fi
  fi
}

function chruby_env_path_set {
  typeset -a paths
  typeset n IFS=:
  while read -r paths[n++]; do :; done <<<"$PATH"
  paths=("${paths[@]//$RUBY_ROOT\/bin}")
  paths=("${paths[@]//$GEM_HOME\/bin}")
  PATH=${paths[*]}




  PATH=:$PATH:
  PATH=${PATH//:$RUBY_ROOT\/bin:/:}
  PATH=${PATH//:$GEM_HOME\/bin:/:}
  PATH=${PATH#:}
  PATH=${PATH%:}
  PATH=$GEM_HOME/bin${GEM_ROOT:+:$GEM_ROOT/bin}:$RUBY_ROOT/bin:$PATH
}

function chruby_env_gempath_set {
  GEM_HOME=$HOME/.gem/$RUBY_ENGINE/$RUBY_VERSION
  GEM_PATH=:$GEM_PATH:
  GEM_PATH=${GEM_PATH//:$GEM_HOME:/:}
  GEM_PATH=${GEM_PATH//:$GEM_ROOT:/:}
  GEM_PATH=${GEM_PATH#:}
  GEM_PATH=${GEM_PATH%:}
  GEM_PATH=$GEM_HOME${GEM_ROOT:+:$GEM_ROOT}${GEM_PATH:+:$GEM_PATH}
}

function chruby_env_set {
  typeset env ruby_opt=${*:2}
  RUBY_ROOT=${1:-$sys_ruby_root}
  RUBYOPT=${ruby_opt:-$RUBYOPT}
  while read -r env; do
    typeset "$env"
  done < <("$RUBY_ROOT"/bin/ruby - <<\EOR
begin; require 'rubygems'; rescue LoadError; end
puts "RUBY_ENGINE=#{defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'}"
puts "RUBY_VERSION=#{RUBY_VERSION}"
puts "RUBY_PATCHLEVEL=#{RUBY_PATCHLEVEL}"
puts "GEM_ROOT=#{Gem.default_dir.inspect}" if defined?(Gem)
EOR
)
  chruby_env_gempath_set
  chruby_env_path_set
  hash -r
}

function chruby_default_rubies_set {
  typeset dir
  RUBIES=()
  for dir in "$PREFIX"/opt/rubies/* "$HOME"/.rubies/*; do
    [[ -e $dir && -x $dir/bin/ruby ]] && RUBIES+=("$dir")
  done
}

function chruby_default_set {
  RUBY_ROOT=$(command -v ruby)
  RUBY_ROOT=${RUBY_ROOT%/bin/*}
  sys_ruby_root=$RUBY_ROOT
  ((${#RUBIES[@]})) || chruby_default_rubies_set
  chruby_env_set
}

function chruby_use {
  typeset ruby_opt=${*:2}
  RUBYOPT=${ruby_opt:-$RUBYOPT}
  chruby_env_set
}

function chruby_auto {
  typeset dir stop ver
  [[ ${dir:=$PWD} == ${stop:=${HOME%/*}}* ]] || return
  while [[ -n $dir ]]; do
    if { IFS= read -r ver <"$dir"/.ruby-version; } 2>/dev/null; then
      chruby "$ver"
      break
    fi
    dir=${dir%/*}
  done
  chruby_env_set
}

## user functions
function chruby {
  typeset match msg colored IFS= arg=$1; shift
  case $arg in
    -h|--help)
      printf '%s\n' "usage: chruby [RUBY|VERSION|system] [RUBY_OPTS]"
      return
    ;;
    -V|--version)
      printf '%s\n' "chruby version: $chruby_version"
      return
    ;;
    '')
      colored=${chruby_blue}*${chruby_coff}
      colored=" ${colored}${chruby_green}$RUBY_ROOT${chruby_off}"
      printf '%s\n' "${RUBIES[@]/#$RUBY_ROOT/$colored}"
    ;;
    system)
      chruby_default_set
    ;;
    *)
      msg="Unknown ruby: $arg"
      ## store in tmp var: collapsing into scalar
      tmp=${RUBIES[*]/#/ }
      ## cut from right: from $arg to end
      # /home/me/RUBIES/ruby-ver-p420 /home/me/RUBIES/ruby-
      begin_tmp=${tmp%$arg*}
      ## ensure there was a match or die
      ((${#tmp} >= ${#begin_tmp})) || { printf '%s\n' "$msg"; return 2; }
      ## yank out the leading junk
      # home/me/RUBIES/ruby-
      begin=${begin_tmp##* /}
      ## cut from left: from begin to $arg
      # -p448
      end_tmp=${tmp##*$arg}
      ## if $arg was the trailing substring of a ruby dir, $end_tmp will
      ## contain *all* of the other rubies. so strip those.
      end=${end_tmp%% /*}
      ## rebuild pieces $begin + $arg + $end
      # /home/me/RUBIES/ruby-1.9.3-p448
      match=/${begin}${arg}${end}

      chruby_use "$match" "$@" || { printf '%s\n' "$msg"; return 2; }
    ;;
  esac
}

function chruby_preexec_set {
  chruby_preexec_${chruby_sh}_set $1
}

## setup
if (($#)); then
  optstring=:acd
  while getopts $optstring o; do
    case $o in
      a) enable_auto=1;;
      c) enable_color=1;;
      d) enable_defaults=1;;
    esac
  done
fi

((enable_color)) && chruby_color_set
((enable_auto)) && chruby_preexec_set
((enable_defaults)) && chruby_default_set

unset ruby_auto_version optstring o \
  enable_auto enable_color enable_defaults
export GEM_HOME GEM_PATH \
	RUBY_ENGINE RUBY_VERSION RUBY_PATCHLEVEL RUBY_ROOT RUBYOPT

