# ~/.prompt/hop.zsh — hop 🐇 v2: your terminals, multiplexed.
#
# One tmux-backed hub (its own socket, own server — never touches your other
# tmux). Every session is a named window: the left sidebar lists them, the
# right pane IS the session — claude, vim, top, anything, at full fidelity,
# because tmux is the terminal emulator. Sessions survive closing the
# terminal window; `hop` from anywhere puts you right back among them.
#
#   hop              outside the hub: attach (creating it if needed)
#                    inside the hub:  jump to the sidebar
#   hop name <n>     rename the current session
#   hop list         list hub sessions from anywhere
#   hop help         cheat sheet
#
# Sidebar keys: ↑↓/jk browse (right pane follows live) · 1-9 jump · ⏎ into
# the session · r rename · n new · x kill · t themes mode · d detach ·
# q hide sidebar. Themes mode: browse = the whole hub re-themes live;
# ⏎ keeps it, Esc restores theme+glow, g toggles glow.
# Jump panes from anywhere — even while claude/vim/top run (tmux eats the
# keys first): Alt+h → sidebar · Alt+l → session. Typing `hop` at a shell
# prompt also lands on the sidebar.
# Sidebar width: HOP_WIDTH (default 20%); resizing the terminal keeps the
# ratio — tmux scales panes proportionally.
#
# Needs tmux (the one dependency): apt/dnf/pacman/brew install tmux.
# Works on Linux + macOS, x86 and ARM alike — tmux is plain C, everywhere.

[[ -o interactive ]] || return

: ${HOP_SOCKET:=hop}
: ${HOP_WIDTH:=20%}          # sidebar width — % of the window or a column count
# sessions.zsh normally defines this, but sidebar shells skip it (HOP_SB)
: ${_PR_SESS_DIR:="$PROMPT_HOME/sessions"}

# ── glyphs: box-drawing when the locale can show it, ASCII otherwise ────────
if (( ${HOP_ASCII:-0} )) || [[ ${(U)LANG}${(U)LC_ALL} != *UTF*8* ]]; then
    typeset -g _hop_utf=0 _hop_h2='-' _hop_ptr='>' _hop_dot='*' _hop_idot='.' _hop_chk='*'
else
    typeset -g _hop_utf=1 _hop_h2='─' _hop_ptr='▸' _hop_dot='●' _hop_idot='·' _hop_chk='✓'
fi

