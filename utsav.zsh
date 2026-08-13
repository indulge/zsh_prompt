# utsav.zsh — उत्सव: festival modes for playful-zsh. Sourced by init.zsh.
#
# The two rules everything here obeys:
#   the day makes the moment; the user makes the palette — and
#   silence is the default; any keypress skips any animation.
#
# ARCHITECTURE — five layers, each usable without the ones above it:
#
#   §1 DATA        festivals.txt (verified dates) + a flat registry:
#                  _utsav[key:field] → icon · name · tag · ramp · fx · amb
#   §2 FRAME KIT   the only code that touches the terminal: guards, cursor
#                  hygiene, region reserve/repaint, zselect ticks, key-skip.
#                  Contract: an effect defines sky/H/W/fxc; the kit paints.
#   §3 EFFECTS     15 archetype functions (_ufx_*). A festival binds one via
#                  its fx field; per-festival flavor lives in a case inside
#                  the archetype, so the registry stays data-only.
#                  grand = the day-one showpiece (custom for diwali, generic
#                  marquee+mini for the rest). mini = summonable ≤1.5s.
#   §4 AMBIENCE    while-you-work micro-moments, day-locked and rare: a
#                  self-erasing firework spark on Diwali, a silver moon-glow
#                  on Guru Purnima. They vanish without a trace in scrollback.
#   §5 INTEGRATION `utsav` command · Alt-J replays today's/last effect ·
#                  `theme utsav` opens a browse-and-preview panel (production:
#                  folds into menu.zsh's picker as an [f] उत्सव section).
#
# Degrade ladder everywhere: animation → static banner → nothing (no tty).
# Any keypress skips any animation. Religious symbols render static, whole.
#
#   utsav              today's status
#   utsav play [key]   mini effect (no key: today's)
#   utsav grand [key]  the day-one showpiece
#   utsav day          what a shell runs on a festival morning (stamp-aware)
#   utsav list         every festival, one line each
#   utsav on|off       arm / disarm ambience (and off restores `theme`)
#   Alt-J              replay today's (or last previewed) effect, any time
#                      (PROMPT_UTSAV_KEY to rebind; only binds free keys)
#   theme utsav [key]  preview panel / direct preview
#
# Knobs (set before the managed block): PROMPT_UTSAV=0 silences the whole
# system, PROMPT_UTSAV_AMBIENT=0 just the while-you-work micro-moments.

typeset -g PROMPT_HOME="${PROMPT_HOME:-${${(%):-%x}:A:h}}"
zmodload zsh/datetime 2>/dev/null

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

# ═══ §1 DATA ═════════════════════════════════════════════════════════════════
typeset -gA _utsav
_utsav_def() {   # key icon name tag ramp fx [amb]
    _utsav[$1:icon]=$2; _utsav[$1:name]=$3; _utsav[$1:tag]=$4
    _utsav[$1:ramp]=$5; _utsav[$1:fx]=$6;   _utsav[$1:amb]=${7:-}
}
#          key         icon name              tagline                                      ramp                        fx        amb
_utsav_def sankranti   🪁  'मकर संक्रांति'    'kites on the north wind, til-gud sweetness' '45 220 208 106 173 255'    rise
_utsav_def lohri       🔥  'लोहड़ी'            'the bonfire, the rewri, the songs'          '202 208 214 220 180 17'    kindle
_utsav_def vasant      🌼  'वसंत पंचमी'       'mustard-field yellow, सरस्वती की वीणा'      '226 220 184 178 255 154'   sweep
_utsav_def shivaratri  🔱  'महाशिवरात्रि'     'the still night — ॐ नमः शिवाय'              '17 39 28 250 255 245'      pulse
_utsav_def holi        🎨  'होली है!'          'a play of colors'                           '201 226 51 82 208 129'     splash
_utsav_def ramnavami   🏹  'राम नवमी'         'अयोध्या में जन्म, धनुष की टंकार'             '208 214 220 75 255'        rise
_utsav_def hanuman     🚩  'हनुमान जयंती'     'संकटमोचन का जन्मदिवस'                       '202 208 196 220 130'       sweep
_utsav_def baisakhi    🌾  'बैसाखी'           'the wheat is gold, the harvest is home'     '220 178 106 208 27'        sweep
_utsav_def gurupurnima 🪷  'गुरु पूर्णिमा'    'to the one who lights the lamp within'      '255 251 111 54 180 208'    bloom     glow
_utsav_def rakhi       🎀  'रक्षाबंधन'        'a thread stronger than armour'              '196 220 205 214 216'       thread
_utsav_def janmashtami 🦚  'जन्माष्टमी'       'midnight in Mathura, माखन everywhere'       '18 45 38 220 230 205'      twinkle
_utsav_def ganesh      🐘  'गणेश चतुर्थी'     'विघ्नहर्ता arrives, मोदक ready'              '202 214 220 70 196'        chant
_utsav_def navratri    🌺  'नवरात्रि'         'nine nights, nine colors'                   '208 255 196 21 226 40 245 129 43' band
_utsav_def dussehra    🏹  'विजयादशमी'        'good keeps its old promise'                 '202 208 214 220 226'       volley
_utsav_def diwali      🪔  'शुभ दीपावली'      'rows of lamps for the return home'          '202 208 214 220 226'       burst     spark
_utsav_def chhath      🌅  'छठ पूजा'          'standing in the river, facing the sun'      '166 208 220 31 223 180'    rise
_utsav_def onam        🌸  'ओणम्'             'pookalam rings for the King who visits'     '226 220 214 208 196 201 255' rings
_utsav_def gurpurab    ☬   'गुरपुरब'          'प्रकाश पर्व — a deepmala for Guru Nanak'    '220 226 229 254 214'       kindle
_utsav_def christmas   🎄  'Merry Christmas'  'stars over a quiet stable'                  '196 34 220 255 28'         snow
_utsav_def newyear     🕯️  'नव वर्ष शुभ हो'   'candles for the year ahead'                 '220 226 190 213 219 51'    countdown

