# lab.zsh — playful-lab PROTOTYPE (untracked): try-before-you-buy delights.
# Five experiments that ride the existing engine (init.zsh) without touching it:
#
#   🐣 सखी        a tiny companion that grows with your lifetime commands,
#                 droops after failures, sleeps at night, and one day becomes 🦚
#   ⚡ combo      consecutive successes build a streak; it only speaks at ≥5,
#                 and breaking a big one costs you a 💥 moment
#   🪔 बेला       a time-of-day greeting — dawn, noon, dusk (diya), night (moon)
#   🍃 empathy    one kind line for `command not found` / Ctrl-C, never nagging
#   📿 whisper    verses woven into the flow of ordinary commands: a धैर्य line
#                 when a long command finally SUCCEEDS, a welcome-back half-verse
#                 after 30 idle minutes, an ambient fragment each half-माला
#   🎆 उत्सव      festival modes from a verified festivals.txt date table:
#                 banner on the day, a ≤2s skippable one-shot effect (Diwali
#                 fireworks, Holi colors, Onam pookalam, deepmala, छठ sunrise)
#                 once per day globally — the day makes the moment, the user
#                 makes the palette
#
#   lab on            arm the blessed set for this shell (banner if festival day)
#   lab off           put everything back
#   lab status        your सखी's story so far
#   lab festival [k]  list festivals / preview one's moment
#   lab demo          a scripted tour of every moment — safe anywhere
#
# THE SINGLE-VOICE RULE: the prompt may add at most ONE extra line per render.
# Priority when several want to speak: celebration > empathy > whisper.
# (Evolution moments are exempt — they happen a handful of times, ever.)
#
# Lifetime command count persists to $PROMPT_HOME/sadhana (like `current`/`glow`).
# Everything degrades gracefully if init.zsh isn't loaded (demo works standalone).

typeset -g PROMPT_HOME="${PROMPT_HOME:-${${(%):-%x}:A:h}}"
zmodload zsh/datetime 2>/dev/null   # $EPOCHSECONDS for the rate limits

