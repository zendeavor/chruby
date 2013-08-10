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

function chruby_env_set {
  typeset env
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
}

function chruby_default_set {
  typeset dir
  RUBIES=()
  for dir in "$PREFIX"/opt/rubies/* "$HOME"/.rubies/*; do
    [[ -e $dir && -d $dir/bin ]] && RUBIES+=("$dir")
  done
  RUBY_ROOT=$(command -v ruby)
  sys_ruby_root=${RUBY_ROOT%/bin/*}
  chruby_env_set
}

function chruby_reset {
  [[ $RUBY_ROOT == $sys_ruby_root ]] && return 3

  PATH=:$PATH:
  PATH=${PATH//:$RUBY_ROOT\/bin:/:}
  PATH=${PATH//:$GEM_HOME\/bin:/:}
  PATH=${PATH//:$GEM_HOME\/bin:/:}
  PATH=${PATH#:}
  PATH=${PATH%:}

  GEM_PATH=:$GEM_PATH:
  GEM_PATH=${GEM_PATH//:$GEM_HOME:/:}
  GEM_PATH=${GEM_PATH//:$GEM_ROOT:/:}
  GEM_PATH=${GEM_PATH#:}
  GEM_PATH=${GEM_PATH%:}

  chruby_env_set
  hash -r
}

function chruby_use {
  typeset ruby_exe=$1/bin/ruby env
  RUBY_ROOT=$1 RUBYOPT=${*:2}

  chruby_reset

  chruby_env_set

  GEM_HOME=$HOME/.gem/$RUBY_ENGINE/$RUBY_VERSION
  GEM_PATH=$GEM_HOME${GEM_ROOT:+:$GEM_ROOT}${GEM_PATH:+:$GEM_PATH}
  PATH=$GEM_HOME/bin${GEM_ROOT:+:$GEM_ROOT/bin}:$RUBY_ROOT/bin:$PATH
}

function chruby_auto {
  typeset dir=$PWD version
  until [[ $dir/ == / ]]; do
    if { IFS= read -r version <"$dir"/.ruby-version; } 2>/dev/null; then
      [[ $version == $ruby_auto_version ]] && break
	ruby_auto_version=$version
	chruby "$version"
	return
    fi
    dir=${dir%/*}
  done
  chruby_reset
}

## user functions
function chruby {
  typeset match IFS= arg=$1; shift
  case $arg in
    -h|--help)
      chruby_die 0 "usage: chruby [RUBY|VERSION|system] [RUBY_OPTS]"
    ;;
    -V|--version)
      chruby_die 0 chruby version: $chruby_version
    ;;
    "")
      colored=${chruby_green}$RUBY_ROOT${chruby_off}
      printf '%s\n' "${RUBIES[@]/#$RUBY_ROOT/$colored}"
    ;;
    system)
      chruby_reset
    ;;
    *)
      msg="Unknown ruby: $arg"
      ## store in tmp var: collapsing into scalar
      tmp=${RUBIES[*]/#/ }
      ## cut from right: from $arg to end
      # /home/me/RUBIES/ruby-ver-p420 /home/me/RUBIES/ruby-
      begin_tmp=${tmp%$arg*}
      ## ensure there was a match or die
      ((${#tmp} >= ${#begin_tmp})) || { chruby_die 2 $msg; return; }
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

      chruby_use "$match" "$@" || chruby_die 2 $msg
    ;;
  esac
}

function chruby_preexec_set {
  case ${0##*/} in
    bash) chruby_preexec_bash_set;;
    zsh) chruby_preexec_zsh_set;;
    ?ksh) chruby_preexec_ksh_set;;
  esac
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

