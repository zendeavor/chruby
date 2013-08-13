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
  PATH=${PATH//:$RUBY_ROOT?bin:/:}
  PATH=${PATH//:$GEM_HOME?bin:/:}
  PATH=${PATH//:$GEM_ROOT?bin:/:}
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
  typeset env new_ruby_root=$1 ruby_opt=${*:2}
  chruby_env_path_clean
  chruby_env_gempath_clean
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

function chruby_default_rubies_set {
  typeset dir
  rubies=()
  for dir in "$RUBY_PREFIX"/* "$HOME"/.rubies/*; do
    [[ -e $dir && -x $dir/bin/ruby ]] && rubies+=("$dir")
  done
}

function chruby_default_set {
  sys_ruby_root=$(PATH=/usr/local/bin:/usr/bin:/bin command -v ruby)
  sys_ruby_root=${sys_ruby_root%/bin/*}
  chruby_env_set "$sys_ruby_root"
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
  typeset match msg colored optstring=:hV rb=${rubies[*]}
  [[ $1 == --* ]] && set -- "${1#-}" "${@:2}"
  if getopts $optstring o; then
    case $o in
      h)
	printf '%s\n' "usage: chruby [RUBY|VERSION|system] [RUBY_OPTS]"
	return
      ;;
      V)
	printf '%s\n' "chruby version: $chruby_version"
	return
      ;;
    esac
  fi
  case $1 in
    '')
      colored=${chruby_blue}*\ ${chruby_coff}
      colored=${colored}${chruby_green}$RUBY_ROOT${chruby_off}
      printf '%s\n' "${rubies[@]/#$RUBY_ROOT/$colored}"
    ;;
    system)
      chruby_default_set
    ;;
    *)
      while ((rb-- >= 0)); do
	[[ ${rubies[rb]} == *$1* ]] && { match=${rubies[rb]}; break; }
      done
      if [[ -n $match ]]; then
	chruby_env_set "$match" "${@:2}"
      else
	printf '%s\n' "$msg"
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
export GEM_HOME GEM_PATH GEMSKIP GEM_SKIP RUBY_ROOT RUBYOPT RUBY_PREFIX

