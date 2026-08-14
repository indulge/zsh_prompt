# ~/.prompt/init.zsh — a tiny, dependency-free, themeable zsh prompt engine.
# No frameworks, no plugins. Just zsh builtins + small theme scripts.
#
#   Theme panel:    theme               — browse w/ preview, toggle effects
#   Switch theme:   theme <name>
#   List / preview: theme list          (or: theme gallery)
#   Surprise me:    theme random
#   Glow mode:      theme glow [on|off]
#
# Themes live in $PROMPT_HOME/themes/*.zsh and self-register.

[[ -o interactive ]] || return

# Resolve the directory this file lives in (so it works from any install path).
typeset -g PROMPT_HOME="${${(%):-%x}:A:h}"

# Per-machine runtime state (pulse, sadhana, festival stamps) lives in
# sessions/ — git-ignored, so a fresh clone ships without it. Recreate it
# before any module that writes there is sourced.
[[ -d "$PROMPT_HOME/sessions" ]] || command mkdir -p -- "$PROMPT_HOME/sessions" 2>/dev/null

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

# ── glyph set: plain Unicode by default, Nerd Font icons opt-in ─────────────
# `theme nerd on` (persisted in $PROMPT_HOME/nerd, PROMPT_NERD=1 presets it)
# swaps the marks the shared helpers render. Codepoints stay in the ranges
# stable across Nerd Fonts v2/v3: powerline E0Ax, devicons E7xx, FA F0xx.
typeset -gA _pr_g
typeset -gi _prompt_nerd=0
_pr_glyphs() {
    if (( _prompt_nerd )); then
        _pr_g=(
            on    $'\ue0a0'   # powerline branch, replaces the word "on"
            venv  $'\ue73c'   # devicons python
            jobs  $'\uf013'   # fa gear
            err   $'\uf00d'   # fa times
            timer $'\uf017'   # fa clock
        )
    else
        _pr_g=( on 'on'  venv '🐍'  jobs '✦'  err '✘'  timer '⏱' )
    fi
}
_pr_glyphs

# Themes call this to render the git segment in their own accent colors:
#   _pr_gitstr <color:on-word> <color:branch> [<color:alert>]
_pr_gitstr() {
    [[ -n $_pr_branch ]] || return
    local con=$1 cbr=$2 cal=${3:-197}
    print -n " %F{$con}${_pr_g[on]} %F{$cbr}${_pr_branch//\%/%%}%f"
    [[ -n $_pr_dirty ]]  && print -n " %F{$cal}●%f"
    (( _pr_ahead ))      && print -n " %F{$cbr}⇡${_pr_ahead}%f"
    (( _pr_behind ))     && print -n " %F{$cal}⇣${_pr_behind}%f"
    (( _pr_stash ))      && print -n " %F{$con}≡${_pr_stash}%f"
}

# Themes call this in RPROMPT to render the timer in their own accent color:
#   $(_pr_timestr <color>)   (empty unless the last command took a while)
_pr_timestr() {
    [[ -n $_pr_elapsed ]] || return
    print -n "%F{$1}${_pr_g[timer]} ${_pr_elapsed}%f "
}

