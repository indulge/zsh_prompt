# ~/.prompt/menu.zsh — `theme`: a full-screen theme picker in the hop family.
# Browse every theme with ↑↓/jk — the panel re-chromes itself and the preview
# re-renders in the highlighted theme's colors: its two-line prompt sample
# (path, git branch, dirty dot, arrows) and its file colors (folder, file,
# symlink, executable, pipe, archive, image, broken link). Effects toggle
# live: g = ✨ glow, p = full paths. ⏎ applies + persists, q keeps your theme.
# Pure zsh + ANSI escapes; ASCII borders in non-UTF-8 locales (HOP_ASCII=1).

[[ -o interactive ]] || return

if (( ${HOP_ASCII:-0} )) || [[ ${(U)LANG}${(U)LC_ALL} != *UTF*8* ]]; then
    typeset -g  _thm_utf=0
    typeset -g _thm_tl='+' _thm_hh='=' _thm_v='|' _thm_ml='+' _thm_h2='-' \
               _thm_bl='+' _thm_ptr='>' _thm_chk='*' _thm_dot='.'
else
    typeset -g  _thm_utf=1
    typeset -g _thm_tl='╔' _thm_hh='═' _thm_v='║' _thm_ml='╟' _thm_h2='─' \
               _thm_bl='╚' _thm_ptr='▸' _thm_chk='✓' _thm_dot='·'
fi