typeset -ga _utsav_keys=(${(ok)${(M)${(k)_utsav}:#*:name}%:name})

# Memoized per date — ambience may ask on every gated prompt; the file is
# read at most once a day per shell.
typeset -g _utsav_today_d='' _utsav_today_k=''
_utsav_today() {   # -> key in $REPLY when today is a festival
    local today=${(%):-%D{%Y-%m-%d}}
    if [[ $today == $_utsav_today_d ]]; then
        REPLY=$_utsav_today_k
        [[ -n $REPLY ]]
        return
    fi
    _utsav_today_d=$today _utsav_today_k='' REPLY=''
    case ${today[6,10]} in
        01-01) _utsav_today_k=newyear ;;
        01-13) _utsav_today_k=lohri ;;
        12-25) _utsav_today_k=christmas ;;
        *)
            local f="$PROMPT_HOME/festivals.txt" d k
            if [[ -r $f ]]; then
                while read -r d k; do
                    [[ ${d[1]} == '#' || -z $k || -z ${_utsav[$k:name]} ]] && continue
                    [[ $d == $today ]] && { _utsav_today_k=$k; break }
                done < $f
            fi ;;
    esac
    REPLY=$_utsav_today_k
    [[ -n $REPLY ]]
}

# ═══ §2 FRAME KIT ════════════════════════════════════════════════════════════
# Effects declare:  H (rows) · W (cols) · sky (row strings) · fxc (row colors)
# and speak to the terminal only through these five functions.
typeset -gi _ufx_skip=0

_ufx_can_animate() {
    [[ -t 1 && $TERM != (dumb|linux) ]] && (( ${COLUMNS:-0} >= 60 )) \
        && zmodload zsh/zselect 2>/dev/null
}
_ufx_open() {   # $1 rows — hide cursor, reserve the region
    _ufx_skip=0
    print -n $'\e[?25l'
    local -i r; for (( r = 0; r < $1; r++ )); do print; done
}
_ufx_close() {  # restore cursor + colors, whatever happened
    print -n $'\e[?25h\e[0m'
}
_ufx_tick() {   # [centiseconds] — sleep one frame; any keypress skips the rest
    local k
    if read -sk1 -t 0 k 2>/dev/null; then _ufx_skip=1; return 1; fi
    zselect -t ${1:-7} 2>/dev/null
    return 0
}
_ufx_paint() {  # repaint sky[1..H] in place, row colors cycling through fxc
    local -i r
    print -n "\e[${H}A\r"
    for (( r = 1; r <= H; r++ )); do
        print -P "   %F{${fxc[(( (r - 1) % ${#fxc} + 1 ))]}}${sky[r]}%f\e[K"
    done
}
_ufx_pk() {     # poke char $3 into caller's sky, row $1 col $2 (bounds-safe)
    (( $1 >= 1 && $1 <= H && $2 >= 1 && $2 <= W )) || return 0
    local t=${sky[$1]}; t[$2]=$3; sky[$1]=$t
}
_ufx_sign() {   # the closing line every effect ends on
    print -P "   %F{215}${_utsav[$1:icon]} ${_utsav[$1:name]}%f %F{243}— ${_utsav[$1:tag]}%f"
    print
}