# ── extra segments (each renders nothing when idle) ──────────────────────────
#   _pr_venvstr <color>            python venv / conda env, when active
#   _pr_sshstr <userC> <hostC>     user@host, only over SSH
_pr_venvstr() {
    local v=${VIRTUAL_ENV:t}
    [[ -z $v && -n $CONDA_DEFAULT_ENV ]] && v=$CONDA_DEFAULT_ENV
    [[ -n $v ]] && print -n " %F{$1}${_pr_g[venv]} ${v//\%/%%}%f"
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

# ── एक वाणी: the single-voice arbiter ───────────────────────────────────────
# Hooks that want one line above the prompt offer it via _pr_say with a
# priority (lower = rarer = wins); _pr_speak — registered last, at the end of
# this file — prints at most ONE per render. Losers are dropped, not queued:
# deferred delight reads as a bug. Without this, a 108th command that also
# failed after 10s would stack माला and karma lines over one prompt.
typeset -ga _pr_voice
typeset -gi _pr_spoke=0
_pr_say() {   # <priority> <prompt-escaped line>
    (( ${#_pr_voice} == 0 || $1 < _pr_voice[1] )) && _pr_voice=($1 "$2")
    return 0
}
_pr_speak() {
    _pr_spoke=0
    (( ${#_pr_voice} )) && { print -P -- "${_pr_voice[2]}"; _pr_spoke=1 }
    _pr_voice=()
}

# Every 108 commands: one mala of the keyboard. 📿
typeset -gi _pr_mala=0
_prompt_mala() {
    (( _pr_cmds && _pr_cmds % 108 == 0 && _pr_cmds != _pr_mala )) || return 0
    _pr_mala=$_pr_cmds
    local -i n=$(( _pr_cmds / 108 ))
    _pr_say 20 "  %F{220}📿 एक माला पूर्ण${${n:#1}:+ ×$n}%f %F{243}· ${_pr_cmds} commands this session 🙏%f"
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
    local life=''
    (( ${PROMPT_SADHANA:-1} )) && typeset -f _dl_total >/dev/null \
        && life=" %F{243}·%f %F{80}$(_dl_total) आजीवन%f"
    print -P "\n  %F{213}🙏 धन्यवाद%f %F{243}·%f %F{80}${_pr_cmds} commands%f %F{243}·%f %F{80}${dur}%f${life} %F{243}·%f %F{219}फिर मिलेंगे ✨%f"
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
# nerd icons: the file, when present, overrides the PROMPT_NERD env default —
# the `theme` panel and `theme nerd` toggle it with `n`.
(( ${+PROMPT_NERD} )) && _prompt_nerd=$PROMPT_NERD
[[ -f "$PROMPT_HOME/nerd" ]] && _prompt_nerd=$(<"$PROMPT_HOME/nerd")
_pr_glyphs
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

# nerd: swap the plain jobs/error marks baked into theme prompts for icons.
# The patterns stay narrow (✦%j, ✘%?) so decorative marks — diwali's ✦ jewel,
# rainbow's ✘✘✘ arrows, galaxy's ★ jobs star — keep their character.
_prompt_nerdify() {
    (( _prompt_nerd )) || return 0
    PROMPT=${PROMPT//✦%j/${_pr_g[jobs]}%j}   RPROMPT=${RPROMPT//✦%j/${_pr_g[jobs]}%j}
    PROMPT=${PROMPT//✘%\?/${_pr_g[err]}%?}   RPROMPT=${RPROMPT//✘%\?/${_pr_g[err]}%?}
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

# ── shared key reader for full-screen panels (the theme menu) ───────────────
# Sets $REPLY to: up · down · esc · a literal char. Returns 1 on timeout.
# Swallows COMPLETE escape sequences — CSI with parameters (modified arrows,
# Delete \e[3~, F-keys \e[15~, SGR mouse), and SS3 — so stray bytes never
# leak into the caller's key handling as fake keystrokes.
_pr_readkey() {   # [first-read timeout, seconds]
    local k
    REPLY=''
    read -sk1 -t ${1:-3} k 2>/dev/null || return 1
    if [[ $k != $'\e' ]]; then REPLY=$k; return 0; fi
    read -sk1 -t 0.1 k 2>/dev/null || { REPLY=esc; return 0 }
    if [[ $k == '[' ]]; then
        local fin=''
        while read -sk1 -t 0.1 k 2>/dev/null; do
            [[ $k == [@-~] ]] && { fin=$k; break }   # CSI final byte
        done
        case $fin in A) REPLY=up ;; B) REPLY=down ;; esac
    elif [[ $k == O ]]; then
        read -sk1 -t 0.1 k 2>/dev/null
        case $k in A) REPLY=up ;; B) REPLY=down ;; esac
    fi                                               # \e+other: alt-chord, drop
    return 0
}

# ── theme picker panel (the hop terminal hub lives on the `hop` branch) ─────
[[ -r "$PROMPT_HOME/menu.zsh" ]] && source "$PROMPT_HOME/menu.zsh"

# ── colorful ASCII-art startup banner ───────────────────────────────────────
[[ -r "$PROMPT_HOME/banner.zsh" ]] && source "$PROMPT_HOME/banner.zsh"
: ${PROMPT_BANNER:=1}
(( PROMPT_BANNER )) && typeset -f prompt-banner >/dev/null && prompt-banner

# ── उत्सव — festival modes ──────────────────────────────────────────────────
# On a festival day (festivals.txt, verified dates): a banner in every shell,
# and the animated moment once — first shell of the day only. Any day:
# `theme utsav` browses every festival's moment, Alt-J replays one.
# PROMPT_UTSAV=0 silences it all. The theme wrapper installs at file end,
# once theme() exists.
[[ -r "$PROMPT_HOME/utsav.zsh" ]] && source "$PROMPT_HOME/utsav.zsh"
typeset -f _utsav_startup >/dev/null && _utsav_startup

# ── श्लोक — offline verses: Gita, Ramayan, Sundarkand, Chalisa ───────────────
# A random verse at startup (PROMPT_SHLOK=0 to disable), `shlok` or Alt-G for
# a fresh one any time.
[[ -r "$PROMPT_HOME/shlok.zsh" ]] && source "$PROMPT_HOME/shlok.zsh"
: ${PROMPT_SHLOK:=1}
(( PROMPT_SHLOK )) && [[ -t 1 ]] && typeset -f shlok >/dev/null && shlok 2>/dev/null

# ── the ordinary-day delights: empathy · whisper · साधना · cd-greet ─────────
# (sourced after shlok — whisper borrows verse lines from the collections)
[[ -r "$PROMPT_HOME/delights.zsh" ]] && source "$PROMPT_HOME/delights.zsh"

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
        print -u2 "theme: unknown theme '$name'"; _prompt_list; return 1
    fi
    _prompt_apply_$name
    _prompt_expand_paths
    _prompt_nerdify
    _prompt_glowify
    _prompt_apply_lscolors $name
    _prompt_current=$name
    { print -r -- "$name" > "$PROMPT_HOME/current" } 2>/dev/null
}

_prompt_list() {
    print -P "%B%F{045}Available prompt themes%f%b  (current: %F{213}${_prompt_current:-none}%f)\n"
    local name
    for name in ${(ok)_prompt_themes}; do
        local mark=' '; [[ $name == $_prompt_current ]] && mark='%F{046}✓%f'
        print -P "  ${mark} %F{213}$(printf '%-11s' $name)%f ${_prompt_themes[$name]}"
    done
    local glow=''; (( _prompt_glow )) && glow='  %F{220}✨ glow on%f'
    (( _prompt_nerd )) && glow+="  %F{117}${_pr_g[on]} nerd on%f"
    print -P "\n  %F{242}theme <name> | list | gallery | random | glow | nerd — no args opens the panel%f${glow}"
}

_prompt_gallery() {
    print -P "\n%B%F{045}✦ playful-zsh theme gallery ✦%f%b\n"
    local name s
    for name in ${(ok)_prompt_themes}; do
        print -P "%F{242}── %f%B%F{213}${name}%f%b %F{242}${_prompt_themes[$name]}%f"
        s=${_prompt_samples[$name]}
        (( _prompt_nerd )) && s=${s//on \%F/${_pr_g[on]} %F}
        print -P "$s"
        _pr_ls_swatch $name
        print
    done
}

# The one command. Bare `theme` opens the picker panel (menu.zsh); everything
# else — list, gallery, random, glow, a theme name — is a subcommand.
theme() {
    case ${1:-menu} in
        menu|'')
            if typeset -f _thm_menu >/dev/null; then _thm_menu; else _prompt_list; fi ;;
        list)     _prompt_list ;;
        gallery)  _prompt_gallery ;;
        random)   local -a k=(${(k)_prompt_themes}); _prompt_use ${k[$((RANDOM % $#k + 1))]} ;;
        glow)
            case ${2:-toggle} in
                on)  _prompt_glow=1 ;;
                off) _prompt_glow=0 ;;
                *)   (( _prompt_glow ^= 1 )) || : ;;
            esac
            { print -r -- $_prompt_glow > "$PROMPT_HOME/glow" } 2>/dev/null
            _prompt_use "$_prompt_current"
            if (( _prompt_glow )); then print -P "%F{220}✨ glow on%f — bold prompt & file colors"
            else print -P "%F{242}glow off%f"; fi
            ;;
        nerd)
            case ${2:-toggle} in
                on)  _prompt_nerd=1 ;;
                off) _prompt_nerd=0 ;;
                *)   (( _prompt_nerd ^= 1 )) || : ;;
            esac
            { print -r -- $_prompt_nerd > "$PROMPT_HOME/nerd" } 2>/dev/null
            _pr_glyphs
            _prompt_use "$_prompt_current"
            if (( _prompt_nerd )); then print -P "%F{117}${_pr_g[on]} nerd icons on%f — needs a patched font (e.g. JetBrainsMono Nerd Font)"
            else print -P "%F{242}nerd icons off%f — plain Unicode, works everywhere"; fi
            ;;
        *)        _prompt_use "$1" ;;
    esac
}
# Tab-completion for `theme`. Plugin managers load us before compinit has run
# (oh-my-zsh calls it after the plugin list), so compdef may not exist yet —
# _pr_rebind_once re-offers this at the first prompt, when it certainly does.
_prompt_compdef() {
    (( $+functions[compdef] )) || return 0
    compdef '_arguments "1:theme:(list gallery random glow nerd ${(k)_prompt_themes})"' theme
}
_prompt_compdef

