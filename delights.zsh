# delights.zsh — the ordinary-day delights. Where utsav.zsh celebrates the
# calendar, this file warms the everyday: a kind line for a typo, a verse
# woven into long work, a shell that remembers how long you've practiced.
#
#   🍃 empathy    one kind line for exit codes that MEAN something (127
#                 command-not-found, 130 Ctrl-C, 126 not-executable) —
#                 once per class per session, never a lecture
#   📿 whisper    verses in the flow of real work: a धैर्य line when a ≥30s
#                 command finally SUCCEEDS, a welcome-back half-verse after
#                 30 idle minutes (cross-shell — six tmux panes greet once),
#                 an ambient verse line each half-माला (the 54th command)
#   🌱 साधना      lifetime command count, persisted; titles at log-scale
#                 (जिज्ञासु → शिष्य → साधक → योगी → ऋषि); the banner greets
#                 you by title from level 2, the farewell knows your total
#   🛤️ cd-greet   returning to a repo untouched ≥7 days earns one honest line
#
# Every line goes through init.zsh's एक वाणी arbiter — at most ONE speaks per
# prompt, rarest first: level-up(15) < माला(20) < karma(30) < empathy(40) <
# धैर्य(50) < welcome-back(55) < ambient(60). Losers are dropped, not queued.
#
#   delights           status: साधना, whisper cooldown, what's armed
#   delights demo      every line, previewed at once (nothing counts)
#
# Knobs (before the managed block, default on): PROMPT_EMPATHY=0,
# PROMPT_WHISPER=0 (PROMPT_WHISPER_GAP seconds, default 900),
# PROMPT_SADHANA=0, PROMPT_CD_GREET=0.

typeset -g PROMPT_HOME="${PROMPT_HOME:-${${(%):-%x}:A:h}}"
zmodload zsh/datetime 2>/dev/null
zmodload -F zsh/stat b:zstat 2>/dev/null