# ═══ §3 EFFECTS ══════════════════════════════════════════════════════════════
_ufx_banner() {   # the static fallback — and the off-day preview artifact
    local k=$1
    print
    _pr_grad "   ✦ ${_utsav[$k:icon]}  ${_utsav[$k:name]}  ${_utsav[$k:icon]} ✦" 0 ${=_utsav[$k:ramp]}
    print -P "   %F{243}${_utsav[$k:tag]}%f"
    print
}

_ufx_burst_sky() {   # shared by mini burst + grand diwali: $1 bursts, on caller's sky
    local -i b f x
    for (( b = 1; b <= $1; b++ )); do
        x=$(( 7 + RANDOM % (W - 14) ))
        for f in 0 1 2; do
            _ufx_pk $(( H - f )) $x '·'; _ufx_paint; _ufx_pk $(( H - f )) $x ' '
            _ufx_tick 6 || return
        done
        _ufx_pk 3 $x '✦'; _ufx_paint; _ufx_tick 8 || return
        _ufx_pk 2 $x '✧'; _ufx_pk 4 $x '✧'
        _ufx_pk 3 $(( x - 2 )) '✦'; _ufx_pk 3 $(( x + 2 )) '✦'
        _ufx_paint; _ufx_tick 8 || return
        _ufx_pk 1 $x '·'; _ufx_pk 2 $(( x - 2 )) '·'; _ufx_pk 2 $(( x + 2 )) '·'
        _ufx_pk 3 $(( x - 4 )) '·'; _ufx_pk 3 $(( x + 4 )) '·'
        _ufx_pk 4 $(( x - 2 )) '·'; _ufx_pk 4 $(( x + 2 )) '·'
        _ufx_paint; _ufx_tick 6 || return
    done
}

_ufx_burst() {   # diwali mini: three bursts, then the diya line
    local k=$1
    local -i W=$(( ${COLUMNS:-72} - 8 )) H=6 r
    (( W > 56 )) && W=56
    local -a sky fxc=(226 220 214 208 213 220)
    for (( r = 1; r <= H; r++ )); do sky[r]=${(l:W:: :)}; done
    _ufx_open $H; { _ufx_burst_sky 3; _ufx_paint } always { _ufx_close }
    print -P "   %F{220}🪔 🪔 🪔 🪔 🪔 🪔 🪔%f"
    _ufx_sign $k
}

_ufx_splash() {   # holi: gulal accumulates — the animation IS the final art
    local k=$1 line
    local -i W=$(( ${COLUMNS:-72} - 10 )) r i x n last
    (( W > 52 )) && W=52
    local -a cols=(${=_utsav[$k:ramp]}) dots=('●' '∘' '•' '✿' '·')
    print; _ufx_skip=0
    for r in 1 2 3 4 5; do
        line='' last=0; n=$(( 4 + RANDOM % 4 ))
        for (( i = 1; i <= n; i++ )); do
            x=$(( last + 1 + RANDOM % (W / n) ))
            line+="${(l:$(( x - last )):: :)}%F{${cols[RANDOM % ${#cols} + 1]}}${dots[RANDOM % ${#dots} + 1]}%f"
            last=$(( x + 1 ))
        done
        print -P "   $line"
        (( _ufx_skip )) || _ufx_tick 12
    done
    _ufx_sign $k
}

_ufx_kindle() {   # gurpurab/lohri: lamps light one by one — reverent, no burst
    local k=$1 line under flame='✦' body='│'
    local -i f i
    [[ $k == lohri ]] && { flame='▲'; body='▲'; }
    print
    [[ $k == gurpurab ]] && _pr_grad '                 ੴ' 0 ${=_utsav[$k:ramp]}
    _ufx_open 2
    {
        for (( f = 0; f <= 8; f++ )); do
            print -n $'\e[2A\r'
            line='   '; under='   '
            for i in {1..8}; do
                if (( i <= f )); then line+="${flame} "; under+="${body} "
                else                  line+='· ';        under+='  '; fi
            done
            print -P "%F{220}${line}%f\e[K"
            print -P "%F{208}${under}%f\e[K"
            (( _ufx_skip )) && break
            _ufx_tick 11 || break
        done
    } always { _ufx_close }
    _ufx_sign $k
}

