# ~/.prompt/hop.zsh — hop 🐇: an in-terminal panel listing every live zsh
# session — scroll with live preview, rename for your own reference, press
# Enter to jump. Pure zsh + ANSI escapes, no dependencies; colors come from
# the active prompt theme. `hop help` for usage; README for the per-platform
# story (tmux → true switch, window focus where the OS allows it, and a cwd
# "teleport" everywhere else).

[[ -o interactive ]] || return

: ${_PR_SESS_DIR:="$PROMPT_HOME/sessions"}
typeset -g  _hop_result='' _hop_msg=''
typeset -ga _hop_pids
typeset -gA _hop_d

# ── glyphs: box-drawing when the locale can show it, pure ASCII otherwise ────
# (force ASCII with HOP_ASCII=1)
if (( ${HOP_ASCII:-0} )) || [[ ${(U)LANG}${(U)LC_ALL} != *UTF*8* ]]; then
    typeset -g  _hop_utf=0
    typeset -g _hop_tl='+' _hop_tr='+' _hop_bl='+' _hop_br='+' _hop_hh='=' \
               _hop_v='|' _hop_ml='+' _hop_mr='+' _hop_h2='-' _hop_ptr='>' \
               _hop_dot='*' _hop_idot='.' _hop_nox='x'
else
    typeset -g  _hop_utf=1
    typeset -g _hop_tl='╔' _hop_tr='╗' _hop_bl='╚' _hop_br='╝' _hop_hh='═' \
               _hop_v='║' _hop_ml='╟' _hop_mr='╢' _hop_h2='─' _hop_ptr='▸' \
               _hop_dot='●' _hop_idot='·' _hop_nox='⤫'
fi

