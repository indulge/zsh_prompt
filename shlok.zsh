# shlok.zsh — offline श्लोक engine: Bhagavad Gita, Ramcharitmanas, Sundarkand,
# Hanuman Chalisa. A verse at startup, a fresh one any time. Dependency-free.
#
#   shlok                     a random verse (never the same one twice in a row)
#   shlok daily               today's verse (same all day, changes at midnight)
#   shlok gita [2.47]         random / specific verse from one collection
#   shlok list [gita]         browse what's inside
#   Alt-G                     a fresh verse right above whatever you're typing
#   gita / ramayan / sundarkand / chalisa    shortcuts for each collection
#
# Collections are plain text files in $PROMPT_HOME/quotes/*.txt — drop in your
# own and it joins the rotation. Format (only [id] and v: are required;
# @title defaults to the file name, and a bare `v:` makes a blank verse line):
#   @title <display title>       @icon <one char>
#   @ramp <256-color indices>    @art <line of block art, ░ becomes space>
#   [id]
#   t: <label shown in the header, e.g. अध्याय २ · श्लोक ४७>
#   v: <verse line>          hi: <hindi meaning line>     en: <english line>

typeset -g PROMPT_HOME="${PROMPT_HOME:-${${(%):-%x}:A:h}}"

typeset -gA _shlok_v _shlok_hi _shlok_en _shlok_t
typeset -gA _shlok_title _shlok_icon _shlok_ramp _shlok_art
typeset -ga _shlok_ids
typeset -g  _shlok_last=''