# ── activate saved theme (or default) ───────────────────────────────────────
[[ -f "$PROMPT_HOME/current" ]] && _prompt_current=$(<"$PROMPT_HOME/current")
[[ -n ${_prompt_themes[$_prompt_current]} ]] || _prompt_current=candy
_prompt_apply_$_prompt_current
_prompt_expand_paths
_prompt_nerdify
_prompt_glowify
_prompt_apply_lscolors $_prompt_current

# ── shells follow the persisted theme (PROMPT_FOLLOW=0 to opt out) ──────────
# When any shell switches theme, glow or nerd icons, every other running shell
# adopts it at its next prompt. Three builtin file reads per prompt, no forks.
_prompt_follow() {
    (( ${PROMPT_FOLLOW:-1} )) || return 0
    local t=$_prompt_current g=0 nd=$_prompt_nerd
    [[ -r "$PROMPT_HOME/current" ]] && t=$(<"$PROMPT_HOME/current")
    [[ -f "$PROMPT_HOME/glow" ]] && g=$(<"$PROMPT_HOME/glow")
    [[ -f "$PROMPT_HOME/nerd" ]] && nd=$(<"$PROMPT_HOME/nerd")
    [[ $t == $_prompt_current && $g == $_prompt_glow && $nd == $_prompt_nerd ]] && return 0
    [[ -n ${_prompt_themes[$t]} ]] || return 0
    _prompt_glow=$g
    (( nd != _prompt_nerd )) && { _prompt_nerd=$nd; _pr_glyphs }
    _prompt_apply_$t
    _prompt_expand_paths
    _prompt_nerdify
    _prompt_glowify
    _prompt_apply_lscolors $t
    _prompt_current=$t
}
add-zsh-hook precmd _prompt_follow