_hop_clean() {   # names travel into titles & tmux commands — keep them tame
    local nm=${1//[[:cntrl:]]/}
    nm=${nm//[\"\'\\\`;]/}
    print -rn -- "${nm[1,20]}"
}

# ── hub plumbing ────────────────────────────────────────────────────────────
_hop_tm() { command tmux -L "$HOP_SOCKET" "$@" }

_hop_in_hub() { [[ -n $TMUX && ${${TMUX%%,*}:t} == $HOP_SOCKET ]] }

_hop_hub_config() {
    _hop_tm set -g status off \; set -g mouse on \; set -g base-index 1 \; \
            set -g renumber-windows on \; set -g set-titles on \; \
            set -g set-titles-string '#W · hop' \; set -s escape-time 10 \
            2>/dev/null
    _hop_tm move-window -r -t hub: 2>/dev/null   # first window starts at 1
    # Alt+h from anywhere — even with claude/vim/top running in the right
    # pane, tmux eats the key before the app sees it: focus the sidebar,
    # spawning it first if it was hidden (q) or the window never had one.
    _hop_sb_cmd
    _hop_tm bind -n M-h if -F '#{e|>:#{window_panes},1}' \
        "select-pane -t '{left}'" \
        "split-window -hbf -l $HOP_WIDTH '$REPLY'" 2>/dev/null
    # …and Alt+l jumps back into the session pane: h ⇄ l, vim-style
    _hop_tm bind -n M-l select-pane -t '{right}' 2>/dev/null
    _hop_theme_sync
}

# Restyle the hub to the active theme (split lines in theme colors). Called
# on hub creation and by _prompt_use on every theme switch, so changing the
# theme re-skins the whole hub live; the sidebar re-inks itself on its tick.
_hop_theme_sync() {
    (( $+commands[tmux] )) || return 0
    _hop_tm has-session -t hub 2>/dev/null || return 0
    # last field of the SGR entry = the 256-colour number tmux wants
    local -a P=(${(s.:.)_prompt_lscolors[$_prompt_current]})
    local ln=${${${(M)P:#ln=*}#ln=}##*;} di=${${${(M)P:#di=*}#di=}##*;}
    [[ -n $ln ]] && _hop_tm set -g pane-border-style "fg=colour${ln}" 2>/dev/null
    [[ -n $di ]] && _hop_tm set -g pane-active-border-style "fg=colour${di}" 2>/dev/null
}

_hop_sb_pane() {   # <win> — print the window's sidebar pane id, if any
    local id sb
    _hop_tm list-panes -t "$1" -F '#{pane_id} #{?@hop_sb,1,0}' 2>/dev/null | \
    while read -r id sb; do
        [[ $sb == 1 ]] && { print -rn -- "$id"; return 0 }
    done
    return 1
}

# the command a sidebar pane runs — no single quotes, so it can survive
# every quoting layer (zsh → tmux → sh) identically everywhere it's used.
# Sets $REPLY (no fork) instead of printing.
_hop_sb_cmd() {
    REPLY="PROMPT_BANNER=0 PROMPT_SHLOK=0 PROMPT_FAREWELL=0 HOP_SB=1 HOP_SOCKET=$HOP_SOCKET exec zsh -ic hop\\ _sidebar"
}

_hop_sb_ensure() {   # <win> — spawn the sidebar there if missing; print its id
    local id
    id=$(_hop_sb_pane "$1") && { print -rn -- "$id"; return 0 }
    _hop_sb_cmd
    id=$(_hop_tm split-window -hbf -l "$HOP_WIDTH" -d -t "$1" -P -F '#{pane_id}' "$REPLY")
    [[ -n $id ]] && _hop_tm set -p -t "$id" @hop_sb 1
    print -rn -- "$id"
}

_hop_hub_attach() {
    (( $+commands[tmux] )) || {
        print -u2 "hop: needs tmux — sudo apt install tmux (Linux/WSL) or brew install tmux (macOS)"
        return 1
    }
    if ! _hop_tm has-session -t hub 2>/dev/null; then
        _hop_tm new-session -d -s hub -n shell || return 1
        _hop_hub_config
    fi
    # each terminal gets an independent grouped view; it evaporates on detach,
    # while the base "hub" session keeps every window alive in the background.
    # --own-window (used by HOP_AUTO): this tab also gets its OWN fresh hub
    # session, so every new terminal shows up in every sidebar.
    if [[ $1 == --own-window ]]; then
        _hop_sb_cmd
        _hop_tm new-session -t hub \; set-option destroy-unattached on \; \
            new-window \; split-window -hbf -l "$HOP_WIDTH" -d "$REPLY" \; \
            select-pane -t '{right}'
    else
        _hop_sb_ensure "hub:" >/dev/null
        _hop_tm new-session -t hub \; set-option destroy-unattached on
    fi
}

_hop_sb_focus() {   # `hop` typed inside the hub: land on the sidebar
    local id
    id=$(_hop_sb_ensure "$(_hop_tm display -p '#{window_id}')")
    [[ -n $id ]] && _hop_tm select-pane -t "$id"
}

# ── the sidebar (runs inside its own pane, one per window, shared by views) ─
_hop_sb_move() {   # next|prev|<index> — ONE tmux round-trip, for a snappy feel
    local tgt
    case $1 in
        next) tgt=':+' ;;
        prev) tgt=':-' ;;
        *)    tgt=":$1" ;;
    esac
    # switch window, then land on its sidebar — spawning one on the fly if
    # that window never had one (or had it hidden). All in a single client
    # invocation: per-keypress process spawns are what read as input lag.
    _hop_sb_cmd
    _hop_tm select-window -t "$tgt" \; \
        if -F '#{e|>:#{window_panes},1}' \
        "select-pane -t '{left}'" \
        "split-window -hbf -l $HOP_WIDTH -d '$REPLY' ; select-pane -t '{left}'" \
        2>/dev/null
}

_hop_sb_new() {
    local w
    w=$(_hop_tm new-window -P -F '#{window_id}')
    [[ -n $w ]] || return 1
    _hop_sb_ensure "$w" >/dev/null     # lands focused on the fresh shell
}

_hop_sb_rename() {
    local cur name
    cur=$(_hop_tm display -p '#{window_name}')
    print -n "\e[$((LINES));1H\e[K\e[?25h"
    IFS= read -r "name?name [$cur]: "
    print -n '\e[?25l'
    name=$(_hop_clean "$name")
    [[ -n $name ]] && _hop_tm rename-window -- "$name"
}

_hop_sb_kill() {
    print -n "\e[$((LINES));1H\e[K"
    print -n "kill this session? y/N"
    local ans; read -sk1 ans
    print -n "\e[$((LINES));1H\e[K"
    [[ $ans == [yY] ]] || return 0
    local cur n
    cur=$(_hop_tm display -p '#{window_id}')
    n=$(_hop_tm display -p '#{session_windows}')
    (( n > 1 )) && _hop_sb_move next     # step onto a survivor first
    _hop_tm kill-window -t "$cur"        # killing our own window ends us too
}

_hop_sb_draw() {
    # re-read the theme each tick — switching themes re-inks the sidebar live
    local thm=$_prompt_current
    [[ -r "$PROMPT_HOME/current" ]] && thm=$(<"$PROMPT_HOME/current")
    local -a P=(${(s.:.)_prompt_lscolors[$thm]})
    local cS=${${(M)P:#di=*}#di=} cH=${${(M)P:#ex=*}#ex=} cF=${${(M)P:#ln=*}#ln=}
    : ${cS:='1;38;5;39'} ${cH:='38;5;114'} ${cF:='38;5;244'}
    local S=$'\e['"${cS}m" H=$'\e['"${cH}m" F=$'\e['"${cF}m" \
          D=$'\e[38;5;242m' R=$'\e[0m' K=$'\e[K'
    local icon=${${(z)_prompt_themes[$thm]}[1]}   # the theme's emoji
    local -i w=$COLUMNS
    print -n '\e[H'
    print -r -- "${icon:-} ${F}hop ${(pl:$(( w - 7 ))::$_hop_h2:):-}${R}${K}"
    # windows + what runs in them, from ONE tmux call (draw runs per keypress;
    # every extra client spawn is felt as input lag)
    local -A cmd_of idx_of act_of nam_of
    local -a order
    local wid idx act sb cmd name
    _hop_tm list-panes -s -F '#{window_id} #{window_index} #{window_active} #{?@hop_sb,1,0} #{pane_current_command} #{window_name}' 2>/dev/null | \
    while read -r wid idx act sb cmd name; do
        [[ -n ${idx_of[$wid]} ]] || { order+=($wid); idx_of[$wid]=$idx; act_of[$wid]=$act; nam_of[$wid]=$name; }
        [[ $sb == 1 ]] || cmd_of[$wid]=$cmd
    done
    local c dot mark nc   # declared once — re-`local` in a loop echoes set vars
    local -i nw=$(( w - 8 ))          # name column adapts to the rail width
    (( nw > 14 )) && nw=14
    (( nw < 6 ))  && nw=6
    for wid in $order; do
        c=${cmd_of[$wid]:-zsh} mark='  ' nc=$D dot="${D}${_hop_idot}${R}"
        [[ $c != (zsh|bash|sh|fish) ]] && dot="${H}${_hop_dot}${R}"
        [[ ${act_of[$wid]} == 1 ]] && { mark="${H}${_hop_ptr} ${R}"; nc=$S; }
        name=${nam_of[$wid]}
        print -r -- "${mark}${D}${idx_of[$wid]}${R} ${dot} ${nc}${(r:nw:)${name[1,nw]}}${R}${K}"
    done
    # plain terminals outside the hub (from the session registry). Honesty
    # note: the hub cannot embed an already-running pty, so these are listed
    # for awareness, not hosted — HOP_AUTO=1 makes future tabs join for real.
    local f pid line onm otm
    local -a out_rows=()
    for f in "$_PR_SESS_DIR"/*.session(N); do
        pid=${${f:t}%.session}
        [[ $pid == <-> ]] && kill -0 $pid 2>/dev/null || { command rm -f "$f" 2>/dev/null; continue }
        onm='' otm=''
        while IFS= read -r line; do
            case $line in
                name=*) onm=${line#name=} ;;
                tmux=*) otm=${line#tmux=} ;;
            esac
        done < "$f"
        [[ -n $otm ]] && continue          # already inside a tmux/the hub
        out_rows+=("${onm:-zsh ${pid}}")
    done
    if (( ${#out_rows} )); then
        print -r -- "${F}${_hop_h2} outside ${(pl:$(( w - 10 ))::$_hop_h2:):-}${R}${K}"
        local o
        for o in $out_rows; do
            print -r -- "  ${D}${_hop_idot} ${o[1,$(( w - 4 ))]}${R}${K}"
        done
    fi
    print -r -- "${K}"
    print -r -- "${F}${(pl:$w::$_hop_h2:):-}${R}${K}"
    local ent='⏎' sw='⇄'
    (( _hop_utf )) || { ent='cr'; sw='='; }
    print -r -- "${D}${ent} open  r name${R}${K}"
    print -r -- "${D}n new   x kill${R}${K}"
    print -r -- "${D}t theme d detach${R}${K}"
    print -r -- "${D}q hide  alt+h/l${sw}${R}${K}"
    print -r -- "${D}${_hop_idot} ${thm}${R}${K}"
    print -rn -- $'\e[J'
}

_hop_sb_theme_apply() {   # uses thmsel/_thmlist — apply, persist, restyle hub;
    _prompt_use "${_thmlist[thmsel]}" 2>/dev/null   # running shells follow at
}                                                   # their next prompt

_hop_sb_draw_themes() {   # uses: _thmlist thmsel toff thm0 (dynamic scope)
    local thm=${_thmlist[thmsel]}
    local -a P=(${(s.:.)_prompt_lscolors[$thm]})
    local cS=${${(M)P:#di=*}#di=} cH=${${(M)P:#ex=*}#ex=}
    local cF=${${(M)P:#ln=*}#ln=} cB=${${(M)P:#or=*}#or=}
    : ${cS:='1;38;5;39'} ${cH:='38;5;114'} ${cF:='38;5;244'} ${cB:='38;5;203'}
    local S=$'\e['"${cS}m" H=$'\e['"${cH}m" F=$'\e['"${cF}m" B=$'\e['"${cB}m" \
          D=$'\e[38;5;242m' R=$'\e[0m' K=$'\e[K'
    local -i g=0; [[ -f "$PROMPT_HOME/glow" ]] && g=$(<"$PROMPT_HOME/glow")
    local ls=${_prompt_lscolors[$thm]}
    (( g )) && ls=$(_pr_ls_glowed "$ls")
    local -a Q=(${(s.:.)ls})
    local di=${${(M)Q:#di=*}#di=} ln=${${(M)Q:#ln=*}#ln=} ex=${${(M)Q:#ex=*}#ex=}
    local or=${${(M)Q:#or=*}#or=} me=${${(M)Q:#\*.png=*}#\*.png=}
    local icon=${${(z)_prompt_themes[$thm]}[1]}
    local -i w=$COLUMNS n=${#_thmlist} i
    local -i tvis=$(( LINES - 9 )); (( tvis < 4 )) && tvis=4
    (( thmsel <= toff ))       && toff=$(( thmsel - 1 ))
    (( thmsel > toff + tvis )) && toff=$(( thmsel - tvis ))
    print -n '\e[H'
    print -r -- "🎨 ${F}themes ${(pl:$(( w - 10 ))::$_hop_h2:):-}${R}${K}"
    local t chk mark nc
    for (( i = toff + 1; i <= n && i <= toff + tvis; i++ )); do
        t=${_thmlist[i]} chk=' ' mark='  ' nc=$D
        [[ $t == $thm0 ]] && chk="${H}${_hop_chk}${R}"
        (( i == thmsel )) && { mark="${H}${_hop_ptr} ${R}"; nc=$S; }
        print -r -- "${mark}${D}${(l:2:)i}${R} ${chk} ${nc}${(r:12:)${t[1,12]}}${R}${K}"
    done
    print -r -- "${F}${_hop_h2} preview ${(pl:$(( w - 10 ))::$_hop_h2:):-}${R}${K}"
    local pch='❯'; (( _hop_utf )) || pch='>'
    print -r -- "${icon} ${H}${pch}${R} ${F}on main${R} ${B}${_hop_dot}${R}${K}"
    print -- "\e[${di}mdir/\e[0m \e[${ln}mln@\e[0m \e[${ex}mbin*\e[0m \e[${me}mimg\e[0m \e[${or}mgone@\e[0m${K}"
    print -r -- "${F}${(pl:$w::$_hop_h2:):-}${R}${K}"
    local ent='⏎'; (( _hop_utf )) || ent='cr'
    print -r -- "${D}${ent} keep  g glow${R}${K}"
    print -r -- "${D}esc undo${R}${K}"
    print -r -- "${D}${_hop_idot} glow ${${${g/#1/on}}/#0/off}${R}${K}"
    print -rn -- $'\e[J'
}

_hop_sidebar() {
    _hop_in_hub || { print -u2 "hop: _sidebar only runs inside the hub"; return 1 }
    _hop_tm set -p -t "$TMUX_PANE" @hop_sb 1
    print -n '\e[?25l\e[2J'
    local junk mode=sessions thm0=''
    local -i thmsel=1 toff=0 glow0=0
    local -a _thmlist=(${(ok)_prompt_themes})
    {
        while :; do
            if [[ $mode == themes ]]; then _hop_sb_draw_themes; else _hop_sb_draw; fi
            _pr_readkey 3 || continue      # 3s tick: pick up outside changes
            if [[ $mode == themes ]]; then
                case $REPLY in
                    j|down) (( thmsel < ${#_thmlist} )) && { (( thmsel++ )); _hop_sb_theme_apply } ;;
                    k|up)   (( thmsel > 1 )) && { (( thmsel-- )); _hop_sb_theme_apply } ;;
                    [1-9])  (( REPLY <= ${#_thmlist} )) && { thmsel=$REPLY; _hop_sb_theme_apply } ;;
                    g|G) (( _prompt_glow ^= 1 )) || :
                         print -r -- $_prompt_glow > "$PROMPT_HOME/glow" 2>/dev/null
                         _hop_sb_theme_apply ;;
                    $'\r'|$'\n'|t|T) mode=sessions ;;      # keep what you see
                    esc|q|Q)                                # undo theme + glow
                        _prompt_glow=$glow0
                        print -r -- $glow0 > "$PROMPT_HOME/glow" 2>/dev/null
                        _prompt_use "$thm0" 2>/dev/null
                        mode=sessions ;;
                esac
            else
                case $REPLY in
                    j|down) _hop_sb_move next ;;
                    k|up)   _hop_sb_move prev ;;
                    [1-9]) _hop_sb_move $REPLY ;;
                    $'\r'|$'\n') _hop_tm select-pane -R 2>/dev/null ;;
                    t|T) mode=themes
                         thm0=$_prompt_current
                         [[ -r "$PROMPT_HOME/current" ]] && thm0=$(<"$PROMPT_HOME/current")
                         glow0=0; [[ -f "$PROMPT_HOME/glow" ]] && glow0=$(<"$PROMPT_HOME/glow")
                         thmsel=${_thmlist[(Ie)$thm0]}; (( thmsel )) || thmsel=1
                         toff=0 ;;
                    r|R) _hop_sb_rename ;;
                    n|N) _hop_sb_new ;;
                    x|X) _hop_sb_kill ;;
                    d|D) _hop_tm detach-client ;;
                    q|Q) _hop_tm kill-pane -t "$TMUX_PANE" ;;
                esac
            fi
            # drain type-ahead: a held-down arrow must not queue moves that
            # keep firing after the key is released
            while read -sk1 -t 0 junk 2>/dev/null; do :; done
        done
    } always {
        print -n '\e[?25h'
    }
}

# ── the command ─────────────────────────────────────────────────────────────
hop() {
    case ${1:-go} in
        go|'')
            if _hop_in_hub; then
                _hop_sb_focus
            elif [[ -n $TMUX ]]; then
                print -u2 "hop: you're inside another tmux — run hop from a plain terminal (nesting isn't supported)"
                return 1
            else
                _hop_hub_attach
            fi ;;
        name)
            shift
            local nm=$(_hop_clean "$*")
            [[ -n $nm ]] || { print -u2 "usage: hop name <label>"; return 1 }
            if _hop_in_hub; then
                _hop_tm rename-window -- "$nm"
                print -r -- "hop: session is now '$nm'"
            else
                TERM_SESSION_NAME=$nm
                _pr_sess_title; _pr_sess_write
                print -r -- "hop: this terminal is now '$nm' (outside the hub — run hop to join it)"
            fi ;;
        list)
            if (( $+commands[tmux] )) && _hop_tm has-session -t hub 2>/dev/null; then
                print -r -- "hub sessions:"
                _hop_tm list-windows -t hub -F '  #{window_index}  #{window_name}'
            else
                print -r -- "hub not running — start it with: hop"
            fi ;;
        help|-h|--help)
            print -r -- 'hop — your terminals, multiplexed (tmux-backed hub)
  hop              outside the hub: attach (creates it first time)
                   inside the hub:  jump to the sidebar
  hop name <n>     rename the current session
  hop list         list hub sessions from anywhere
Sidebar: ↑↓/jk browse (right pane follows) · 1-9 jump · ⏎ into session
         r rename · n new · x kill · t themes · d detach · q hide
Themes mode (t): browse re-themes the whole hub live; ⏎ keep, esc undo,
g glow. Sessions keep running when you close the terminal; hop brings you
back. HOP_AUTO=1 auto-joins every new shell as its own hub session; plain
terminals that have not joined appear under "outside" (list-only — a
running pty cannot be moved into the hub).' ;;
        _sidebar) _hop_sidebar ;;
        *) print -u2 "hop: unknown command '$1' (try: hop help)"; return 1 ;;
    esac
}
compdef '_arguments "1:cmd:(name list help)"' hop 2>/dev/null
