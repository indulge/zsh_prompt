# ~/.prompt/init.zsh — a tiny, dependency-free, themeable zsh prompt engine.
# No frameworks, no plugins. Just zsh builtins + small theme scripts.
#
#   Switch theme:   prompt-theme <name>
#   List / preview: prompt-theme        (or: prompt-theme gallery)
#   Surprise me:    prompt-theme random
#
# Themes live in $PROMPT_HOME/themes/*.zsh and self-register.

[[ -o interactive ]] || return

# Resolve the directory this file lives in (so it works from any install path).
typeset -g PROMPT_HOME="${${(%):-%x}:A:h}"

zmodload -F zsh/datetime b:strftime 2>/dev/null
zmodload zsh/datetime 2>/dev/null
autoload -Uz add-zsh-hook vcs_info
setopt PROMPT_SUBST

# Courtesy: unhook a previous hand-rolled prompt from this repo's older setup
# so we don't pay for duplicate git/timer work. No-ops if they don't exist.
add-zsh-hook -d precmd  _prompt_precmd      2>/dev/null
add-zsh-hook -d precmd  _cmd_timer_precmd   2>/dev/null
add-zsh-hook -d preexec _cmd_timer_preexec  2>/dev/null

typeset -gA _prompt_themes _prompt_samples
typeset -g  _prompt_current=''

# ── git status (computed once per prompt, rendered by the active theme) ──────
zstyle ':vcs_info:*'     enable git
zstyle ':vcs_info:git:*' check-for-changes false
zstyle ':vcs_info:git:*' formats       '%b'
zstyle ':vcs_info:git:*' actionformats '%b|%a'

typeset -g _pr_branch _pr_dirty _pr_ahead _pr_behind _pr_stash

_prompt_gitinfo() {
    _pr_branch='' _pr_dirty='' _pr_ahead=0 _pr_behind=0 _pr_stash=0
    [[ -n $vcs_info_msg_0_ ]] || return
    _pr_branch=$vcs_info_msg_0_
    [[ -n "$(command git status --porcelain 2>/dev/null)" ]] && _pr_dirty=1
    local ab; ab=$(command git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
    if [[ -n $ab ]]; then _pr_ahead=${ab%%$'\t'*}; _pr_behind=${ab##*$'\t'}; fi
    _pr_stash=$(command git rev-list --walk-reflogs --count refs/stash 2>/dev/null) || _pr_stash=0
}

# Themes call this to render the git segment in their own accent colors:
#   _pr_gitstr <color:on-word> <color:branch> [<color:alert>]
_pr_gitstr() {
    [[ -n $_pr_branch ]] || return
    local con=$1 cbr=$2 cal=${3:-197}
    print -n " %F{$con}on %F{$cbr}${_pr_branch}%f"
    [[ -n $_pr_dirty ]]  && print -n " %F{$cal}●%f"
    (( _pr_ahead ))      && print -n " %F{$cbr}⇡${_pr_ahead}%f"
    (( _pr_behind ))     && print -n " %F{$cal}⇣${_pr_behind}%f"
    (( _pr_stash ))      && print -n " %F{$con}≡${_pr_stash}%f"
}

# Themes call this in RPROMPT to render the timer in their own accent color:
#   $(_pr_timestr <color>)   (empty unless the last command took a while)
_pr_timestr() {
    [[ -n $_pr_elapsed ]] || return
    print -n "%F{$1}⏱ ${_pr_elapsed}%f "
}

# ── command timer (self-contained) ──────────────────────────────────────────
typeset -g _pr_start _pr_elapsed
_prompt_timer_pre()  { _pr_start=$EPOCHREALTIME }
_prompt_timer_post() {
    _pr_elapsed=''
    [[ -n $_pr_start ]] || return
    local e=$(( EPOCHREALTIME - _pr_start )); unset _pr_start
    (( e >= 2 )) || return
    local s=${e%.*}
    if   (( s >= 3600 )); then _pr_elapsed=$(printf '%dh%dm'  $((s/3600)) $((s%3600/60)))
    elif (( s >= 60 ));   then _pr_elapsed=$(printf '%dm%02ds' $((s/60))  $((s%60)))
    else                       _pr_elapsed=$(printf '%ds' $s); fi
}

# ── precmd orchestration (order matters: capture $? first) ───────────────────
typeset -g _pr_last
_prompt_precmd_main() { _pr_last=$?; vcs_info; _prompt_gitinfo; }
add-zsh-hook precmd  _prompt_precmd_main
add-zsh-hook preexec _prompt_timer_pre
add-zsh-hook precmd  _prompt_timer_post

# ── load all themes ─────────────────────────────────────────────────────────
() {
    local f
    for f in "$PROMPT_HOME"/themes/*.zsh(N); do source "$f"; done
}

# ── colorful ASCII-art startup banner ───────────────────────────────────────
[[ -r "$PROMPT_HOME/banner.zsh" ]] && source "$PROMPT_HOME/banner.zsh"
: ${PROMPT_BANNER:=1}
(( PROMPT_BANNER )) && typeset -f prompt-banner >/dev/null && prompt-banner

# ── theme switching ─────────────────────────────────────────────────────────
_prompt_use() {
    local name=$1
    if [[ -z ${_prompt_themes[$name]} ]]; then
        print -u2 "prompt-theme: unknown theme '$name'"; _prompt_list; return 1
    fi
    _prompt_apply_$name
    _prompt_current=$name
    print -r -- "$name" > "$PROMPT_HOME/current" 2>/dev/null
}

_prompt_list() {
    print -P "%B%F{045}Available prompt themes%f%b  (current: %F{213}${_prompt_current:-none}%f)\n"
    local name
    for name in ${(ok)_prompt_themes}; do
        local mark=' '; [[ $name == $_prompt_current ]] && mark='%F{046}✓%f'
        print -P "  ${mark} %F{213}$(printf '%-11s' $name)%f ${_prompt_themes[$name]}"
    done
    print -P "\n  %F{242}prompt-theme <name> | gallery | random%f"
}

_prompt_gallery() {
    print -P "\n%B%F{045}✦ prompt.sh theme gallery ✦%f%b\n"
    local name
    for name in ${(ok)_prompt_themes}; do
        print -P "%F{242}── %f%B%F{213}${name}%f%b %F{242}${_prompt_themes[$name]}%f"
        print -P "${_prompt_samples[$name]}\n"
    done
}

prompt-theme() {
    case ${1:-list} in
        list|'')  _prompt_list ;;
        gallery)  _prompt_gallery ;;
        random)   local -a k=(${(k)_prompt_themes}); _prompt_use ${k[$((RANDOM % $#k + 1))]} ;;
        *)        _prompt_use "$1" ;;
    esac
}
compdef '_arguments "1:theme:(list gallery random ${(k)_prompt_themes})"' prompt-theme 2>/dev/null

# ── activate saved theme (or default) ───────────────────────────────────────
[[ -f "$PROMPT_HOME/current" ]] && _prompt_current=$(<"$PROMPT_HOME/current")
[[ -n ${_prompt_themes[$_prompt_current]} ]] || _prompt_current=candy
_prompt_apply_$_prompt_current