_ufx_countdown() {   # newyear: 3 · 2 · 1 — candles flare — a moment of confetti
    local k=$1 line
    local -i f i
    print
    _ufx_open 2
    {
        for f in 3 2 1 0; do
            print -n $'\e[2A\r'
            if (( f )); then line="        ${f} …"
            else             line='   ✶ ✦ ✧ ✶ ✧ ✦ ✶'; fi
            print -P "%F{226}${line}%f\e[K"
            line='   '; for i in {1..5}; do (( f <= i % 3 + 1 )) && line+='✦ │  ' || line+='· │  '; done
            print -P "%F{220}${line}%f\e[K"
            (( _ufx_skip )) && break
            _ufx_tick $(( f ? 35 : 20 )) || break
        done
    } always { _ufx_close }
    _ufx_sign $k
}

_ufx_rings() {   # onam pookalam, ring by ring
    local k=$1
    local -i H=5
    local -a fxc=(${=_utsav[$k:ramp]}) sky
    local -a c=( '' '' '             ❁' '' '' )
    local -a m=( '' '         ·  ✿  ·' '      ✿  ❁  ✿' '         ·  ✿  ·' '' )
    local -a o=( '            ❀' '      ❀  ✿  ✿  ❀' '   ❀  ✿  ❁  ✿  ❀' '      ❀  ✿  ✿  ❀' '            ❀' )
    print
    _ufx_open $H
    {
        sky=("${c[@]}"); _ufx_paint; _ufx_tick 22
        sky=("${m[@]}"); _ufx_paint; _ufx_tick 22
        sky=("${o[@]}"); _ufx_paint
    } always { _ufx_close }
    _ufx_sign $k
}

_ufx_rise() {   # something climbs: a kite, the sun, the moon, a pennant
    local k=$1
    local -i H=4 W=50 row
    local -a sky fxc
    print
    _ufx_open $H
    {
        case $k in
            sankranti)   # ◆ kite with a swaying tail
                fxc=(45 45 45 106)
                for row in 4 3 2 1; do
                    sky=( '' '' '' '' ); sky[row]="${(l:24:: :)}◆"
                    (( row < 4 )) && sky[row+1]="${(l:$(( 23 + (row % 2) * 2 )):: :)}/"
                    sky[4]='  ·  ˚     ·      ˚   ·    ☀'
                    _ufx_paint; (( _ufx_skip )) && break; _ufx_tick 16 || break
                done ;;
            chhath)      # the sun out of the river — slow, austere
                fxc=(226 220 214 31)
                local water="  ${(l:44::~:)}"
                for row in 4 3 2; do
                    sky=( '' '' '' "$water" )
                    (( row == 4 )) && sky[4]="  ${(l:20::~:)}◉${(l:23::~:)}"
                    (( row < 4 ))  && sky[row]="${(l:22:: :)}◉"
                    (( row == 2 )) && sky[3]="${(l:21:: :)}· · ·"
                    _ufx_paint; (( _ufx_skip )) && break; _ufx_tick 20 || break
                done ;;
            ramnavami)   # the pennant goes up the mast
                fxc=(208 214 220 178)
                for row in 4 3 2 1; do
                    sky=( '' "${(l:24:: :)}│" "${(l:24:: :)}│" "${(l:24:: :)}│" )
                    sky[row]="${(l:24:: :)}▲${${row:#4}:+~}"
                    _ufx_paint; (( _ufx_skip )) && break; _ufx_tick 14 || break
                done ;;
        esac
    } always { _ufx_close }
    _ufx_sign $k
}

_ufx_bloom() {   # gurupurnima: the moon brightens in place, then the shloka
    local k=$1 c
    local -a seq=( '☽' '○' '◉' '˚ ◉ ˚' )
    print
    _ufx_open 1
    {
        for c in "${seq[@]}"; do
            print -n $'\e[1A\r'
            print -P "%F{251}${(l:24:: :)}${c}%f\e[K"
            (( _ufx_skip )) && break
            _ufx_tick 16 || break
        done
    } always { _ufx_close }
    print -P "   %F{251}गुरुर्ब्रह्मा गुरुर्विष्णुः गुरुर्देवो महेश्वरः%f"
    _ufx_sign $k
}

_ufx_sweep() {   # a color floods the line left→right (sindoor, mustard, harvest)
    local k=$1 text accent dim=240
    local -i f n
    case $k in
        hanuman)  text='जय बजरंगबली'                accent=202 ;;
        vasant)   text='❀ विद्या ददाति विनयम् ❀'      accent=226 ;;
        baisakhi) text='● ਵਿਸਾਖੀ ● बैसाखी की बधाई ●'  accent=220 ;;
        *)        text=${_utsav[$k:name]}           accent=214 ;;
    esac
    n=${#text}
    print
    _ufx_open 1
    {
        for (( f = 2; f <= n + 1; f += 2 )); do
            print -n $'\e[1A\r'
            print -P "   %F{${accent}}${text[1,f]}%f%F{${dim}}${text[f+1,-1]}%f\e[K"
            (( _ufx_skip )) && break
            _ufx_tick 6 || break
        done
    } always { _ufx_close }
    _ufx_sign $k
}