_shlok_load() {
    (( ${#_shlok_ids} )) && return 0
    local f coll line id=''
    for f in "$PROMPT_HOME"/quotes/*.txt(N); do
        coll=${f:t:r} id=''
        for line in "${(@f)$(<$f)}"; do
            line=${line%$'\r'}                 # tolerate CRLF drop-ins
            case $line in
                ('#'*)       ;;
                ('@title '*) _shlok_title[$coll]=${line#@title } ;;
                ('@icon '*)  _shlok_icon[$coll]=${line#@icon } ;;
                ('@ramp '*)  _shlok_ramp[$coll]=${line#@ramp } ;;
                ('@art '*)   _shlok_art[$coll]+="${line#@art }"$'\n' ;;
                ('['*']')    id="$coll:${${line#\[}%\]}"; _shlok_ids+=($id) ;;
                ('t: '*)     [[ -n $id ]] && _shlok_t[$id]=${line#t: } ;;
                ('v: '*|v:)  [[ -n $id ]] && _shlok_v[$id]+="${${line#v:}# }"$'\n' ;;
                ('hi: '*)    [[ -n $id ]] && _shlok_hi[$id]+="${line#hi: }"$'\n' ;;
                ('en: '*)    [[ -n $id ]] && _shlok_en[$id]+="${line#en: }"$'\n' ;;
            esac
        done
        # A drop-in without @title still deserves a name and a list entry.
        [[ -n ${_shlok_title[$coll]} ]] || _shlok_title[$coll]=$coll
        [[ -n ${_shlok_icon[$coll]}  ]] || _shlok_icon[$coll]='📜'
    done
    (( ${#_shlok_ids} ))
}

# Pick a random id (optionally within collection $1) into $REPLY. No subshell —
# $(...) would fork and $RANDOM would repeat, so callers read $REPLY instead.
_shlok_pick() {
    local -a pool
    if [[ -n $1 ]]; then pool=(${(M)_shlok_ids:#$1:*}); else pool=($_shlok_ids); fi
    (( ${#pool} )) || return 1
    REPLY=${pool[RANDOM % ${#pool} + 1]}
    while [[ $REPLY == $_shlok_last ]] && (( ${#pool} > 1 )); do
        REPLY=${pool[RANDOM % ${#pool} + 1]}
    done
}

# The card: gradient block-art header, ornament rule, verse, then meanings.
# No closed box — Devanagari glyph widths vary by terminal, so the layout is
# left-anchored and never needs a right border to line up.
_shlok_show() {
    local id=$1 coll=${1%%:*} line
    local ramp=${_shlok_ramp[$coll]:-"$_pr_ramp"}
    local -i off=$(( RANDOM % 8 ))
    print
    for line in "${(@f)${_shlok_art[$coll]%$'\n'}}"; do
        print -n '   '; _pr_grad "${line//░/ }" $off ${=ramp}
    done
    print -P "   %F{243}╶─✦%f %F{220}${_shlok_icon[$coll]}%f %B%F{215}${_shlok_title[$coll]}%f%b%F{243}${_shlok_t[$id]:+ · }${_shlok_t[$id]} ✦─╴%f"
    print
    for line in "${(@f)${_shlok_v[$id]%$'\n'}}";  do print -P "     %F{223}${line}%f"; done
    print
    for line in "${(@f)${_shlok_hi[$id]%$'\n'}}"; do print -P "     %F{182}${line}%f"; done
    [[ -n ${_shlok_en[$id]} ]] && print
    for line in "${(@f)${_shlok_en[$id]%$'\n'}}"; do print -P "     %F{109}${line}%f"; done
    print
    _shlok_last=$id
}

_shlok_list() {
    local coll id first
    print
    for coll in ${(ok)_shlok_title}; do
        [[ -n $1 && $coll != $1 ]] && continue
        print -P "  %F{220}${_shlok_icon[$coll]}%f %B%F{215}${_shlok_title[$coll]}%f%b %F{243}— shlok $coll%f"
        for id in ${(M)_shlok_ids:#$coll:*}; do
            first=${${(@f)_shlok_v[$id]}[1]}
            print -P "    %F{220}$(printf '%-8s' ${id#$coll:})%f %F{250}${first}%f"
        done
        print
    done
}

_shlok_help() {
    print -P "%B%F{215}shlok%f%b — offline verses, beautifully"
    print -P "  %F{220}shlok%f            a random verse from every collection"
    print -P "  %F{220}shlok daily%f      today's verse (same all day)"
    print -P "  %F{220}shlok gita 2.47%f  a specific verse  %F{243}(also: ramayan · sundarkand · chalisa)%f"
    print -P "  %F{220}shlok list%f       browse everything"
    print -P "  %F{220}Alt-G%f            a fresh verse, any time, mid-typing"
    print -P "  %F{243}drop your own collection in quotes/*.txt — it joins the rotation%f"
}

shlok() {
    emulate -L zsh
    _shlok_load || { print -u2 'shlok: no quote files in quotes/'; return 1 }
    local id sub=${1:-random}
    case $sub in
        random|'') _shlok_pick '' && id=$REPLY || { print -u2 'shlok: nothing to pick'; return 1 } ;;
        daily)     local -i d=${(%):-%D{%Y%j}}
                   id=${_shlok_ids[d % ${#_shlok_ids} + 1]} ;;
        list)      _shlok_list "$2"; return ;;
        help|-h|--help) _shlok_help; return ;;
        *)
            if [[ -n ${_shlok_title[$sub]} ]]; then
                if [[ -n $2 ]]; then
                    id="$sub:$2"
                    [[ -n ${_shlok_v[$id]} ]] || { print -u2 "shlok: no [$2] in $sub (try: shlok list $sub)"; return 1 }
                else
                    _shlok_pick $sub && id=$REPLY || { print -u2 "shlok: '$sub' has no verses"; return 1 }
                fi
            elif [[ -n ${_shlok_v[gita:$sub]} ]]; then
                id="gita:$sub"                       # bare 2.47 means the Gita
            else
                print -u2 "shlok: unknown '$sub' (try: shlok help)"; return 1
            fi ;;
    esac
    [[ -n $id ]] || return 1
    _shlok_show $id
}

# Friendly per-collection shortcuts: `gita`, `gita 2.47`, `chalisa`, …
gita()       { shlok gita       "$@" }
ramayan()    { shlok ramayan    "$@" }
sundarkand() { shlok sundarkand "$@" }
chalisa()    { shlok chalisa    "$@" }

# Alt-G: a fresh verse above whatever you're typing, prompt redrawn intact.
if [[ -o zle ]]; then
    _shlok_widget() { zle -I; shlok; zle reset-prompt }
    zle -N shlok-random _shlok_widget
    bindkey '\eg' shlok-random
fi

# ── कर्मफल सान्त्वना: when a long command fails, a moment of Gita ─────────────
# A command that ran ≥10s and exited nonzero earns one dim consolation line.
# Disable with PROMPT_KARMA=0.
typeset -ga _shlok_karma_lines=(
    'कर्मण्येवाधिकारस्ते मा फलेषु कदाचन — the effort is yours; the fruit was never yours to hold'
    'योगः कर्मसु कौशलम् — yoga is skill in action; begin again'
    'समत्वं योग उच्यते — equanimity, in success and failure, is yoga'
    'उद्धरेदात्मनात्मानम् — lift yourself up by your own self'
)
typeset -gi _shlok_karma_i=0
_shlok_karma() {
    (( ${PROMPT_KARMA:-1} ))                    || return 0
    (( _pr_last != 0 && _pr_elapsed_s >= 10 ))  || return 0
    _shlok_karma_i=$(( _shlok_karma_i % ${#_shlok_karma_lines} + 1 ))
    print -P "  %F{243}🪶 ${_shlok_karma_lines[_shlok_karma_i]}%f"
}
add-zsh-hook precmd _shlok_karma 2>/dev/null
