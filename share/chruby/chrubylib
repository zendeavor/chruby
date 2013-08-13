# {{{1 safely set up some colors or fallback on raw escapes
function chrubylib_set_color {
  if [[ -t 2 ]]; then
    if tput setaf 0 >/dev/null 2>&1; then
      chrubycoff=$(tput sgr0)
      chruby_bold=$(tput bold)
      chruby_red=${chruby_bold}$(tput af 1)
      chruby_green=${chruby_bold}$(tput af 2)
      chruby_yellow=${chruby_bold}$(tput af 3)
      chruby_blue=${chruby_bold}$(tput af 4)
    else
      chrubycoff="\e[1;0m"
      chruby_bold="\e[1;1m"
      chruby_red="${chruby_bold}\e[1;31m"
      chruby_green="${chruby_bold}\e[1;32m"
      chruby_yellow="${chruby_bold}\e[1;33m"
      chruby_blue="${chruby_bold}\e[1;34m"
    fi
  fi
} # 1}}}

# {{{ semi-sanitize paths
function chrubylib_clean_env_path {
  PATH=:$PATH:
  PATH=${PATH//:$RUBY_ROOT\/bin:/:}
  PATH=${PATH//:$GEM_HOME\/bin:/:}
  PATH=${PATH//:$GEM_ROOT\/bin:/:}
  PATH=${PATH#:}
  PATH=${PATH%:}
}

function chrubylib_clean_env_gempath {
  GEM_PATH=:$GEM_PATH:
  GEM_PATH=${GEM_PATH//:$GEM_HOME:/:}
  GEM_PATH=${GEM_PATH//:$GEM_ROOT:/:}
  GEM_PATH=${GEM_PATH#:}
  GEM_PATH=${GEM_PATH%:}
} # }}}

# {{{ set some reasonable defaults
function chrubylib_set_default_rubies {
  typeset dir
  rubies=()
  for dir in "$HOME"/.rubies/*; do
    [[ -e $dir && -x $dir/bin/ruby ]] && rubies+=("$dir")
  done
}

function chrubylib_set_default {
  sys_ruby_root=$(PATH=/usr/local/bin:/usr/bin:/bin command -v ruby)
  sys_ruby_root=${sys_ruby_root%/bin/*}
  chrubylib_set_env "$sys_rubyroot"
} # }}}

# {{{ worker for $SHELL_set_preexec functions
function chruby_auto {
  typeset ver dir=${1:-$PWD} stop=${HOME%/*}
  [[ $dir == $stop* ]] || return
  until [[ $dir == $stop ]]; do
    if { IFS= read -r ver <"$dir"/.ruby-version; } 2>/dev/null; then
      chruby "$ver"
      break
    fi
    dir=${dir%/*}
  done
} # }}}

# {{{ workhorse; sets up the whole environment
function chrubylib_set_env {
  typeset env new_ruby_root=${1%/bin/*} ruby_opt=${*:2}
  chrubylib_clean_env_path
  chrubylib_clean_env_gempath
  RUBY_ROOT=${new_ruby_root:-$sys_ruby_root}
  RUBYOPT=${ruby_opt:-$RUBYOPT}
  while IFS= read -r env; do
    export "$env"
  done < <("$RUBY_ROOT"/bin/ruby - <<\EOR
begin; require 'rubygems'; rescue LoadError; end
eng = defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'
gems = defined?(Gem) ? Gem.default_dir : "/usr/lib/#{eng}/gems/#{ver}"
(RUBY_VERSION.split('.') +
[RUBY_PATCHLEVEL, RUBY_REVISION, eng, RUBY_PLATFORM]
).each_with_index { |v, i| puts "RUBY_VERSINFO[#{i+1}]=#{v}" }
puts "GEM_ROOT=#{gems}"
EOR
)
  GEM_HOME=$HOME/.gem/$RUBY_ENGINE/$RUBY_VERSION
  GEM_PATH=$GEM_HOME${GEM_ROOT:+:$GEM_ROOT}${GEM_PATH:+:$GEM_PATH}
  PATH=$GEM_HOME/bin${GEM_ROOT:+:$GEM_ROOT/bin}:$RUBY_ROOT/bin:$PATH
  hash -r
} # }}}

# {{{ infect the shell environment
if (($#)); then
  optstring=:acdr
  while getopts $optstring o; do
    case $o in
      a) enable_auto=1 ;;
      c) enable_color=1 ;;
      d) enable_defaults=1 ;;
      r) enable_rubies=1 ;;
    esac
  done
fi

((enable_defaults)) && chrubylib_set_default
((enable_rubies)) && chrubylib_set_default_rubies
((enable_color)) && chrubylib_set_color
((enable_auto)) && chrubylib_set_preexec

unset optstring o enable_auto enable_color enable_defaults enable_rubies
export GEM_HOME GEM_PATH GEMSKIP GEM_SKIP RUBY_ROOT RUBYOPT
# }}}

# vim: ft=sh sts=2 sw=2 fdm=marker