_ufx_pulse() {   # shivaratri: the mantra breathes — nothing else moves
    local k=$1 text='ॐ नमः शिवाय'
    local -a breath=(239 245 250 255 250 245 239)
    local -i f
    print
    _ufx_open 1
    {
        for (( f = 1; f <= ${#breath}; f++ )); do
            print -n $'\e[1A\r'
            print -P "   %F{${breath[f]}}${(l:14:: :)}${text}%f\e[K"
            (( _ufx_skip )) && break
            _ufx_tick 13 || break
        done
    } always { _ufx_close }
    _ufx_sign $k
}

_ufx_band() {   # navratri: nine nights paint the line, one color each
    local k=$1 line=''
    local -a nine=(${=_utsav[$k:ramp]})
    local -i f
    print
    _ufx_open 1
    {
        for (( f = 1; f <= 9; f++ )); do
            line+="%F{${nine[f]}}━━━━ %f"
            print -n $'\e[1A\r'
            print -P "   ${line}\e[K"
            (( _ufx_skip )) && break
            _ufx_tick 14 || break
        done
    } always { _ufx_close }
    _ufx_sign $k
}

_ufx_twinkle() {   # janmashtami: the midnight starfield, then the birth
    local k=$1
    local -a fields=( '  ✦   ·    ✧     ·   ✦    ˚   ✧'
                      '  ✧   ˚    ✦     ·   ✧    ·   ✦'
                      '  ·   ✦    ˚     ✧   ·    ✦   ˚' )
    local -i f
    print
    _ufx_open 1
    {
        for (( f = 1; f <= 5; f++ )); do
            print -n $'\e[1A\r'
            print -P "%F{45}${fields[(( (f - 1) % 3 + 1 ))]}%f\e[K"
            (( _ufx_skip )) && break
            _ufx_tick 14 || break
        done
    } always { _ufx_close }
    print -P "   %F{220}नंद के आनंद भयो — जय कन्हैया लाल की%f 🦚"
    _ufx_sign $k
}

_ufx_snow() {   # christmas: flakes drift down and settle
    local k=$1
    local -i H=3 f
    local -a fxc=(255 255 250) sky
    local -a drift=( '   ❄     ·      ✧        ❄       ·'
                     '      ❄      ✧       ·       ❄'
                     '   ·      ❄       ❄      ✧       ❄' )
    print
    _ufx_open $H
    {
        for (( f = 1; f <= 6; f++ )); do
            sky=( "${drift[(( (f - 1) % 3 + 1 ))]}" "${drift[(( f % 3 + 1 ))]}" '' )
            (( f >= 4 )) && sky[3]='   . ✧ .   * .    . *   . ✧ .'
            _ufx_paint
            (( _ufx_skip )) && break
            _ufx_tick 13 || break
        done
    } always { _ufx_close }
    _ufx_sign $k
}

_ufx_thread() {   # rakhi: the thread draws from both ends; the knot blooms
    local k=$1
    local -i n=20 f
    print
    _ufx_open 1
    {
        for (( f = 1; f <= n / 2 + 1; f++ )); do
            print -n $'\e[1A\r'
            if (( f <= n / 2 )); then
                print -P "   %F{196}${(l:f::─:)}%f${(l:$(( n - 2 * f )):: :)}%F{196}${(l:f::─:)}%f\e[K"
            else
                print -P "   %F{196}${(l:$(( n / 2 - 1 ))::─:)}%f%F{220}✿%f%F{196}${(l:$(( n / 2 - 1 ))::─:)}%f\e[K"
            fi
            (( _ufx_skip )) && break
            _ufx_tick 8 || break
        done
    } always { _ufx_close }
    _ufx_sign $k
}

_ufx_chant() {   # ganesh: call — beat — response, marigolds settle
    local k=$1
    print
    print -P "   %F{208}गणपति बप्पा …%f"
    _ufx_tick 35
    print -P "   %F{214}❀ ✿ ❀ ✿ ❀%f  %B%F{220}मोरया!%f%b"
    _ufx_sign $k
}

_ufx_volley() {   # dussehra: the arrow crosses; what it strikes becomes light
    local k=$1
    local -i W=40 f
    print
    _ufx_open 1
    {
        for (( f = 1; f <= 5; f++ )); do
            print -n $'\e[1A\r'
            if (( f < 5 )); then
                print -P "   %F{220}${(l:$(( f * 7 )):: :)}──>%f${(l:$(( W - f * 7 - 3 )):: :)}%F{240}▲%f\e[K"
            else
                print -P "   ${(l:W:: :)}%F{220}✦%f %F{226}✧%f\e[K"
            fi
            (( _ufx_skip )) && break
            _ufx_tick 10 || break
        done
    } always { _ufx_close }
    _ufx_sign $k
}

# ── grand: the day-one showpiece ─────────────────────────────────────────────
_ufx_grand_diwali() {   # sky of fireworks → diyas kindle → DIWALI marquee
    local k=diwali line
    local -i W=$(( ${COLUMNS:-72} - 8 )) H=6 r f i
    (( W > 56 )) && W=56
    local -a sky fxc=(226 220 214 208 213 220)
    for (( r = 1; r <= H; r++ )); do sky[r]=${(l:W:: :)}; done
    _ufx_open $H
    { _ufx_burst_sky 4; _ufx_paint } always { _ufx_close }
    _ufx_open 2
    {
        for (( f = 0; f <= 4; f++ )); do              # diyas kindle, left to right
            print -n $'\e[2A\r'
            line='      '; for i in {1..4}; do (( i <= f )) && line+='✦      ' || line+='       '; done
            print -P "%F{220}${line}%f\e[K"
            print -P "      %F{208}△      △      △      △%f\e[K"
            (( _ufx_skip )) && break
            _ufx_tick 14 || break
        done
    } always { _ufx_close }
    _ufx_open 2
    {
        for (( f = 0; f <= 5; f++ )); do              # the name, as a marquee
            print -n $'\e[2A\r'
            _pr_grad '   █▀▄ █ █░█░█ ▄▀█ █░░ █' $f ${=_utsav[$k:ramp]}
            _pr_grad '   █▄▀ █ ▀▄▀▄▀ █▀█ █▄▄ █' $f ${=_utsav[$k:ramp]}
            (( _ufx_skip )) && break
            _ufx_tick 12 || break
        done
    } always { _ufx_close }
    print -P "   %F{220}🪔%f %B%F{215}${_utsav[$k:name]}%f%b %F{243}— ${_utsav[$k:tag]}%f %F{220}🪔%f"
    print
}
_ufx_grand() {   # generic showpiece: gradient marquee of the name, then the mini
    local k=$1
    local -i f
    if (( $+functions[_ufx_grand_$k] )); then _ufx_grand_$k; return; fi
    print
    _ufx_open 1
    {
        for (( f = 0; f <= 5; f++ )); do
            print -n $'\e[1A\r'
            _pr_grad "   ✦ ${_utsav[$k:icon]}  ${_utsav[$k:name]}  ${_utsav[$k:icon]} ✦" $f ${=_utsav[$k:ramp]}
            (( _ufx_skip )) && break
            _ufx_tick 11 || break
        done
    } always { _ufx_close }
    _utsav_play $k nosign
}

# ═══ §4 AMBIENCE ═════════════════════════════════════════════════════════════
# While-you-work micro-moments: day-locked, ≥20 min apart, ≥10 commands apart,
# then a 1-in-3 roll (the owner asked for "random, occasional"). Each one
# animates on a single line and erases itself — scrollback keeps no trace.
# PROMPT_UTSAV_AMBIENT=0 silences it entirely.
typeset -gi _uamb_at=0 _uamb_cmds=0

_uamb_spark() {   # diwali: a far-off firework, gone in a blink
    local -i pad=$(( 4 + RANDOM % 30 ))
    local -a fr=( '˚' '˚ ✦ ˚' '· ✧   ✧ ·' )
    local f
    for f in "${fr[@]}"; do
        print -Pn "\r${(l:pad:: :)}%F{220}${f}%f\e[K"
        _ufx_tick 8 || break
    done
    print -n $'\r\e[K'
}
_uamb_glow() {    # gurupurnima: the moon breathes once, silver, and fades
    local -a fr=( '˚' '˚ ☽ ˚' '˚ ✧ ☽ ✧ ˚' '˚ ☽ ˚' )
    local f
    for f in "${fr[@]}"; do
        print -Pn "\r${(l:20:: :)}%F{251}${f}%f\e[K"
        _ufx_tick 9 || break
    done
    print -n $'\r\e[K'
}
_utsav_amb_hook() {
    (( ${PROMPT_UTSAV_AMBIENT:-1} )) || return 0
    (( ${_pr_spoke:-0} )) && return 0     # the single voice already spoke
    (( ++_uamb_cmds ))
    local -i now=${EPOCHSECONDS:-0}
    (( now - _uamb_at >= 1200 && _uamb_cmds >= 10 )) || return 0
    (( RANDOM % 3 == 0 ))                            || return 0
    _utsav_today || return 0
    local amb=${_utsav[$REPLY:amb]}
    [[ -n $amb ]] && _ufx_can_animate || return 0
    _uamb_at=$now _uamb_cmds=0 _ufx_skip=0
    _uamb_$amb
}

# ═══ §5 INTEGRATION ══════════════════════════════════════════════════════════
typeset -g _utsav_current=''

_utsav_play() {   # mini effect with full degrade ladder
    local k=$1
    _utsav_current=$k
    if _ufx_can_animate; then _ufx_${_utsav[$k:fx]:-banner} $k
    else _ufx_banner $k; fi
    [[ $2 == nosign ]] || :
}
_utsav_grand_play() {
    local k=$1
    _utsav_current=$k
    if _ufx_can_animate; then _ufx_grand $k; else _ufx_banner $k; fi
}

_utsav_day() {   # what a shell runs on a festival morning — stamp-aware
    _utsav_today || { print -P '   %F{243}आज कोई उत्सव नहीं — the calendar makes the moment%f'; return 0 }
    local k=$REPLY stamp="$PROMPT_HOME/sessions/festival.stamp"
    local today=${(%):-%D{%Y-%m-%d}}
    if [[ ! -r $stamp || "$(<$stamp)" != $today ]]; then
        print -r -- $today > $stamp 2>/dev/null
        _utsav_grand_play $k          # first shell of the day: the showpiece
    else
        _ufx_banner $k                # every later shell: the quiet banner
    fi
}

_utsav_list() {
    local k
    print
    if _utsav_today; then print -P "   %F{220}आज: ${_utsav[$REPLY:icon]} ${_utsav[$REPLY:name]}%f\n"; fi
    for k in $_utsav_keys; do
        print -P "   ${_utsav[$k:icon]} $(printf '%-12s' $k) %F{243}${_utsav[$k:name]} — ${_utsav[$k:tag]}%f"
    done
    print -P "\n   %F{243}utsav play <key> · utsav grand <key> · theme utsav — browse with preview%f"
    print
}

# The preview panel: ↑↓/jk browse · ⏎ play · g grand · q quit.
# (Production home: an [f] उत्सव section inside menu.zsh's picker panel.)
_utsav_panel() {
    if ! [[ -t 1 ]] || ! (( $+functions[_pr_readkey] )); then _utsav_list; return; fi
    local -a keys=($_utsav_keys)
    local -i n=${#keys} sel=1 L=$(( n + 3 )) i drawn=0
    local k mark
    _utsav_panel_draw() {
        (( drawn )) && print -n "\e[${L}A\r"
        drawn=1
        print -P "  %F{220}✦ उत्सव — festival moments ✦%f\e[K"
        for (( i = 1; i <= n; i++ )); do
            k=${keys[i]}; mark='  '; (( i == sel )) && mark='%F{220}▸%f '
            print -P "  ${mark}${_utsav[$k:icon]} $(printf '%-12s' $k) %F{243}${_utsav[$k:name]}%f\e[K"
        done
        print -P "  %F{243}↑↓/jk browse · ⏎ play · g grand · q quit%f\e[K"
        print -n $'\e[K'
    }
    _utsav_panel_draw
    while _pr_readkey 60; do
        case $REPLY in
            up|k)   (( sel = sel > 1 ? sel - 1 : n )); _utsav_panel_draw ;;
            down|j) (( sel = sel < n ? sel + 1 : 1 )); _utsav_panel_draw ;;
            ''|$'\n'|$'\r') print; _utsav_play ${keys[sel]};  return ;;
            g)              print; _utsav_grand_play ${keys[sel]}; return ;;
            q|esc)  print; return ;;
        esac
    done
    print
}