# Fallbacks so `zsh lab.zsh demo` works without the engine.
(( $+functions[_pr_grad] )) || {
    typeset -ga _pr_ramp=(196 202 208 214 220 190 154 84 43 45 39 63 99 135 171 207 213)
    _pr_grad() {
        local s=$1 off=${2:-0}; local -a ramp=(${@[3,-1]}); (( ${#ramp} )) || ramp=($_pr_ramp)
        local -i n=${#ramp} i c
        for (( i = 1; i <= ${#s}; i++ )); do
            c=${ramp[ (( (i + off - 1) % n ) + 1 ) ]}; print -Pn "%F{$c}${s[i]}%f"
        done; print
    }
}

# ── सखी: the companion ──────────────────────────────────────────────────────
# Stages are measured in malas (108 commands each) — the japa-mala is already
# this prompt's unit of devotion. Egg → hatchling → fledgling → bird → peacock.
typeset -gi _lab_sadhana=0 _lab_fails=0 _lab_hour_override=-1
[[ -f "$PROMPT_HOME/sadhana" ]] && _lab_sadhana=$(<"$PROMPT_HOME/sadhana")

typeset -ga _lab_stages=(🥚 🐣 🐤 🐦 🦚)
typeset -ga _lab_stage_names=(अण्ड शावक चूज़ा पंछी मयूर)
typeset -ga _lab_stage_at=(0 108 1080 5400 10800)   # lifetime commands

_lab_total() { print $(( _lab_sadhana + ${_pr_cmds:-0} )) }
_lab_stage() {   # -> index into _lab_stages for a given total
    local -i t=$1 i s=1
    for (( i = 2; i <= ${#_lab_stage_at}; i++ )); do (( t >= _lab_stage_at[i] )) && s=$i; done
    print $s
}
_lab_hour() {
    (( _lab_hour_override >= 0 )) && { print $_lab_hour_override; return }
    local h=${(%):-%D{%H}}
    print $(( 10#$h ))
}

# साधना titles — log-scale, so a new level is years apart by construction.
typeset -ga _lab_titles=(जिज्ञासु शिष्य साधक योगी ऋषि)
typeset -ga _lab_title_at=(0 1000 10000 50000 200000)
_lab_title() {   # -> index into _lab_titles for the lifetime total
    local -i t=$(_lab_total) i s=1
    for (( i = 2; i <= ${#_lab_title_at}; i++ )); do (( t >= _lab_title_at[i] )) && s=$i; done
    print $s
}

# The segment: icon + mood. Sleeps 22:00–05:00, droops after 2 straight fails.
_pr_petstr() {
    local -i s=$(_lab_stage $(_lab_total)) h=$(_lab_hour)
    local mood=''
    if   (( h >= 22 || h < 5 )); then mood='💤'
    elif (( _lab_fails >= 2 ));  then mood='💧'; fi
    print -n " ${_lab_stages[s]}${mood}"
}

# Evolution moment: fires once, the instant the stage flips mid-session.
typeset -gi _lab_seen_stage=0
_lab_evolve() {
    local -i s=$(_lab_stage $(_lab_total))
    (( _lab_seen_stage )) || _lab_seen_stage=$s
    (( s > _lab_seen_stage )) || return 0
    _lab_seen_stage=$s
    print
    _pr_grad "   ✦ ${_lab_stages[s-1]} → ${_lab_stages[s]} ✦" 0 220 214 208 202 208 214
    print -P "   %F{215}आपकी सखी बढ़ी — now a ${_lab_stage_names[s]}%f %F{243}· $(_lab_total) commands together%f"
    print
}

# ── ⚡ combo: consecutive successes ──────────────────────────────────────────
typeset -gi _lab_combo=0 _lab_combo_best=0 _lab_ran=0
typeset -ga _lab_combo_marks=(25 50 108)

_pr_combostr() {
    (( _lab_combo >= 5 )) || return 0
    print -n " %F{220}⚡${_lab_combo}%f"
}

# Printers return 0 only when they actually said something — the single-voice
# chain in _lab_precmd stops at the first speaker.
_lab_combo_step() {   # $1 = exit code of the command that just ran
    if [[ $1 == 0 ]]; then
        (( ++_lab_combo, _lab_fails = 0 ))
        (( _lab_combo > _lab_combo_best )) && _lab_combo_best=$_lab_combo
        if (( ${_lab_combo_marks[(Ie)$_lab_combo]} && _lab_wild )); then
            _pr_grad "   ⚡ ${_lab_combo} निर्विघ्न — a flawless streak" 0 226 220 214 208 214 220
            return 0
        fi
    else
        (( ++_lab_fails ))
        local -i was=$_lab_combo
        _lab_combo=0
        (( was >= 10 && _lab_wild )) && { print -P "   %F{243}💥 ⚡${was} combo broken — फिर से%f"; return 0 }
    fi
    return 1
}

# ── 🍃 empathy: one kind line, rate-limited to one per 5 minutes ─────────────
typeset -gi _lab_empathy_at=0
_lab_empathy() {   # $1 = exit code
    local now=${EPOCHSECONDS:-0}
    (( now - _lab_empathy_at >= 300 )) || return 1
    case $1 in
        127) print -P "   %F{109}🔍 वह मंत्र किसी ग्रंथ में नहीं मिला%f %F{243}— command not found%f" ;;
        130) print -P "   %F{109}🍃 रुकना भी साधना है%f %F{243}— interrupted; breathe%f" ;;
        *)   return 1 ;;
    esac
    _lab_empathy_at=$now
    return 0
}

# ── ☄️ शुभ संकेत: a rare blessing (~1 in 200 successful commands) ─────────────
_lab_shubh() {
    (( RANDOM % 200 == 0 )) || return 1
    _pr_grad "   ☄️  शुभ संकेत — something good is coming ✨" $(( RANDOM % 8 ))
    return 0
}

# ── 📿 whisper: verses woven into ordinary commands, never intrusive ─────────
# Three earned moments, one shared rate limit (default: one whisper per 15 min,
# PROMPT_WHISPER_GAP to tune, PROMPT_WHISPER=0 to silence):
#   · धैर्य — a long command (≥30s) finally succeeded (twin of the karma line,
#     which only ever speaks to failure)
#   · welcome back — first command after ≥30 idle minutes
#     (production: needs a cross-shell last-activity stamp in sessions/, or six
#     idle tmux panes greet you six times)
#   · ambient — every half-माला (the 54th command of each 108), one dim verse
#     line from the real collections. Count-earned, never RNG. The Alt-G hint
#     retires after its first three appearances.
typeset -gi _lab_whisper_at=0 _lab_last_at=0 _lab_hint_n=0
typeset -ga _lab_dhairya=(
    'श्रद्धावाँल्लभते ज्ञानम् — the patient one attains'
    'उद्यमेन हि सिध्यन्ति कार्याणि न मनोरथैः — by effort, not by wishing, do works succeed'
    'धीरे धीरे रे मना, धीरे सब कुछ होय — slowly, slowly — everything, in its season'
)
_lab_whisper_line() {   # one verse line + its collection icon, from quotes/*.txt
    (( $+functions[_shlok_load] )) && _shlok_load 2>/dev/null
    if (( ${#_shlok_ids} )); then
        _shlok_pick '' || return 1
        local coll=${REPLY%%:*}
        print -rn -- "${_shlok_icon[$coll]} ${${(@f)_shlok_v[$REPLY]}[1]}"
    else
        print -rn -- '🪶 कर्मण्येवाधिकारस्ते मा फलेषु कदाचन'
    fi
}
_lab_whisper() {   # $1 = exit code
    (( ${PROMPT_WHISPER:-1} )) || return 1
    local -i now=${EPOCHSECONDS:-0}
    (( now - _lab_whisper_at >= ${PROMPT_WHISPER_GAP:-900} )) || return 1
    if [[ $1 == 0 ]] && (( ${_pr_elapsed_s:-0} >= 30 )); then
        print -P "   %F{243}🕊️  ${_lab_dhairya[RANDOM % ${#_lab_dhairya} + 1]}%f"
    elif (( _lab_last_at && now - _lab_last_at >= 1800 )); then
        print -P "   %F{243}🪷 पुनः स्वागतम् — $(_lab_whisper_line)%f"
    elif (( ${_pr_cmds:-0} % 108 == 54 )); then       # the half-माला
        local hint=''
        (( ++_lab_hint_n <= 3 )) && hint=" %F{240}· Alt-G%f"
        print -P "   %F{243}$(_lab_whisper_line)${hint}%f"
    else
        return 1
    fi
    _lab_whisper_at=$now
    return 0
}

# ── 🪔 बेला: greeting for the hour ───────────────────────────────────────────
# From the second साधना level on, the greeting knows your title (day one shows
# nothing new — the title is earned, then it simply starts being used).
bela() {
    local -i h=$(_lab_hour) lvl=$(_lab_title)
    local who=''
    (( lvl >= 2 )) && who=", ${_lab_titles[lvl]}"
    if   (( h >= 5  && h < 11 )); then print -P "   %F{215}🌅 सुप्रभात${who}%f %F{243}— a fresh page%f"
    elif (( h >= 11 && h < 16 )); then print -P "   %F{220}☀️  नमस्कार${who}%f %F{243}— midday steadiness%f"
    elif (( h >= 16 && h < 20 )); then print -P "   %F{208}🪔 शुभ संध्या${who}%f %F{243}— light the diya%f"
    else
        local moon=''
        (( $+functions[_pr_moon] )) && { _pr_moon; moon=" · ${_pr_moon_icon} ${_pr_moon_name}" }
        print -P "   %F{147}🌙 शुभ रात्रि${who}%f %F{243}— the quiet hours${moon}%f"
    fi
}

# ── 🛤️ cd greeting: returning to a forgotten repo earns one honest line ──────
# Fires only when the git toplevel changes, once per repo per session, and only
# after ≥7 quiet days. Honest phrasing: git knows commits, not visits.
typeset -gA _lab_visited
_lab_chpwd() {
    local top
    top=$(command git rev-parse --show-toplevel 2>/dev/null) || return 0
    [[ -n $top && -z ${_lab_visited[$top]} ]] || return 0
    _lab_visited[$top]=1
    local -i ct
    ct=$(command git -C "$top" log -1 --format=%ct 2>/dev/null) || return 0
    (( ct )) || return 0
    local -i days=$(( (${EPOCHSECONDS:-$ct} - ct) / 86400 ))
    (( days >= 7 )) || return 0
    print -P "   %F{243}🛤️  ${top:t} फिर से — last commit here: ${days} days ago%f"
}

# ── 🎆 उत्सव: festival modes ─────────────────────────────────────────────────
# The day makes the moment; the user makes the palette. Dates come from
# festivals.txt (verified, New Delhi convention); fixed days live in code.
# On the day: banner auto-shows, and the ≤2s one-shot effect plays ONCE
# globally (sessions/festival.stamp) — later shells get the static banner.
# Any key skips an animation instantly. Not a tty / narrow / no zselect →
# static banner. `lab festival <key>` previews any of them, any day.
typeset -gA _lab_fest_icon _lab_fest_name _lab_fest_tag _lab_fest_ramp _lab_fest_fx
_lab_fest_def() {
    _lab_fest_icon[$1]=$2; _lab_fest_name[$1]=$3
    _lab_fest_tag[$1]=$4;  _lab_fest_ramp[$1]=$5; _lab_fest_fx[$1]=${6:-banner}
}
_lab_fest_def sankranti   🪁 'मकर संक्रांति'  'kites on the north wind, til-gud sweetness' '208 214 220 45 39 214'
_lab_fest_def vasant      🌼 'वसंत पंचमी'     'mustard-field yellow, सरस्वती की वीणा'      '226 220 190 184 228'
_lab_fest_def shivaratri  🔱 'महाशिवरात्रि'   'the still night — ॐ नमः शिवाय'              '17 39 28 250 255 245'
_lab_fest_def holi        🎨 'होली है!'        'a play of colors'                           '201 196 202 220 46 51 129' holi
_lab_fest_def ramnavami   🏹 'राम नवमी'       'अयोध्या में जन्म, धनुष की टंकार'             '208 214 220 178 172'
_lab_fest_def hanuman     🚩 'हनुमान जयंती'   'संकटमोचन का जन्मदिवस'                       '196 202 208 214 220'
_lab_fest_def baisakhi    🌾 'बैसाखी'         'the wheat is gold, the harvest is home'     '178 184 190 220 226 100'
_lab_fest_def gurupurnima 🪷 'गुरु पूर्णिमा'  'to the one who lights the lamp within'      '255 253 251 189 183'
_lab_fest_def rakhi       🎀 'रक्षाबंधन'      'a thread stronger than armour'              '204 211 218 225 219'
_lab_fest_def janmashtami 🦚 'जन्माष्टमी'     'midnight in Mathura, माखन everywhere'       '18 45 38 220 230 205'
_lab_fest_def ganesh      🐘 'गणेश चतुर्थी'   'विघ्नहर्ता arrives, मोदक ready'              '208 214 220 202 196'
_lab_fest_def dussehra    🏹 'विजयादशमी'      'good keeps its old promise'                 '202 208 214 220 226'
_lab_fest_def diwali      🪔 'शुभ दीपावली'    'rows of lamps for the return home'          '202 208 214 220 226' fireworks
_lab_fest_def chhath      🌅 'छठ पूजा'        'standing in the river, facing the sun'      '166 208 220 31 223 180' sunrise
_lab_fest_def lohri       🔥 'लोहड़ी'          'the bonfire, the rewri, the songs'          '202 208 214 220 180 17' deepmala
_lab_fest_def onam        🌸 'ओणम्'           'pookalam rings for the King who visits'     '226 220 214 208 196 201 255' pookalam
_lab_fest_def gurpurab    ☬  'गुरपुरब'        'प्रकाश पर्व — a deepmala for Guru Nanak'    '220 226 229 254 214' deepmala
_lab_fest_def christmas   🎄 'Merry Christmas' 'stars over a quiet stable'                 '22 28 34 196 203 255'
_lab_fest_def newyear     🕯️ 'नव वर्ष शुभ हो' 'candles for the year ahead'                 '220 226 190 213 219' deepmala

_lab_fest_today() {   # -> key in $REPLY when today is a festival
    local today=${(%):-%D{%Y-%m-%d}}
    case ${today[6,10]} in
        01-01) REPLY=newyear;   return 0 ;;
        01-13) REPLY=lohri;     return 0 ;;
        12-25) REPLY=christmas; return 0 ;;
    esac
    local f="$PROMPT_HOME/festivals.txt" d k
    [[ -r $f ]] || return 1
    while read -r d k; do
        [[ ${d[1]} == '#' || -z $k ]] && continue
        [[ $d == $today ]] && { REPLY=$k; return 0 }
    done < $f
    return 1
}

# animation plumbing: sub-second frames via zselect, any keypress skips
typeset -gi _lab_fx_skip=0
_lab_fx_tick() {   # [centiseconds]
    local k
    if read -sk1 -t 0 k 2>/dev/null; then _lab_fx_skip=1; return 1; fi
    zselect -t ${1:-8} 2>/dev/null
    return 0
}
_lab_fx_banner() {   # the static fallback — and the whole show off-day
    local k=$1
    print
    _pr_grad "   ✦ ${_lab_fest_icon[$k]}  ${_lab_fest_name[$k]}  ${_lab_fest_icon[$k]} ✦" 0 ${=_lab_fest_ramp[$k]}
    print -P "   %F{243}${_lab_fest_tag[$k]}%f"
    print
}
_lab_fx_play() {   # dispatch with degrade guards; cursor hidden, always restored
    local k=$1
    if [[ ! -t 1 || $TERM == (dumb|linux) ]] || (( ${COLUMNS:-0} < 60 )) \
        || ! zmodload zsh/zselect 2>/dev/null; then
        _lab_fx_banner $k; return
    fi
    _lab_fx_skip=0
    print -n $'\e[?25l'
    {
        _lab_fx_${_lab_fest_fx[$k]:-banner} $k
    } always {
        print -n $'\e[?25h\e[0m'
    }
}

_lab_fx_pk() {   # poke char $3 into row $1 col $2 of the caller's $sky
    (( $2 >= 1 && $2 <= W )) || return 0
    local t=${sky[$1]}; t[$2]=$3; sky[$1]=$t
}
_lab_fx_render() {   # repaint the caller's $sky ($H rows) in place
    local -i r
    print -n "\e[${H}A\r"
    for (( r = 1; r <= H; r++ )); do
        print -P "   %F{${fxc[(( (r - 1) % ${#fxc} + 1 ))]}}${sky[r]}%f\e[K"
    done
}

_lab_fx_fireworks() {   # 3 staggered bursts over a persistent night sky
    local k=$1
    local -i W=$(( ${COLUMNS:-72} - 8 )) H=6 b f x r
    (( W > 56 )) && W=56
    local -a sky fxc=(226 220 214 208 213 220)
    for (( r = 1; r <= H; r++ )); do sky[r]=${(l:W:: :)}; print; done
    for b in 1 2 3; do
        x=$(( 7 + RANDOM % (W - 14) ))
        for f in 0 1 2; do                                # rise
            _lab_fx_pk $(( H - f )) $x '·'; _lab_fx_render; _lab_fx_pk $(( H - f )) $x ' '
            _lab_fx_tick 6 || break
        done
        _lab_fx_pk 3 $x '✦'; _lab_fx_render; _lab_fx_tick 9
        _lab_fx_pk 2 $x '✧'; _lab_fx_pk 4 $x '✧'          # bloom
        _lab_fx_pk 3 $(( x - 2 )) '✦'; _lab_fx_pk 3 $(( x + 2 )) '✦'
        _lab_fx_render; _lab_fx_tick 9
        _lab_fx_pk 1 $x '·'; _lab_fx_pk 2 $(( x - 2 )) '·'; _lab_fx_pk 2 $(( x + 2 )) '·'
        _lab_fx_pk 3 $(( x - 4 )) '·'; _lab_fx_pk 3 $(( x + 4 )) '·'
        _lab_fx_pk 4 $(( x - 2 )) '·'; _lab_fx_pk 4 $(( x + 2 )) '·'
        _lab_fx_render
        (( _lab_fx_skip )) && break
        _lab_fx_tick 7 || break
    done
    _lab_fx_render
    print -P "   %F{220}🪔 🪔 🪔 🪔 🪔 🪔 🪔%f"
    print -P "   %F{215}${_lab_fest_name[$k]}%f %F{243}— ${_lab_fest_tag[$k]}%f"
    print
}

_lab_fx_holi() {   # gulal accumulates line by line; the art stays behind
    local k=$1 line
    local -i W=$(( ${COLUMNS:-72} - 10 )) r i x n last
    (( W > 52 )) && W=52
    local -a cols=(${=_lab_fest_ramp[$k]}) dots=('●' '∘' '•' '✿' '·')
    print
    for r in 1 2 3 4 5; do
        line='' last=0
        n=$(( 4 + RANDOM % 4 ))
        for (( i = 1; i <= n; i++ )); do
            x=$(( last + 1 + RANDOM % (W / n) ))
            line+="${(l:$(( x - last )):: :)}%F{${cols[RANDOM % ${#cols} + 1]}}${dots[RANDOM % ${#dots} + 1]}%f"
            last=$(( x + 1 ))
        done
        print -P "   $line"
        (( _lab_fx_skip )) || _lab_fx_tick 12
    done
    print -P "   %F{213}${_lab_fest_name[$k]}%f %F{243}— ${_lab_fest_tag[$k]}%f"
    print
}

_lab_fx_deepmala() {   # lamps kindle one by one, left to right — reverent, no burst
    # wide-safe glyphs only inside the redrawn region (tmux disagrees with the
    # terminal about emoji width; the VS16 forms lie to wcwidth outright)
    local k=$1 line
    local -i f i lit=0
    print
    [[ $k == gurpurab ]] && _pr_grad '                 ੴ' 0 ${=_lab_fest_ramp[$k]}
    local flame='✦' body='│'
    [[ $k == lohri ]] && { flame='▲'; body='▲'; }
    print; print
    for (( f = 0; f <= 8; f++ )); do
        print -n $'\e[2A\r'
        line='   ' ; local under='   '
        for i in 1 2 3 4 5 6 7 8; do
            if (( i <= f )); then line+="${flame} "; under+="${body} "
            else                  line+='· ';        under+='  '; fi
        done
        print -P "%F{220}${line}%f\e[K"
        print -P "%F{208}${under}%f\e[K"
        (( _lab_fx_skip )) && break
        _lab_fx_tick 12 || break
    done
    print -P "   %F{215}${_lab_fest_icon[$k]} ${_lab_fest_name[$k]}%f %F{243}— ${_lab_fest_tag[$k]}%f"
    print
}

_lab_fx_pookalam() {   # the flower carpet grows ring by ring
    local k=$1
    local -i H=5 f
    local -a fxc=(${=_lab_fest_ramp[$k]}) sky
    local -a c=( '' '' '             ❁' '' '' )
    local -a m=( '' '         ·  ✿  ·' '      ✿  ❁  ✿' '         ·  ✿  ·' '' )
    local -a o=( '            ❀' '      ❀  ✿  ✿  ❀' '   ❀  ✿  ❁  ✿  ❀' '      ❀  ✿  ✿  ❀' '            ❀' )
    print
    sky=("${c[@]}");  for f in 1 2 3 4 5; do print; done
    _lab_fx_render; _lab_fx_tick 22
    sky=("${m[@]}");  _lab_fx_render; _lab_fx_tick 22
    sky=("${o[@]}");  _lab_fx_render
    print -P "   %F{215}${_lab_fest_name[$k]}%f %F{243}— ${_lab_fest_tag[$k]}%f"
    print
}

_lab_fx_sunrise() {   # छठ: the sun climbs out of the river — austere, no glitter
    local k=$1
    local -i H=4 f
    local -a fxc=(226 220 214 45) sky
    print
    for f in 1 2 3 4; do print; done
    local water="  ${(l:44::~:)}"
    local -a frames=( 4 3 2 )
    local -i row
    for row in $frames; do
        sky=( '' '' '' "$water" )
        (( row == 4 )) && sky[4]="  ~~~~~~~~~~~~~~~~~~~~◉~~~~~~~~~~~~~~~~~~~~~~~"
        (( row < 4 ))  && sky[row]="${(l:22:: :)}◉"
        (( row == 2 )) && sky[3]="${(l:21:: :)}· · ·"
        _lab_fx_render
        (( _lab_fx_skip )) && break
        _lab_fx_tick 20 || break
    done
    print -P "   %F{215}${_lab_fest_name[$k]}%f %F{243}— ${_lab_fest_tag[$k]}%f"
    print
}

# ── wiring (hooks consume $_pr_last set by the engine's precmd) ──────────────
_lab_preexec() { _lab_ran=1 }
_lab_precmd() {
    (( _lab_ran )) || return 0
    _lab_ran=0
    local code=${_pr_last:-0}
    # single voice: the first speaker wins, everyone after stays quiet
    _lab_combo_step $code \
        || _lab_empathy $code \
        || { (( _lab_wild )) && [[ $code == 0 ]] && _lab_shubh } \
        || _lab_whisper $code
    _lab_evolve
    _lab_last_at=${EPOCHSECONDS:-0}
}
_lab_save() { print -r -- $(_lab_total) > "$PROMPT_HOME/sadhana" 2>/dev/null }

typeset -g _lab_rprompt_saved=''
typeset -gi _lab_on=0 _lab_wild=0
lab() {
    case ${1:-status} in
        on)
            if (( $+functions[_dl_precmd] )); then
                print -P '%F{174}lab: the blessed set now ships in delights.zsh (already active) —%f'
                print -P '%F{174}`lab on` would double every whisper. `lab on wild` still adds सखी+combo.%f'
                [[ ${2:-} == wild ]] || return 1
            fi
            (( _lab_on )) && { print -P '%F{243}lab: already on%f'; return }
            autoload -Uz add-zsh-hook
            add-zsh-hook preexec _lab_preexec
            add-zsh-hook precmd  _lab_precmd
            add-zsh-hook chpwd   _lab_chpwd
            add-zsh-hook zshexit _lab_save
            _lab_rprompt_saved=$RPROMPT
            if [[ ${2:-} == wild ]]; then   # the UX-vetoed extras, if you insist
                _lab_wild=1
                RPROMPT="${RPROMPT}"'$(_pr_combostr)$(_pr_petstr)'
            fi
            _lab_on=1
            bela
            local extras=''; (( _lab_wild )) && extras=' · सखी + ⚡ combo ride the right prompt'
            print -P "   %F{243}lab on — empathy · whisper · cd-greetings armed${extras}%f"
            # festival day? banner always; the animated moment once per day, globally
            if _lab_fest_today; then
                local fk=$REPLY stamp="$PROMPT_HOME/sessions/festival.stamp"
                local today=${(%):-%D{%Y-%m-%d}}
                if [[ ! -r $stamp || "$(<$stamp)" != $today ]]; then
                    print -r -- $today > $stamp 2>/dev/null
                    _lab_fx_play $fk
                else
                    _lab_fx_banner $fk
                fi
            fi
            ;;
        off)
            (( _lab_on )) || return 0
            add-zsh-hook -d preexec _lab_preexec
            add-zsh-hook -d precmd  _lab_precmd
            add-zsh-hook -d chpwd   _lab_chpwd
            add-zsh-hook -d zshexit _lab_save
            _lab_save
            RPROMPT=$_lab_rprompt_saved
            _lab_on=0 _lab_wild=0
            print -P '%F{243}lab off — everything restored%f'
            ;;
        status)
            local -i t=$(_lab_total) s=$(_lab_stage $(_lab_total)) lvl=$(_lab_title)
            local -i next=0
            (( s < ${#_lab_stage_at} )) && next=$(( _lab_stage_at[s+1] - t ))
            print
            print -P "   ${_lab_stages[s]} %B%F{215}आपकी सखी%f%b %F{243}· ${_lab_stage_names[s]} · ${t} lifetime commands · $(( t / 108 )) माला · साधना: ${_lab_titles[lvl]}%f"
            (( next > 0 )) && print -P "   %F{243}   ${next} commands until ${_lab_stages[s+1]}%f"
            (( _lab_combo_best >= 5 )) && print -P "   %F{220}⚡%f %F{243}best streak this session: ${_lab_combo_best}%f"
            print
            ;;
        demo) lab-demo ;;
        festival|fest)
            if [[ -z $2 ]]; then
                local k
                print
                if _lab_fest_today; then
                    print -P "   %F{220}आज: ${_lab_fest_icon[$REPLY]} ${_lab_fest_name[$REPLY]}%f"
                else
                    print -P "   %F{243}no festival today — the day makes the moment%f"
                fi
                print
                for k in ${(ok)_lab_fest_name}; do
                    print -P "   ${_lab_fest_icon[$k]} $(printf '%-12s' $k) %F{243}${_lab_fest_name[$k]} — ${_lab_fest_tag[$k]}%f"
                done
                print -P "\n   %F{243}lab festival <key> previews its moment (in production the animation is day-locked)%f"
                print
            elif [[ -n ${_lab_fest_name[$2]} ]]; then
                _lab_fx_play $2
            else
                print -P "lab: unknown festival '$2' (lab festival lists them)"
            fi ;;
        *) print -P 'usage: lab on [wild]|off|status|festival [name]|demo' ;;
    esac
}

# ── the scripted tour: every moment, no waiting, nothing persisted ───────────
_lab_frame() {   # a fake two-line prompt with RPROMPT segments drawn at right
    local dirty='' right="$(_pr_combostr)$(_pr_petstr)"
    [[ -n $1 ]] && dirty=' %F{204}●%f'
    print -P "   %F{75}「~/projects/zion」%f %F{43}on%f %F{84}main%f${dirty}"
    print -P "   %F{84}❯%f %F{250}${2}%f%F{243}${right}%f"
}
lab-demo() {
    emulate -L zsh
    local -i sad_save=$_lab_sadhana cmds_save=${_pr_cmds:-0}
    local -i combo_save=$_lab_combo fails_save=$_lab_fails seen_save=$_lab_seen_stage
    local -i wild_save=$_lab_wild
    typeset -gi _pr_cmds
    _lab_sadhana=0 _pr_cmds=0 _lab_combo=0 _lab_fails=0 _lab_seen_stage=1 _lab_wild=1

    print; _pr_grad '   ▄▀█ playful-lab █▀▄' 2; print
    print -P '   %F{243}━━ act I · the wild ideas (with the UX designer'\''s verdict) ━━%f'
    print
    print -P '   %F{243}① सखी the companion — hatches at 108, sleeps at night, droops on failure.%f'
    _lab_hour_override=9; _lab_frame '' 'git status'
    _pr_cmds=108; _lab_evolve
    print -P '   %F{174}   verdict: kill — the peacock IS the pet; the prompt already reacts.%f'
    print
    print -P '   %F{243}② combo streak — speaks at ≥5, a 💥 when a big one dies.%f'
    _lab_combo=23; _lab_combo_step 1; _lab_combo_step 1; _lab_frame yes './deploy.sh'
    print -P '   %F{174}   verdict: kill — a streak counter is attachment to फल; the feather trail already shows the run.%f'
    print
    print -P '   %F{243}③ random rare events (~1 in 200):%f'
    _pr_grad '   ☄️  शुभ संकेत — something good is coming ✨' 3
    print -P '   %F{174}   verdict: kill the RNG — rarity must be earned by calendar or count, never by dice.%f'
    print
    _lab_wild=0
    print -P '   %F{243}━━ act II · the blessed set (one voice, silence is the default) ━━%f'
    print
    print -P '   %F{243}④ बेला — the greeting knows the hour, and one day, your साधना title.%f'
    _lab_hour_override=9; _lab_sadhana=12000; bela
    _lab_hour_override=23; bela
    _lab_sadhana=0
    print
    print -P '   %F{243}⑤ a typo — empathy, only for codes with a meaning (127, 130), once per class.%f'
    _lab_empathy_at=0; _lab_empathy 127
    print
    print -P '   %F{243}⑥ a 4-minute build finally lands — धैर्य, success-twin of the karma line.%f'
    print -P "   %F{243}🕊️  ${_lab_dhairya[2]}%f"
    print
    print -P '   %F{243}⑦ back after lunch — a welcome and a half-verse from your own collections.%f'
    print -P "   %F{243}🪷 पुनः स्वागतम् — $(_lab_whisper_line)%f"
    print
    print -P '   %F{243}⑧ the 54th command — a half-माला earns one ambient line; Alt-G opens the card.%f'
    print -P "   %F{243}$(_lab_whisper_line) %F{240}· Alt-G%f"
    print
    print -P '   %F{243}⑨ cd into a repo untouched for weeks — one honest line, once per session.%f'
    print -P "   %F{243}🛤️  bookbase फिर से — last commit here: 19 days ago%f"
    print
    print -P '   %F{243}⑩ पूर्णिमा — on the true full moon the verse card turns moonlight silver.%f'
    _pr_grad '   ✦ ॐ श्रीमद्भगवद्गीता · पूर्णिमा ✦' 0 255 253 251 249 251 253 255
    print
    print -P '   %F{243}⑪ उत्सव — on the festival day, once, skippable by any key:%f'
    _lab_fx_play diwali
    _lab_fx_play holi
    print -P '   %F{243}(19 festivals in the registry — `lab festival` lists them, festivals.txt holds%f'
    print -P '   %F{243}verified dates through 2030. The day makes the moment; you make the palette.)%f'
    print
    print -P '   %F{243}try it live in this shell:%f %F{215}lab on%f  %F{243}· सखी/combo stay demo-only unless you veto the verdicts%f'
    print

    _lab_sadhana=$sad_save _pr_cmds=$cmds_save _lab_combo=$combo_save
    _lab_fails=$fails_save _lab_seen_stage=$seen_save _lab_hour_override=-1
    _lab_wild=$wild_save
}

# `zsh lab.zsh demo` — run the tour directly, no install needed.
[[ ${ZSH_EVAL_CONTEXT:-} == toplevel && ${1:-} == demo ]] && lab-demo
