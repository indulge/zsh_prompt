# ~/.prompt/init.zsh — a tiny, dependency-free, themeable zsh prompt engine.
# No frameworks, no plugins. Just zsh builtins + small theme scripts.
#
#   Theme panel:    theme               — browse w/ preview, toggle effects
#   Switch theme:   prompt-theme <name>
#   List / preview: prompt-theme        (or: prompt-theme gallery)
#   Surprise me:    prompt-theme random
#   Glow mode:      prompt-theme glow [on|off]
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
    print -n " %F{$con}on %F{$cbr}${_pr_branch//\%/%%}%f"
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

# ── extra segments (each renders nothing when idle) ──────────────────────────
#   _pr_venvstr <color>            python venv / conda env, when active
#   _pr_sshstr <userC> <hostC>     user@host, only over SSH
_pr_venvstr() {
    local v=${VIRTUAL_ENV:t}
    [[ -z $v && -n $CONDA_DEFAULT_ENV ]] && v=$CONDA_DEFAULT_ENV
    [[ -n $v ]] && print -n " %F{$1}🐍 ${v//\%/%%}%f"
}
_pr_sshstr() {
    [[ -n $SSH_CONNECTION || -n $SSH_TTY ]] || return 0
    print -n "%F{$1}%n%f%F{243}@%f%F{$2}%m%f "
}

# ── offline moon phase (pure date arithmetic — no internet, no binaries) ─────
# Sets $_pr_moon_icon (🌑…🌘) and $_pr_moon_name (अमावस्या / शुक्ल पक्ष /
# पूर्णिमा / कृष्ण पक्ष). Anchor: new moon 2000-01-06 18:14 UTC (epoch
# 947182440); synodic month 29.530589 days.
typeset -g _pr_moon_icon _pr_moon_name
_pr_moon() {
    local -F age=$(( (( EPOCHSECONDS - 947182440 ) % 2551443) / 86400.0 ))
    local -i idx=$(( age / 29.530589 * 8 + 0.5 ))
    (( idx %= 8 ))
    local -a icons=(🌑 🌒 🌓 🌔 🌕 🌖 🌗 🌘)
    _pr_moon_icon=${icons[idx+1]}
    # Names stay honest: अमावस्या/पूर्णिमा only within ±1 day of true new/full.
    if   (( age < 1.0 || age > 28.53 ));            then _pr_moon_name='अमावस्या'
    elif (( age > 13.77 && age < 15.77 ));          then _pr_moon_name='पूर्णिमा'
    elif (( age < 14.77 ));                         then _pr_moon_name='शुक्ल पक्ष'
    else                                                 _pr_moon_name='कृष्ण पक्ष'; fi
}
# For prompts: just the icon (changes with the real moon, night after night).
_pr_moonstr() { _pr_moon; print -n "$_pr_moon_icon " }