# Wiring, installable and removable as a pair (`utsav on` / `utsav off`):
#   theme utsav [key]  — wrap the engine's theme() once, delegate everything else
#   Alt-J (जश्न)       — today's moment (or the last one you previewed), any time
_utsav_widget() {
    zle -I
    local k=''
    if _utsav_today; then k=$REPLY; elif [[ -n $_utsav_current ]]; then k=$_utsav_current; fi
    if [[ -n $k ]]; then _utsav_play $k
    else print -P '   %F{243}आज कोई उत्सव नहीं — theme utsav browses them all%f'; fi
    zle reset-prompt
}
# Applying a festival theme ON its own day earns the animation (the user
# asked; always deliver). Off-day it's just clothes — palette only.
_utsav_theme_moment() {
    _utsav_today && [[ $REPLY == $1 ]] && _utsav_play $1
    return 0
}
_utsav_arm() {
    # Wrap theme() unless the CURRENT body is already the wrapper — a stale
    # _utsav_theme_orig from a previous `source ~/.zshrc` must not stop us,
    # or `theme utsav` dies on every re-source.
    if (( $+functions[theme] )) && [[ ${functions[theme]} != *_utsav_theme_orig* ]]; then
        functions[_utsav_theme_orig]=$functions[theme]
        theme() {
            case $1 in
                utsav|festival)
                    if [[ -n $2 && -n ${_utsav[$2:name]} ]]; then _utsav_play $2
                    else _utsav_panel; fi
                    return 0 ;;
            esac
            # uniform day-jewel: whatever path changed the theme — explicit
            # name, panel apply, even `theme random` — gets the moment
            local _before=$_prompt_current
            _utsav_theme_orig "$@"
            local -i rc=$?
            [[ $_prompt_current != $_before && -n ${_utsav[$_prompt_current:name]:-} ]] \
                && _utsav_theme_moment $_prompt_current
            return $rc
        }
    fi
    _utsav_bind_key
}
# Bindable any time (init re-asserts at the first prompt — late plugins that
# rebuild keymaps would otherwise wipe us). Respects keys the user's setup
# already answers to, unless they chose one via PROMPT_UTSAV_KEY.
_utsav_bind_key() {
    [[ -o zle ]] || return 0
    zle -N utsav-play _utsav_widget
    local key=${PROMPT_UTSAV_KEY:-'\ej'}
    local cur="$(bindkey "$key")"
    if [[ -n $PROMPT_UTSAV_KEY || $cur == *(undefined-key|utsav-play)* ]]; then
        bindkey "$key" utsav-play
    fi
}
_utsav_arm