# ── 🌱 साधना: lifetime memory ────────────────────────────────────────────────
# sessions/sadhana holds "count announced-level hint-count" — written on exit
# and at level-ups. Multi-shell undercount is bounded and fine for whimsy.
typeset -ga _dl_titles=(जिज्ञासु शिष्य साधक योगी ऋषि)
typeset -ga _dl_title_at=(0 1000 10000 50000 200000)
typeset -gi _dl_base=0 _dl_level=1 _dl_hints=0
() {
    local f="$PROMPT_HOME/sessions/sadhana"
    [[ -r $f ]] || return 0
    local -a s=(${=$(<$f)})
    _dl_base=${s[1]:-0} _dl_level=${s[2]:-1} _dl_hints=${s[3]:-0}
}
_dl_total() { print $(( _dl_base + ${_pr_cmds:-0} )) }
_dl_title() {   # -> index into _dl_titles for a given total
    local -i t=$1 i s=1
    for (( i = 2; i <= ${#_dl_title_at}; i++ )); do (( t >= _dl_title_at[i] )) && s=$i; done
    print $s
}
_dl_save() {
    { print -r -- "$(_dl_total) $_dl_level $_dl_hints" > "$PROMPT_HOME/sessions/sadhana" } 2>/dev/null
}
# The banner greets by title from level 2 on — day one shows nothing new.
_dl_titlestr() {
    (( ${PROMPT_SADHANA:-1} )) || return 0
    local -i lvl=$(_dl_title $(_dl_total))
    (( lvl >= 2 )) && print -rn -- " ${_dl_titles[lvl]}"
}
_dl_levelup() {   # a handful of times, ever — announced once across shells
    (( ${PROMPT_SADHANA:-1} )) || return 0
    local -i lvl=$(_dl_title $(_dl_total))
    (( lvl > _dl_level )) || return 0
    _dl_level=$lvl
    _dl_save
    _pr_say 15 "  %F{220}✨ साधना बढ़ी%f %F{215}— अब आप ${_dl_titles[lvl]} हैं%f %F{243}· $(_dl_total) commands, lifetime%f"
}

# ── 🍃 empathy: exit codes that mean something ───────────────────────────────
typeset -gA _dl_emp_seen
typeset -gA _dl_emp_i
typeset -gA _dl_emp_127=(1 '🔍 वह मंत्र किसी ग्रंथ में नहीं मिला — command not found'
                         2 '🔍 अक्षर भटक गए — the letters wandered; try once more')
typeset -gA _dl_emp_130=(1 '🍃 रुकना भी साधना है — stopped on purpose; breathe'
                         2 '🍃 संन्यास भी एक उत्तर है — letting go is also an answer')
typeset -gA _dl_emp_126=(1 '🚪 द्वार अभी बंद है — not executable; chmod +x opens it')
_dl_empathy() {   # $1 = exit code
    (( ${PROMPT_EMPATHY:-1} )) || return 0
    case $1 in (126|127|130) ;; (*) return 0 ;; esac
    [[ -n ${_dl_emp_seen[$1]} ]] && return 0
    _dl_emp_seen[$1]=1
    local -i i=$(( ${_dl_emp_i[$1]:-0} + 1 ))
    local var="_dl_emp_$1"
    local -i n=${#${(P)var}}
    (( i > n )) && i=1
    _dl_emp_i[$1]=$i
    _pr_say 40 "  %F{109}${${(P)var}[$i]}%f"
}

# ── 📿 whisper: verses in the flow of real work ──────────────────────────────
typeset -gi _dl_whisper_at=0 _dl_gap=0
typeset -ga _dl_dhairya=(
    'श्रद्धावाँल्लभते ज्ञानम् — the patient one attains'
    'उद्यमेन हि सिध्यन्ति कार्याणि न मनोरथैः — by effort, not by wishing, do works succeed'
    'धीरे धीरे रे मना — slowly, slowly; everything in its season'
)
_dl_verse_line() {   # one verse line + its icon, from the loaded collections
    (( $+functions[_shlok_load] )) && _shlok_load 2>/dev/null
    if (( ${#_shlok_ids} )); then
        _shlok_pick '' || return 1
        print -rn -- "${_shlok_icon[${REPLY%%:*}]} ${${(@f)_shlok_v[$REPLY]}[1]}"
    else
        print -rn -- '🪶 कर्मण्येवाधिकारस्ते मा फलेषु कदाचन'
    fi
}
_dl_whisper() {   # $1 = exit code
    (( ${PROMPT_WHISPER:-1} )) || return 0
    local -i now=${EPOCHSECONDS:-0}
    # welcome-back rates itself — a ≥30-min idle gap cannot be spammed — so it
    # skips the shared cooldown (a धैर्य line ten minutes ago must not mute
    # the greeting). It still counts as a whisper for whatever comes next.
    if (( _dl_gap >= 1800 )); then
        _dl_gap=0                     # consumed — one gap, one greeting
        _pr_say 55 "  %F{243}🪷 पुनः स्वागतम् — $(_dl_verse_line)%f"
        _dl_whisper_at=$now
        return 0
    fi
    (( now - _dl_whisper_at >= ${PROMPT_WHISPER_GAP:-900} )) || return 0
    if [[ $1 == 0 ]] && (( ${_pr_elapsed_s:-0} >= 30 )); then
        _pr_say 50 "  %F{243}🕊️  ${_dl_dhairya[RANDOM % ${#_dl_dhairya} + 1]}%f"
    elif (( ${_pr_cmds:-0} % 108 == 54 )); then       # the half-माला
        local hint=''
        if (( _dl_hints < 3 )); then (( ++_dl_hints )); hint=" %F{240}· Alt-G%f"; fi
        _pr_say 60 "  %F{243}$(_dl_verse_line)${hint}%f"
    else
        return 0
    fi
    _dl_whisper_at=$now
}

# ── 🛤️ cd-greet: returning to a forgotten repo ──────────────────────────────
typeset -gA _dl_visited
_dl_chpwd() {
    (( ${PROMPT_CD_GREET:-1} )) || return 0
    local top
    top=$(command git rev-parse --show-toplevel 2>/dev/null) || return 0
    [[ -n $top && -z ${_dl_visited[$top]} ]] || return 0
    _dl_visited[$top]=1
    local -i ct
    ct=$(command git -C "$top" log -1 --format=%ct 2>/dev/null) || return 0
    (( ct )) || return 0
    local -i days=$(( (${EPOCHSECONDS:-$ct} - ct) / 86400 ))
    (( days >= 7 )) || return 0
    _pr_say 45 "  %F{243}🛤️  ${top:t} फिर से — last commit here: ${days} days ago%f"
}

# ── wiring ───────────────────────────────────────────────────────────────────
# The pulse file makes welcome-back cross-shell: every command start touches
# it (builtin redirect, no forks); the gap is read BEFORE touching, so any
# shell's activity — including this one's — resets everyone's idle clock.
typeset -gi _dl_ran=0
_dl_preexec() {
    _dl_ran=1
    local p="$PROMPT_HOME/sessions/pulse"
    local -a st
    _dl_gap=0
    if zstat -A st +mtime "$p" 2>/dev/null; then
        _dl_gap=$(( ${EPOCHSECONDS:-st[1]} - st[1] ))
    fi
    { : >| "$p" } 2>/dev/null
}
_dl_precmd() {
    (( _dl_ran )) || return 0
    _dl_ran=0
    local code=${_pr_last:-0}
    _dl_levelup
    _dl_empathy $code
    _dl_whisper $code
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _dl_preexec
add-zsh-hook precmd  _dl_precmd
add-zsh-hook chpwd   _dl_chpwd
add-zsh-hook zshexit _dl_save

# ── the status card, and a preview of every line ─────────────────────────────
delights() {
    case ${1:-status} in
        demo)
            print
            print -P '  %F{243}every ordinary-day line, previewed (nothing counts):%f'
            print -P "  %F{109}${_dl_emp_127[1]}%f"
            print -P "  %F{109}${_dl_emp_130[1]}%f"
            print -P "  %F{243}🕊️  ${_dl_dhairya[2]}%f"
            print -P "  %F{243}🪷 पुनः स्वागतम् — $(_dl_verse_line)%f"
            print -P "  %F{243}$(_dl_verse_line) %F{240}· Alt-G%f"
            print -P "  %F{243}🛤️  bookbase फिर से — last commit here: 19 days ago%f"
            print -P "  %F{220}✨ साधना बढ़ी%f %F{215}— अब आप शिष्य हैं%f %F{243}· 1000 commands, lifetime%f"
            print
            ;;
        *)
            local -i t=$(_dl_total) lvl=$(_dl_title $(_dl_total))
            local -i next=0 now=${EPOCHSECONDS:-0}
            (( lvl < ${#_dl_title_at} )) && next=$(( _dl_title_at[lvl+1] - t ))
            print
            print -P "  🌱 %B%F{215}साधना%f%b %F{243}· ${_dl_titles[lvl]} · ${t} lifetime commands · $(( t / 108 )) माला$( (( next )) && print -rn -- " · ${next} until ${_dl_titles[lvl+1]}" )%f"
            local w='ready'
            (( now - _dl_whisper_at < ${PROMPT_WHISPER_GAP:-900} )) && w="quiet for $(( (${PROMPT_WHISPER_GAP:-900} - now + _dl_whisper_at) / 60 ))m more"
            print -P "  📿 %F{243}whisper: ${w} · empathy classes heard: ${(k)_dl_emp_seen:-none} · Alt-G hint uses left: $(( 3 - _dl_hints ))%f"
            print -P "  %F{243}delights demo previews every line%f"
            print
            ;;
    esac
}
