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

function chruby_env_path_clean {
  PATH=:$PATH:
  PATH=${PATH//:$GEM_HOME:/:}
  PATH=${PATH//:$GEM_ROOT:/:}
  PATH=${PATH#:}
  PATH=${PATH%:}
}

function chruby_env_gempath_clean {
  GEM_PATH=:$GEM_PATH:
  GEM_PATH=${GEM_PATH//:$GEM_HOME:/:}
  GEM_PATH=${GEM_PATH//:$GEM_ROOT:/:}
  GEM_PATH=${GEM_PATH#:}
  GEM_PATH=${GEM_PATH%:}
}

function chruby_env_set {
  typeset env ruby_opt=${*:2}
  RUBY_ROOT=${1:-$sys_ruby_root}
  RUBYOPT=${ruby_opt:-$RUBYOPT}
  chruby_env_path_clean
  chruby_env_gempath_clean
  while IFS= read -r env; do
    export "$env"
  done < <("$RUBY_ROOT"/bin/ruby - <<\EOR
begin; require 'rubygems'; rescue LoadError; end
ver, eng, gems =
RUBY_VERSION,
defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby',
defined?(Gem) ? Gem.default_dir : "/usr/lib/#{eng}/gems/#{ver}"
c = 0
puts "RUBY_VERSINFO[#{(c+=1)-1}]=#{eng}"
ver.split('.').each { |v|
puts "RUBY_VERSINFO[#{(c+=1)-1}]=#{v}"
}
puts "RUBY_VERSINFO[#{(c+=1)-1}]=#{RUBY_PATCHLEVEL}"
puts "RUBY_VERSINFO[#{(c+=1)-1}]=#{RUBY_REVISION}"
puts "RUBY_VERSINFO[#{(c+=1)-1}]=#{RUBY_PLATFORM}"
puts "GEM_ROOT=#{gems}"
EOR
)
  GEM_HOME=$HOME/.gem/$RUBY_ENGINE/$RUBY_VERSION
  GEM_PATH=$GEM_HOME${GEM_ROOT:+:$GEM_ROOT}${GEM_PATH:+:$GEM_PATH}
  PATH=$GEM_HOME/bin${GEM_ROOT:+:$GEM_ROOT/bin}:$RUBY_ROOT/bin:$PATH
  hash -r
}

function chruby_default_rubies_set {
  typeset dir
  rubies=()
  for dir in "$rubiesdir"/opt/rubies/* "$HOME"/.rubies/*; do
    [[ -e $dir && -x $dir/bin/ruby ]] && rubies+=("$dir")
  done
}

function chruby_default_set {
  RUBY_ROOT=$(command -v ruby)
  RUBY_ROOT=${RUBY_ROOT%/bin/*}
  sys_ruby_root=$RUBY_ROOT
  chruby_env_set
}

function chruby_auto {
  typeset dir stop ver
  [[ ${dir:=$PWD} == ${stop:=${HOME%/*}}* ]] || return
  until [[ $dir == $stop ]]; do
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
      colored=${chruby_blue}*\ ${chruby_coff}
      colored=${colored}${chruby_green}$RUBY_ROOT${chruby_off}
      printf '%s\n' "${rubies[@]/#$RUBY_ROOT/$colored}"
    ;;
    system)
      chruby_default_set
    ;;
    *)
      msg="Unknown ruby: $arg"
      ## store in tmp var: collapsing into scalar
      tmp=${rubies[*]/#/ }
      ## cut from right: from $arg to end
      # /home/me/rubies/ruby-ver-p420 /home/me/rubies/ruby-
      begin_tmp=${tmp%$arg*}
      ## ensure there was a match or die
      ((${#tmp} >= ${#begin_tmp})) || { printf '%s\n' "$msg"; return 2; }
      ## yank out the leading junk
      # home/me/rubies/ruby-
      begin=${begin_tmp##* /}
      ## cut from left: from begin to $arg
      # -p448
      end_tmp=${tmp##*$arg}
      ## if $arg was the trailing substring of a ruby dir, $end_tmp will
      ## contain *all* of the other rubies. so strip those.
      end=${end_tmp%% /*}
      ## rebuild pieces $begin + $arg + $end
      # /home/me/rubies/ruby-1.9.3-p448
      match=/${begin}${arg}${end}

      chruby_use "$match" "$@" || { printf '%s\n' "$msg"; return 2; }
    ;;
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
      r) enable_rubies=1;;
    esac
  done
fi

((enable_defaults)) && chruby_default_set
((enable_rubies)) && chruby_default_rubies_set
((enable_color)) && chruby_color_set
((enable_auto)) && chruby_preexec_set

unset optstring o \
  enable_auto enable_color enable_defaults enable_rubies
export GEM_HOME GEM_PATH GEMSKIP GEM_SKIP RUBY_ROOT RUBYOPT