# ── closing wiring (order matters) ──────────────────────────────────────────
# theme() exists now — install the उत्सव wrapper (`theme utsav`, day-jewel on
# festival-theme switches). Then the single voice speaks after every hook has
# offered its line, and ambience registers last so it can see whether it did.
#
# The speaker RE-ANCHORS to the end of the chain on every source: add-zsh-hook
# dedupes but never moves, so a `source ~/.zshrc` that registers new offering
# hooks would otherwise land them AFTER the speaker — and every delight line
# would arrive one prompt late.
typeset -f _utsav_arm >/dev/null && _utsav_arm
add-zsh-hook -d precmd _pr_speak        2>/dev/null
add-zsh-hook -d precmd _utsav_amb_hook  2>/dev/null
add-zsh-hook precmd _pr_speak
typeset -f _utsav_arm_ambient >/dev/null && _utsav_arm_ambient

# Late-loading plugins (vi-mode and friends) rebuild keymaps and silently wipe
# widget bindings. Re-assert our two chords at the FIRST prompt — after the
# whole ~/.zshrc, plugins included, has finished loading. compinit lands in
# that window too when a plugin manager loaded us, so `theme` completion is
# registered here as well.
_pr_rebind_once() {
    add-zsh-hook -d precmd _pr_rebind_once
    _prompt_compdef
    [[ -o zle ]] || return 0
    if (( $+functions[_shlok_widget] )); then
        zle -N shlok-random _shlok_widget
        bindkey '\eg' shlok-random
    fi
    (( $+functions[_utsav_bind_key] )) && _utsav_bind_key
}
add-zsh-hook precmd _pr_rebind_once