# ── palette lifted from the active theme's file colors ──────────────────────
_hop_colors() {
    local -a P=(${(s.:.)_prompt_lscolors[$_prompt_current]})
    typeset -g _hop_cF=${${(M)P:#ln=*}#ln=}  _hop_cS=${${(M)P:#di=*}#di=}
    typeset -g _hop_cH=${${(M)P:#ex=*}#ex=}  _hop_cB=${${(M)P:#or=*}#or=}
    : ${_hop_cF:='38;5;244'} ${_hop_cS:='1;38;5;39'}
    : ${_hop_cH:='38;5;114'} ${_hop_cB:='38;5;203'}
    typeset -g _hop_cD='38;5;242'
}

# ── registry I/O ────────────────────────────────────────────────────────────
_hop_load() {   # fill _hop_pids (self first, then newest activity), _hop_d
    _hop_pids=(); _hop_d=()
    local f pid line
    local -a byage=()
    for f in "$_PR_SESS_DIR"/*.rename(N); do   # orphaned rename handoffs
        pid=${${f:t}%.rename}
        kill -0 $pid 2>/dev/null || command rm -f "$f"
    done
    for f in "$_PR_SESS_DIR"/*.session(N); do
        pid=${${f:t}%.session}
        [[ $pid == <-> ]] || continue
        if ! kill -0 $pid 2>/dev/null; then command rm -f "$f"; continue; fi
        while IFS= read -r line; do
            [[ $line == *=* ]] && _hop_d[$pid,${line%%=*}]=${line#*=}
        done < "$f"
        byage+=("${(l:12::0:)_hop_d[$pid,at]} $pid")
    done
    byage=(${(O)byage})
    _hop_pids=(${byage#* })
    (( ${_hop_pids[(Ie)$$]} )) && _hop_pids=($$ ${_hop_pids:#$$})
    # how (whether) we can actually switch to each one from THIS shell —
    # decided up front so the list and preview can be honest about it
    local reach
    for pid in $_hop_pids; do
        reach=none
        if [[ -n ${_hop_d[$pid,tmux]} && -n $TMUX ]] && (( $+commands[tmux] )) && \
           command tmux display-message -pt "${_hop_d[$pid,tmux]}" '#{session_name}' >/dev/null 2>&1; then
            reach=tmux
        elif [[ -n ${_hop_d[$pid,name]} ]]; then
            if [[ $OSTYPE == darwin* ]]; then
                reach=mac
            elif [[ -n ${WSL_DISTRO_NAME:-}${WSL_INTEROP:-} ]] && (( $+commands[powershell.exe] )); then
                reach=wsl          # window-level focus, best effort
            elif [[ -n $DISPLAY ]] && (( $+commands[wmctrl] || $+commands[xdotool] )); then
                reach=x11
            fi
        fi
        _hop_d[$pid,reach]=$reach
    done
}

_hop_setname() {   # <pid> <name> — registry now; the live shell adopts it
    local pid=$1 nm=$2 f="$_PR_SESS_DIR/$1.session" line out=''
    if [[ $pid == $$ ]]; then
        TERM_SESSION_NAME=$nm
        _pr_sess_title
        _pr_sess_write
        return 0
    fi
    [[ -f $f ]] || return 1
    while IFS= read -r line; do
        [[ $line == name=* ]] && line="name=$nm"
        out+=$line$'\n'
    done < "$f"
    print -rn -- "$out" > "$f"
    # the target applies name + tab title at its next prompt
    print -r -- "$nm" > "$_PR_SESS_DIR/$pid.rename"
}

_hop_clean() {   # names travel into titles, AppleScript & PowerShell — tame them
    local nm=${1//[[:cntrl:]]/}
    nm=${nm//[\"\'\\\`;]/}
    print -rn -- "${nm[1,24]}"
}

_hop_ago() {
    local -i d=$(( EPOCHSECONDS - ${1:-EPOCHSECONDS} ))
    (( d < 0 )) && d=0
    if   (( d < 60 ));   then print -n "${d}s"
    elif (( d < 3600 )); then print -n "$(( d / 60 ))m"
    else                      print -n "$(( d / 3600 ))h"; fi
}

# ── switch backends, best available first ───────────────────────────────────
_hop_focus_mac() {   # <title> <term_program> — osascript ships with macOS
    local t=$1
    case ${2:-$TERM_PROGRAM} in
        iTerm*) command osascript >/dev/null 2>&1 -e '
            tell application "iTerm2"
                activate
                repeat with w in windows
                    repeat with tb in tabs of w
                        repeat with s in sessions of tb
                            if name of s contains "'"$t"'" then
                                select w
                                select tb
                                return
                            end if
                        end repeat
                    end repeat
                end repeat
            end tell' ;;
        *) command osascript >/dev/null 2>&1 -e '
            tell application "Terminal"
                activate
                repeat with w in windows
                    repeat with tb in tabs of w
                        if custom title of tb contains "'"$t"'" then
                            set frontmost of w to true
                            set selected of tb to true
                            return
                        end if
                    end repeat
                end repeat
            end tell' ;;
    esac
}

_hop_focus_wsl() {   # <title> — raise the Windows Terminal *window* whose
    local out          # front tab carries this title (background tabs can't
    out=$(command powershell.exe -NoProfile -Command \
        "(New-Object -ComObject WScript.Shell).AppActivate('$1')" 2>/dev/null)
    [[ ${out%%$'\r'*} == True ]]
}

# Enter never guesses: it switches when a backend can actually reach the
# target, otherwise it explains why and stays in the menu. Teleport (cd to
# the target's directory — cwd only, none of that terminal's session) is
# its own explicit key: t.
_hop_switch() {   # <pid> → 0: done, leave the menu · 1: stay in the menu
    local pid=$1
    [[ $pid == $$ ]] && { _hop_msg="you are already here"; return 1 }
    local name=${_hop_d[$pid,name]} pane=${_hop_d[$pid,tmux]}
    case ${_hop_d[$pid,reach]} in
        tmux)
            local sess
            sess=$(command tmux display-message -pt "$pane" '#{session_name}' 2>/dev/null)
            command tmux switch-client -t "$sess" 2>/dev/null
            command tmux select-window -t "$pane" 2>/dev/null
            command tmux select-pane   -t "$pane" 2>/dev/null
            _hop_result="switched to tmux pane $pane (${name:-unnamed})"
            return 0 ;;
        mac)
            if _hop_focus_mac "$name" "${_hop_d[$pid,term]}"; then
                _hop_result="focused window '$name'"; return 0
            fi
            _hop_msg="no window titled '$name' found ${_hop_idot} t teleports"
            return 1 ;;
        x11)
            if (( $+commands[wmctrl] )) && command wmctrl -a "$name" 2>/dev/null; then
                _hop_result="focused window '$name' (wmctrl)"; return 0
            elif (( $+commands[xdotool] )) && \
                 command xdotool search --name "$name" windowactivate 2>/dev/null; then
                _hop_result="focused window '$name' (xdotool)"; return 0
            fi
            _hop_msg="no window titled '$name' found ${_hop_idot} t teleports"
            return 1 ;;
        wsl)
            if _hop_focus_wsl "$name"; then
                _hop_result="focused Windows Terminal window '$name'"; return 0
            fi
            _hop_msg="'$name' isn't a front tab — Ctrl+Tab to it ${_hop_idot} t teleports"
            return 1 ;;
        *)
            if [[ -n $name ]]; then
                _hop_msg="no switch path — its tab is titled '$name' ${_hop_idot} t teleports"
            else
                _hop_msg="no switch path — r names it (shows in tab bar) ${_hop_idot} t teleports"
            fi
            return 1 ;;
    esac
}

_hop_teleport() {   # <pid> — explicit: bring its cwd here, nothing else
    local cwd=${_hop_d[$1,cwd]}
    if [[ -d $cwd ]]; then
        cd -- "$cwd"
        _hop_result="teleported to ${(D)cwd} (cwd only — not that terminal's session)"
        return 0
    fi
    _hop_msg="its cwd is gone"
    return 1
}

# ── the panel ───────────────────────────────────────────────────────────────
_hop_draw() {   # uses: sel off  ·  sets: nothing (pure redraw)
    local F=$'\e['"${_hop_cF}m" S=$'\e['"${_hop_cS}m" H=$'\e['"${_hop_cH}m"
    local B=$'\e['"${_hop_cB}m" D=$'\e['"${_hop_cD}m" R=$'\e[0m' K=$'\e[K'
    local -i W=$(( COLUMNS - 2 ))
    (( W > 74 )) && W=74
    (( W < 60 )) && W=60
    local -i inner=$(( W - 2 )) n=${#_hop_pids}
    local -i rest=$(( inner - 51 ))    # same-statement would see inner=0
    local -i i
    print -rn -- $'\e[H'

    local title=" hop ${_hop_h2} $n shells "
    (( n == 1 )) && title=" hop ${_hop_h2} 1 shell "
    local -i fill=$(( W - 3 - ${#title} ))
    print -r -- "${F}${_hop_tl}${_hop_hh}${title}${(pl:fill::$_hop_hh:):-}${_hop_tr}${R}${K}"

    # list window
    for (( i = off + 1; i <= n && i <= off + 9; i++ )); do
        local p=${_hop_pids[i]}
        local nm=${_hop_d[$p,name]:-zsh $p} cm=${_hop_d[$p,cmd]:-—}
        local cw=${(D)_hop_d[$p,cwd]}
        (( ${#cw} > 24 )) && cw="…${cw[-23,-1]}"
        [[ $p == $$ ]] && cm='(this shell)'
        local dot="${D}${_hop_idot}${R}" mark='  ' nmC=''
        [[ ${_hop_d[$p,state]} == run ]] && dot="${H}${_hop_dot}${R}"
        [[ ${_hop_d[$p,reach]} == none && $p != $$ ]] && mark="${D}${_hop_nox} ${R}"
        [[ $p == $$ ]] && nmC=$D
        (( i == sel )) && { mark="${H}${_hop_ptr} ${R}"; nmC=$S; }
        print -r -- "${F}${_hop_v}${R} ${mark}${D}${(l:2:)i}${R} ${dot} ${nmC}${(r:16:)${nm[1,16]}}${R} ${D}${(r:24:)cw}${R} ${D}${(r:rest:)${cm[1,rest]}}${R} ${F}${_hop_v}${R}${K}"
    done

    # preview of the selected session
    print -r -- "${F}${_hop_ml}${(pl:$(( W - 2 ))::$_hop_h2:):-}${_hop_mr}${R}${K}"
    local p=${_hop_pids[sel]}
    local nm=${_hop_d[$p,name]:-unnamed} br=${_hop_d[$p,branch]} ex=${_hop_d[$p,exit]:-0}
    local meta="${nm} ${_hop_idot} tty ${_hop_d[$p,tty]} ${_hop_idot} pid ${p}"
    [[ -n $br ]] && meta+=" ${_hop_idot} on ${br}"
    [[ $p == $$ ]] && meta+=" ${_hop_idot} you"
    local exC=$H; [[ $ex != 0 ]] && exC=$B
    local last="last: ${_hop_d[$p,cmd]:-—} ${_hop_ptr} ${ex} ${_hop_idot} $(_hop_ago ${_hop_d[$p,at]}) ago"
    local cwl="cwd:  ${(D)_hop_d[$p,cwd]}"
    local jmp
    case ${_hop_d[$p,reach]} in
        tmux) jmp="jump: real switch — tmux pane ${_hop_d[$p,tmux]}" ;;
        mac)  jmp="jump: focuses the window titled '${nm}'" ;;
        x11)  jmp="jump: focuses the window titled '${nm}'" ;;
        wsl)  jmp="jump: raises the WT window fronting '${nm}' ${_hop_idot} t = cwd here" ;;
        *)    if [[ $p == $$ ]]; then jmp="jump: you are here"
              elif [[ -n ${_hop_d[$p,name]} ]]; then
                  jmp="jump: none from here ${_hop_idot} tab titled '${nm}' ${_hop_idot} t = cwd here"
              else
                  jmp="jump: none ${_hop_idot} r names it for the tab bar ${_hop_idot} t = cwd here"
              fi ;;
    esac
    for meta in "$meta" "$cwl" "$last" "$jmp"; do
        print -r -- "${F}${_hop_v}${R} ${(r:$(( inner - 2 )):)${meta[1,$(( inner - 2 ))]}} ${F}${_hop_v}${R}${K}"
    done
    # live pane tail — only tmux can show another terminal's screen
    if [[ -n ${_hop_d[$p,tmux]} ]] && (( $+commands[tmux] )); then
        local -a live=(${(f)"$(command tmux capture-pane -pt ${_hop_d[$p,tmux]} -S -4 2>/dev/null)"})
        local ln
        for ln in ${live[-3,-1]}; do
            print -r -- "${F}${_hop_v}${R} ${D}│ ${(r:$(( inner - 4 )):)${ln[1,$(( inner - 4 ))]}}${R} ${F}${_hop_v}${R}${K}"
        done
    fi

    # footer
    print -r -- "${F}${_hop_ml}${(pl:$(( W - 2 ))::$_hop_h2:):-}${_hop_mr}${R}${K}"
    local keys=" ↑↓/jk move ${_hop_idot} ⏎ switch ${_hop_idot} t teleport ${_hop_idot} r rename ${_hop_idot} q quit "
    (( _hop_utf )) || keys=" up/dn jk move . Enter switch . t teleport . r rename . q quit "
    [[ -n $_hop_msg ]] && keys=" ${_hop_msg} "
    print -r -- "${F}${_hop_v}${R}${D}${(r:inner:)${keys[1,inner]}}${R}${F}${_hop_v}${R}${K}"
    print -r -- "${F}${_hop_bl}${(pl:$(( W - 2 ))::$_hop_hh:):-}${_hop_br}${R}${K}"
    print -rn -- $'\e[J'
}

_hop_rename() {
    local pid=$1 cur=${_hop_d[$pid,name]} name
    print -rn -- $'\n\e[K\e[?25h'
    IFS= read -r "name?  new name${cur:+ [$cur]}: "
    print -rn -- $'\e[?25l'
    name=$(_hop_clean "$name")
    [[ -n $name ]] || return 0
    _hop_setname $pid "$name" || { _hop_msg="rename failed"; return 1 }
    _hop_d[$pid,name]=$name
    _hop_msg="renamed ${_hop_ptr} $name"
}

_hop_menu() {
    _hop_colors
    _hop_load
    (( ${#_hop_pids} )) || { print -u2 "hop: no live sessions registered yet"; return 1 }
    local -i sel=1 off=0 n=${#_hop_pids}
    local k k2 k3
    _hop_msg='' _hop_result=''
    # terminals running code from before hop existed register only after a
    # restart / re-source — worth saying when the list looks lonely
    (( n == 1 )) && _hop_msg="only this shell — others join after: source ~/.zshrc"
    print -rn -- $'\e[?1049h\e[?25l\e[2J'
    {
        while :; do
            (( sel <= off ))     && off=$(( sel - 1 ))
            (( sel > off + 9 ))  && off=$(( sel - 9 ))
            _hop_draw
            read -sk1 k 2>/dev/null || break
            _hop_msg=''
            case $k in
                $'\e')
                    if read -sk1 -t 0.05 k2 2>/dev/null && [[ $k2 == '[' ]]; then
                        read -sk1 -t 0.2 k3 2>/dev/null
                        case $k3 in
                            A) (( sel > 1 )) && (( sel-- )) ;;
                            B) (( sel < n )) && (( sel++ )) ;;
                        esac
                    else
                        break
                    fi ;;
                k) (( sel > 1 )) && (( sel-- )) ;;
                j) (( sel < n )) && (( sel++ )) ;;
                [1-9]) local -i jmp=$k
                    (( jmp <= n )) && { sel=jmp; _hop_switch ${_hop_pids[sel]} && break } ;;
                $'\r'|$'\n') _hop_switch ${_hop_pids[sel]} && break ;;
                t|T) _hop_teleport ${_hop_pids[sel]} && break ;;
                r|R) _hop_rename ${_hop_pids[sel]} ;;
                q|Q) break ;;
            esac
        done
    } always {
        print -rn -- $'\e[?25h\e[?1049l'
    }
    [[ -n $_hop_result ]] && print -r -- "hop: $_hop_result"
    return 0
}

hop() {
    case ${1:-menu} in
        menu|'') _hop_menu ;;
        name)
            shift
            local nm=$(_hop_clean "$*")
            [[ -n $nm ]] || { print -u2 "usage: hop name <label>"; return 1 }
            _hop_setname $$ "$nm"
            print -r -- "hop: this terminal is now '$nm'" ;;
        list)
            _hop_load
            local p
            for p in $_hop_pids; do
                printf '%8s  %-16s %-28s %s\n' "$p" "${_hop_d[$p,name]:--}" \
                    "${(D)_hop_d[$p,cwd]}" "${_hop_d[$p,cmd]}"
            done ;;
        help|-h|--help)
            print -r -- 'hop — jump between your terminals
  hop              open the panel: ↑↓/jk move, 1-9 jump, ⏎ switch,
                   t teleport (cd to its dir), r rename (sets the tab
                   title too), q quit. ⤫ marks unreachable terminals.
  hop name <label> name this terminal
  hop list         plain listing (for scripts)
Switching: tmux pane → true switch; macOS/X11/Windows-Terminal windows →
focus by title (name your terminals!). When nothing can reach the target,
Enter explains instead of guessing; t explicitly brings its cwd here.' ;;
        *) print -u2 "hop: unknown command '$1' (try: hop help)"; return 1 ;;
    esac
}
compdef '_arguments "1:cmd:(menu name list help)"' hop 2>/dev/null
