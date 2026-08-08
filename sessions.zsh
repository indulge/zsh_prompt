# ~/.prompt/sessions.zsh — live session registry: every interactive zsh
# announces itself here so `hop` can list, preview, rename and switch to it.
# One tiny key=value file per shell in $PROMPT_HOME/sessions/, refreshed by
# the prompt hooks that already run (zero extra forks), removed on exit,
# swept by hop when a pid turns out dead.

[[ -o interactive ]] || return
(( ${HOP_SB:-0} )) && return   # hop's sidebar shells are chrome, not sessions

typeset -g _PR_SESS_DIR="$PROMPT_HOME/sessions"
typeset -g _PR_SESS_FILE="$_PR_SESS_DIR/$$.session"
typeset -g TERM_SESSION_NAME=${TERM_SESSION_NAME:-}
typeset -g _pr_sess_cmd='' _pr_sess_state=idle
command mkdir -p "$_PR_SESS_DIR" 2>/dev/null

# Reflect the session name in the emulator tab/window title. This is the
# bridge to the outside world: hop's window-focus backends match on it, and
# your terminal's own tab list shows it too.
_pr_sess_title() {
    [[ -n $TERM_SESSION_NAME ]] || return 0
    print -n "\e]0;${TERM_SESSION_NAME}\a"
}

_pr_sess_write() {
    {
        print -r -- "pid=$$"
        print -r -- "tty=${TTY#/dev/}"
        print -r -- "name=${TERM_SESSION_NAME}"
        print -r -- "cwd=${PWD}"
        print -r -- "cmd=${_pr_sess_cmd}"
        print -r -- "exit=${_pr_last:-0}"
        print -r -- "branch=${_pr_branch}"
        print -r -- "state=${_pr_sess_state}"
        print -r -- "tmux=${TMUX:+${TMUX_PANE}}"
        print -r -- "term=${TERM_PROGRAM:-${WT_SESSION:+WindowsTerminal}}"
        print -r -- "at=${EPOCHSECONDS}"
    } > "$_PR_SESS_FILE" 2>/dev/null
}

_pr_sess_preexec() {
    _pr_sess_cmd=${1[1,120]} _pr_sess_state=run
    _pr_sess_write
}

_pr_sess_precmd() {
    _pr_sess_state=idle
    # hop in another terminal may have renamed us — adopt name + title
    if [[ -f "$_PR_SESS_DIR/$$.rename" ]]; then
        TERM_SESSION_NAME=$(<"$_PR_SESS_DIR/$$.rename")
        command rm -f "$_PR_SESS_DIR/$$.rename" 2>/dev/null
        _pr_sess_title
    fi
    _pr_sess_write
}

_pr_sess_exit() {
    command rm -f "$_PR_SESS_FILE" "$_PR_SESS_DIR/$$.rename" 2>/dev/null
}

# Registered after init.zsh's own precmd, so $_pr_last / $_pr_branch are fresh.
add-zsh-hook preexec _pr_sess_preexec
add-zsh-hook precmd  _pr_sess_precmd
add-zsh-hook zshexit _pr_sess_exit