# ── init.zsh entry points ────────────────────────────────────────────────────
_utsav_startup() {   # the day moment — init calls this once, after the banner
    (( ${PROMPT_UTSAV:-1} )) || return 0
    [[ -t 1 ]] || return 0
    _utsav_today || return 0
    _utsav_day
}
_utsav_arm_ambient() {   # registered LAST so the single-voice flag is visible
    (( ${PROMPT_UTSAV:-1} )) || return 0
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _utsav_amb_hook
}

utsav() {
    case ${1:-today} in
        today)  if _utsav_today; then
                    print -P "   ${_utsav[$REPLY:icon]} %F{215}आज ${_utsav[$REPLY:name]}%f %F{243}— utsav day plays the morning moment%f"
                else
                    print -P '   %F{243}आज कोई उत्सव नहीं — utsav list shows the year%f'
                fi
                # hotkey health — if a key is bound here but does nothing when
                # pressed, something upstream (tmux, the terminal) is eating it
                local jk=${PROMPT_UTSAV_KEY:-'\ej'} j g
                j="$(bindkey "$jk" 2>/dev/null)" g="$(bindkey '\eg' 2>/dev/null)"
                print -P "   %F{243}keys: ${${j%% *}//\%/%%} → ${${j##* }:-?} · ${${g%% *}//\%/%%} → ${${g##* }:-?}%f"
                [[ $j == *utsav-play* && $g == *shlok-random* ]] \
                    || print -P '   %F{174}   a key is not ours — a later plugin took it, or set PROMPT_UTSAV_KEY%f'
                [[ -n $TMUX ]] && print -P '   %F{243}   in tmux: `tmux list-keys | grep -i "M-j\\|M-g"` shows if tmux eats them first%f' ;;
        play)   _utsav_play ${2:-${$(_utsav_today && print $REPLY):-diwali}} ;;
        grand)  _utsav_grand_play ${2:-diwali} ;;
        day)    _utsav_day ;;
        list)   _utsav_list ;;
        panel)  _utsav_panel ;;
        on)     autoload -Uz add-zsh-hook; add-zsh-hook precmd _utsav_amb_hook
                _utsav_arm
                print -P '   %F{243}utsav on — ambience armed (day-locked, rare, self-erasing)%f' ;;
        off)    add-zsh-hook -d precmd _utsav_amb_hook 2>/dev/null
                if (( $+functions[_utsav_theme_orig] )); then
                    functions[theme]=$functions[_utsav_theme_orig]
                    unfunction _utsav_theme_orig
                fi
                bindkey -r "${PROMPT_UTSAV_KEY:-\ej}" 2>/dev/null
                print -P '   %F{243}utsav off — hooks, Alt-J and theme restored%f' ;;
        help|*) print -P 'usage: utsav [today]|play [key]|grand [key]|day|list|panel|on|off' ;;
    esac
}