_thm_colors() {   # chrome the panel from the highlighted theme's file palette
    local -a P=(${(s.:.)_prompt_lscolors[$1]})
    typeset -g _thm_cF=${${(M)P:#ln=*}#ln=}  _thm_cS=${${(M)P:#di=*}#di=}
    typeset -g _thm_cH=${${(M)P:#ex=*}#ex=}  _thm_cB=${${(M)P:#or=*}#or=}
    : ${_thm_cF:='38;5;244'} ${_thm_cS:='1;38;5;39'}
    : ${_thm_cH:='38;5;114'} ${_thm_cB:='38;5;203'}
    typeset -g _thm_cD='38;5;242'
}

_thm_swatch() {   # every file element in the highlighted theme's colors
    local ls=${_prompt_lscolors[$1]}
    [[ -n $ls ]] || { print -rn -- "  (no file colors registered)"; return 0 }
    (( _prompt_glow )) && ls=$(_pr_ls_glowed "$ls")
    local -a P=(${(s.:.)ls})
    local di=${${(M)P:#di=*}#di=} ln=${${(M)P:#ln=*}#ln=} ex=${${(M)P:#ex=*}#ex=}
    local or=${${(M)P:#or=*}#or=} pi=${${(M)P:#pi=*}#pi=}
    local ar=${${(M)P:#\*.tar=*}#\*.tar=} me=${${(M)P:#\*.png=*}#\*.png=}
    print -n -- "  \e[${di}mfolder/\e[0m  file  \e[${ln}mlink@\e[0m  \e[${ex}mbin*\e[0m  \e[${pi}mpipe|\e[0m  \e[${ar}mpack.tar\e[0m  \e[${me}mimg.png\e[0m  \e[${or}mgone@\e[0m"
}

# Rules are closed left, open right (a left rail) — content rows carry emoji
# and prompt samples whose display width can't be measured portably, so the
# panel never tries to close a right border around them.
_thm_draw() {   # uses: sel off n _thm_names _thm_msg (dynamic scope)
    local name=${_thm_names[sel]}
    _thm_colors "$name"
    local F=$'\e['"${_thm_cF}m" S=$'\e['"${_thm_cS}m" H=$'\e['"${_thm_cH}m"
    local D=$'\e['"${_thm_cD}m" R=$'\e[0m' K=$'\e[K'
    local -i W=$(( COLUMNS - 2 ))
    (( W > 74 )) && W=74
    (( W < 60 )) && W=60
    local -i i
    print -rn -- $'\e[H'

    local title=" themes ${_thm_h2} ${sel}/${n} "
    print -r -- "${F}${_thm_tl}${_thm_hh}${title}${(pl:$(( W - 3 - ${#title} ))::$_thm_hh:):-}${R}${K}"

    for (( i = off + 1; i <= n && i <= off + 8; i++ )); do
        local t=${_thm_names[i]} mark='  ' chk=' ' nmC=''
        (( i == sel )) && { mark="${H}${_thm_ptr} ${R}"; nmC=$S; }
        [[ $t == $_prompt_current ]] && chk="${H}${_thm_chk}${R}"
        print -r -- "${F}${_thm_v}${R} ${mark}${D}${(l:2:)i}${R} ${chk} ${nmC}${(r:10:)t}${R} ${D}${_prompt_themes[$t]}${R}${K}"
    done

    print -r -- "${F}${_thm_ml}${_thm_h2} preview ${(pl:$(( W - 11 ))::$_thm_h2:):-}${R}${K}"
    local ln
    for ln in ${(f)_prompt_samples[$name]}; do
        (( _prompt_glow )) && ln="%B${${ln//\%B/}//\%b/}%b"
        print -P -- "${F}${_thm_v}${R}  ${ln}${K}"
    done
    print -r -- "${F}${_thm_v}${R}$(_thm_swatch "$name")${K}"

    print -r -- "${F}${_thm_ml}${_thm_h2} effects ${(pl:$(( W - 11 ))::$_thm_h2:):-}${R}${K}"
    local g=off p=off
    (( _prompt_glow ))      && g="${H}on ✨${R}"
    (( PROMPT_FULL_PATHS )) && p="${H}on${R}"
    print -r -- "${F}${_thm_v}${R}  [g] glow: ${g}   [p] full paths: ${p}${K}"
    local keys="↑↓/jk browse ${_thm_dot} 1-9 jump ${_thm_dot} ⏎ apply ${_thm_dot} g/p effects ${_thm_dot} q quit"
    (( _thm_utf )) || keys="up/dn jk browse . 1-9 jump . Enter apply . g/p effects . q quit"
    [[ -n $_thm_msg ]] && keys=$_thm_msg
    print -r -- "${F}${_thm_v}${R}  ${D}${keys}${R}${K}"
    print -r -- "${F}${_thm_bl}${(pl:$(( W - 1 ))::$_thm_hh:):-}${R}${K}"
    print -rn -- $'\e[J'
}

_thm_menu() {
    local -a _thm_names=(${(ok)_prompt_themes})
    local -i n=${#_thm_names} sel=1 off=0 applied=0 efx=0
    local -i cur=${_thm_names[(Ie)$_prompt_current]}
    (( cur )) && sel=cur
    local _thm_msg='' junk
    print -rn -- $'\e[?1049h\e[?25l\e[2J'
    {
        while :; do
            (( sel <= off ))    && off=$(( sel - 1 ))
            (( sel > off + 8 )) && off=$(( sel - 8 ))
            _thm_draw
            _pr_readkey 300 || continue
            _thm_msg=''
            case $REPLY in
                esc) break ;;
                k|up)   (( sel > 1 )) && (( sel-- )) ;;
                j|down) (( sel < n )) && (( sel++ )) ;;
                [1-9]) local -i jmp=$REPLY; (( jmp <= n )) && sel=jmp ;;
                g|G)
                    (( _prompt_glow ^= 1 )) || :
                    print -r -- $_prompt_glow > "$PROMPT_HOME/glow" 2>/dev/null
                    efx=1 ;;
                p|P)
                    (( PROMPT_FULL_PATHS = ! PROMPT_FULL_PATHS )) || :
                    print -r -- ${PROMPT_FULL_PATHS:-0} > "$PROMPT_HOME/fullpaths" 2>/dev/null
                    efx=1 ;;
                $'\r'|$'\n') applied=1; break ;;
                q|Q) break ;;
            esac
        done
    } always {
        print -rn -- $'\e[?25h\e[?1049l'
    }
    if (( applied )); then
        _prompt_use "${_thm_names[sel]}"
        print -r -- "theme: ${_thm_names[sel]}${${(M)_prompt_glow:#1}:+ ✨}"
    elif (( efx )); then
        _prompt_use "$_prompt_current"   # land the effect toggles on the live prompt
        print -r -- "theme: kept ${_prompt_current}, effects updated"
    fi
    return 0
}

theme() {
    case ${1:-menu} in
        menu|'') _thm_menu ;;
        *)       prompt-theme "$@" ;;   # theme matrix, theme gallery, theme glow …
    esac
}
compdef '_arguments "1:theme:(menu gallery random glow ${(k)_prompt_themes})"' theme 2>/dev/null