# ── gradient printer (used by the banner and the shlok art headers) ──────────
# _pr_grad <string> [offset] [ramp colors...]  — per-character 256-color ramp.
typeset -ga _pr_ramp=(196 202 208 214 220 190 154 84 43 45 39 63 99 135 171 207 213)
_pr_grad() {
    local s=$1 off=${2:-0}
    local -a ramp=( ${@[3,-1]} )
    (( ${#ramp} )) || ramp=($_pr_ramp)
    local -i n=${#ramp} i c
    for (( i = 1; i <= ${#s}; i++ )); do
        c=${ramp[ (( (i + off - 1) % n ) + 1 ) ]}
        print -Pn "%F{$c}${s[i]}%f"
    done
    print
}

# ── command timer (self-contained) ──────────────────────────────────────────
typeset -g  _pr_start _pr_elapsed
typeset -gi _pr_elapsed_s
_prompt_timer_pre()  { _pr_start=$EPOCHREALTIME }
_prompt_timer_post() {
    _pr_elapsed='' _pr_elapsed_s=0
    [[ -n $_pr_start ]] || return
    local e=$(( EPOCHREALTIME - _pr_start )); unset _pr_start
    _pr_elapsed_s=${e%.*}
    (( e >= 2 )) || return
    local s=${e%.*}
    if   (( s >= 3600 )); then _pr_elapsed=$(printf '%dh%dm'  $((s/3600)) $((s%3600/60)))
    elif (( s >= 60 ));   then _pr_elapsed=$(printf '%dm%02ds' $((s/60))  $((s%60)))
    else                       _pr_elapsed=$(printf '%ds' $s); fi
}

# ── precmd orchestration (order matters: capture $? first) ───────────────────
# The trail keeps the last 8 real exit codes (empty Enters don't count) —
# themes render it with _pr_trailstr <okColor> <badColor>, and it stays
# invisible while everything succeeds.
typeset -g  _pr_last
typeset -ga _pr_trail
typeset -gi _pr_ran=0
_prompt_precmd_main() {
    _pr_last=$?
    if (( _pr_ran )); then
        _pr_trail+=($_pr_last)
        (( ${#_pr_trail} > 8 )) && _pr_trail=(${_pr_trail[-8,-1]})
        _pr_ran=0
    fi
    vcs_info; _prompt_gitinfo
}
add-zsh-hook precmd  _prompt_precmd_main
add-zsh-hook preexec _prompt_timer_pre
add-zsh-hook precmd  _prompt_timer_post

_pr_trailstr() {
    local -a bad=(${_pr_trail:#0})
    (( ${#bad} )) || return 0
    local x out=''
    for x in $_pr_trail; do
        [[ $x == 0 ]] && out+="%F{$1}·%f" || out+="%F{$2}●%f"
    done
    print -n "$out "
}

# ── session farewell (a little blessing + stats when you leave) ──────────────
# Disable with PROMPT_FAREWELL=0 in your ~/.zshrc before the managed block.
typeset -gi _pr_cmds=0
_prompt_count_cmd() { (( ++_pr_cmds )); _pr_ran=1 }
add-zsh-hook preexec _prompt_count_cmd

# Every 108 commands: one mala of the keyboard. 📿
typeset -gi _pr_mala=0
_prompt_mala() {
    (( _pr_cmds && _pr_cmds % 108 == 0 && _pr_cmds != _pr_mala )) || return 0
    _pr_mala=$_pr_cmds
    local -i n=$(( _pr_cmds / 108 ))
    print -P "  %F{220}📿 एक माला पूर्ण${${n:#1}:+ ×$n}%f %F{243}· ${_pr_cmds} commands this session 🙏%f"
}
add-zsh-hook precmd _prompt_mala

_prompt_farewell() {
    (( ${PROMPT_FAREWELL:-1} )) || return 0
    [[ -o interactive && -t 1 ]] || return 0
    local -i s=$SECONDS
    local dur
    if   (( s >= 3600 )); then dur="$((s/3600))h $((s%3600/60))m"
    elif (( s >= 60 ));   then dur="$((s/60))m $((s%60))s"
    else                       dur="${s}s"; fi
    print -P "\n  %F{213}🙏 धन्यवाद%f %F{243}·%f %F{80}${_pr_cmds} commands%f %F{243}·%f %F{80}${dur}%f %F{243}·%f %F{219}फिर मिलेंगे ✨%f"
}
add-zsh-hook zshexit _prompt_farewell

# ── per-theme file colors (ls / tree / fd / completion listings) ────────────
# Folder names, symlinks & friends follow the theme. Each theme registers:
#   _pr_ls_register <name> <dir> <link> <exec> <special> <broken> <archive> <media>
# (256-color numbers). On switch the palette becomes LS_COLORS plus zsh
# completion list-colors, so `ls`, `tree`, `fd` and tab-completion all match.
typeset -gA _prompt_lscolors
typeset -gi _prompt_glow=0
[[ -f "$PROMPT_HOME/glow" ]] && _prompt_glow=$(<"$PROMPT_HOME/glow")
# full-path display (%~ → %d): the file, when present, overrides the
# PROMPT_FULL_PATHS env default — the `theme` panel toggles it with `p`.
[[ -f "$PROMPT_HOME/fullpaths" ]] && PROMPT_FULL_PATHS=$(<"$PROMPT_HOME/fullpaths")

_pr_ls_register() {
    local n=$1 di=$2 ln=$3 ex=$4 sp=$5 br=$6 ar=$7 me=$8 e
    local L="rs=0:di=1;38;5;${di}:ln=38;5;${ln}:ex=38;5;${ex}"
    L+=":or=9;38;5;${br}:mi=9;38;5;${br}"                            # dangling links: struck out
    L+=":pi=38;5;${sp}:so=38;5;${sp}:bd=38;5;${sp}:cd=38;5;${sp}"    # pipes, sockets, devices
    L+=":su=1;4;38;5;${br}:sg=1;4;38;5;${br}:ca=1;4;38;5;${br}"      # setuid/setgid/capability: loud
    L+=":tw=1;4;38;5;${di}:ow=4;38;5;${di}:st=1;38;5;${di}"          # world-writable dirs: underline, not day-glo bg
    for e in tar tgz zip gz bz2 xz zst 7z rar deb rpm jar iso; do L+=":*.${e}=38;5;${ar}"; done
    for e in jpg jpeg png gif webp svg ico mp4 mkv webm mov mp3 flac ogg wav; do L+=":*.${e}=38;5;${me}"; done
    _prompt_lscolors[$n]=$L
}

_pr_ls_glowed() {   # print an LS_COLORS string with every entry emboldened
    local pair v out=''
    for pair in ${(s.:.)1}; do
        v=${pair#*=}
        [[ $pair == rs=* || $v == '1;'* ]] || v="1;${v}"
        out+="${pair%%=*}=${v}:"
    done
    print -rn -- "${out%:}"
}

_prompt_apply_lscolors() {
    local ls=${_prompt_lscolors[$1]}
    [[ -n $ls ]] || return 0
    (( _prompt_glow )) && ls=$(_pr_ls_glowed "$ls")
    export LS_COLORS=$ls
    zstyle ':completion:*' list-colors ${(s.:.)ls}
}

# glow: strip the theme's own bold toggles, then embolden the whole prompt.
# Runtime segments (git, timer…) only reset color (%f), never bold — so they
# stay lit too.
_prompt_glowify() {
    (( _prompt_glow )) || return 0
    PROMPT="%B${${PROMPT//\%B/}//\%b/}%b"
    RPROMPT="%B${${RPROMPT//\%B/}//\%b/}%b"
}

_pr_ls_swatch() {   # one-line file-color preview, used by the gallery
    local ls=${_prompt_lscolors[$1]}
    [[ -n $ls ]] || return 0
    local -a P=(${(s.:.)ls})
    local di=${${(M)P:#di=*}#di=} ln=${${(M)P:#ln=*}#ln=} ex=${${(M)P:#ex=*}#ex=}
    local or=${${(M)P:#or=*}#or=} ar=${${(M)P:#\*.tar=*}#\*.tar=} me=${${(M)P:#\*.png=*}#\*.png=}
    print -- "  \e[${di}mfolder/\e[0m  \e[${ln}mlink@\e[0m  \e[${ex}mbin*\e[0m  \e[${ar}mpack.tar\e[0m  \e[${me}mimg.png\e[0m  \e[${or}mgone@\e[0m"
}

# ── load all themes ─────────────────────────────────────────────────────────
() {
    local f
    for f in "$PROMPT_HOME"/themes/*.zsh(N); do source "$f"; done
}

# We render venv/conda ourselves (_pr_venvstr) — stop activate scripts from
# prepending their own "(venv)" to the prompt.
export VIRTUAL_ENV_DISABLE_PROMPT=1

# ── session registry + hop (terminal switcher) + theme picker panel ─────────
[[ -r "$PROMPT_HOME/sessions.zsh" ]] && source "$PROMPT_HOME/sessions.zsh"
[[ -r "$PROMPT_HOME/hop.zsh"      ]] && source "$PROMPT_HOME/hop.zsh"
[[ -r "$PROMPT_HOME/menu.zsh"     ]] && source "$PROMPT_HOME/menu.zsh"

# ── colorful ASCII-art startup banner ───────────────────────────────────────
[[ -r "$PROMPT_HOME/banner.zsh" ]] && source "$PROMPT_HOME/banner.zsh"
: ${PROMPT_BANNER:=1}
(( PROMPT_BANNER )) && typeset -f prompt-banner >/dev/null && prompt-banner

# ── श्लोक — offline verses: Gita, Ramayan, Sundarkand, Chalisa ───────────────
# A random verse at startup (PROMPT_SHLOK=0 to disable), `shlok` or Alt-G for
# a fresh one any time.
[[ -r "$PROMPT_HOME/shlok.zsh" ]] && source "$PROMPT_HOME/shlok.zsh"
: ${PROMPT_SHLOK:=1}
(( PROMPT_SHLOK )) && [[ -t 1 ]] && typeset -f shlok >/dev/null && shlok 2>/dev/null

# ── theme switching ─────────────────────────────────────────────────────────
# Apply full path expansion if PROMPT_FULL_PATHS is set
_prompt_expand_paths() {
    if (( PROMPT_FULL_PATHS )); then
        PROMPT=$(printf '%s\n' "$PROMPT" | sed 's/%~/%d/g')
        RPROMPT=$(printf '%s\n' "$RPROMPT" | sed 's/%~/%d/g')
    fi
}

_prompt_use() {
    local name=$1
    if [[ -z ${_prompt_themes[$name]} ]]; then
        print -u2 "prompt-theme: unknown theme '$name'"; _prompt_list; return 1
    fi
    _prompt_apply_$name
    _prompt_expand_paths
    _prompt_glowify
    _prompt_apply_lscolors $name
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
    local glow=''; (( _prompt_glow )) && glow='  %F{220}✨ glow on%f'
    print -P "\n  %F{242}prompt-theme <name> | gallery | random | glow%f${glow}"
}

_prompt_gallery() {
    print -P "\n%B%F{045}✦ prompt.sh theme gallery ✦%f%b\n"
    local name
    for name in ${(ok)_prompt_themes}; do
        print -P "%F{242}── %f%B%F{213}${name}%f%b %F{242}${_prompt_themes[$name]}%f"
        print -P "${_prompt_samples[$name]}"
        _pr_ls_swatch $name
        print
    done
}

prompt-theme() {
    case ${1:-list} in
        list|'')  _prompt_list ;;
        gallery)  _prompt_gallery ;;
        random)   local -a k=(${(k)_prompt_themes}); _prompt_use ${k[$((RANDOM % $#k + 1))]} ;;
        glow)
            case ${2:-toggle} in
                on)  _prompt_glow=1 ;;
                off) _prompt_glow=0 ;;
                *)   (( _prompt_glow ^= 1 )) || : ;;
            esac
            print -r -- $_prompt_glow > "$PROMPT_HOME/glow" 2>/dev/null
            _prompt_use "$_prompt_current"
            if (( _prompt_glow )); then print -P "%F{220}✨ glow on%f — bold prompt & file colors"
            else print -P "%F{242}glow off%f"; fi
            ;;
        *)        _prompt_use "$1" ;;
    esac
}
compdef '_arguments "1:theme:(list gallery random glow ${(k)_prompt_themes})"' prompt-theme 2>/dev/null

# ── activate saved theme (or default) ───────────────────────────────────────
[[ -f "$PROMPT_HOME/current" ]] && _prompt_current=$(<"$PROMPT_HOME/current")
[[ -n ${_prompt_themes[$_prompt_current]} ]] || _prompt_current=candy
_prompt_apply_$_prompt_current
_prompt_expand_paths
_prompt_glowify
_prompt_apply_lscolors $_prompt_current
