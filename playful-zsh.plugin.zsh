# playful-zsh.plugin.zsh — the entry point zsh plugin managers look for.
#
# install.sh still works exactly as before: it sources init.zsh from your
# ~/.zshrc, no framework involved. This file is the other door — the shape the
# managers expect, so adding and removing playful-zsh is one line either way.
#
#   zgenom     zgenom load indulge/playful-zsh
#   antidote   antidote bundle indulge/playful-zsh
#   zinit      zinit light indulge/playful-zsh
#   antigen    antigen bundle indulge/playful-zsh
#   zplug      zplug "indulge/playful-zsh"
#   sheldon    [plugins.playful-zsh] github = "indulge/playful-zsh"
#   oh-my-zsh  git clone …  "$ZSH_CUSTOM/plugins/playful-zsh"
#              plugins=(… playful-zsh)   and   ZSH_THEME=""
#              (oh-my-zsh sources its theme after the plugins — left set, it
#               paints over our prompt.)
#
# Follows the ZSH Plugin Standard:
#   https://wiki.zshell.dev/community/zsh_plugin_standard

# ── standardized $0 handling ────────────────────────────────────────────────
# Managers source, symlink, shim and eval plugin files in every combination.
# This is the standard's two-liner for finding our own directory whatever they
# did with us; init.zsh works out $PROMPT_HOME the same way once it's sourced.
0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
0="${${(M)0:#/*}:-$PWD/$0}"

[[ -o interactive ]] || return 0

# What this shell looked like before us — the unload function hands it back.
# Guarded, so a re-source never snapshots our own prompt over the real one.
# Set-ness is recorded separately from value: a user who exported LS_COLORS=''
# should get an empty LS_COLORS back, not no LS_COLORS at all.
if (( ! ${+_pr_pre_prompt} )); then
    typeset -g  _pr_pre_prompt=$PROMPT       _pr_pre_rprompt=$RPROMPT
    typeset -g  _pr_pre_lscolors=$LS_COLORS  _pr_pre_venv=$VIRTUAL_ENV_DISABLE_PROMPT
    typeset -gi _pr_pre_lsset=${+LS_COLORS}  _pr_pre_venvset=${+VIRTUAL_ENV_DISABLE_PROMPT}
    # The zstyles we are about to overwrite, captured as re-runnable zstyle
    # calls. `-L ':vcs_info:*'` matches contexts, so it takes in :vcs_info:git:*
    # too — and anything the user set under either.
    typeset -g  _pr_pre_zstyles="$(zstyle -L ':vcs_info:*'; zstyle -L ':completion:*' list-colors)"
fi

source "${0:A:h}/init.zsh"

# ── unload ──────────────────────────────────────────────────────────────────
# Managers call {plugin-name}_plugin_unload to take a plugin back out of a
# running shell. Undo what init.zsh wired up — hooks, both chords, the prompt
# and file colors, then every function and parameter we defined. This one goes
# last, deleting itself, as the standard asks.
playful-zsh_plugin_unload() {
    emulate -L zsh
    setopt local_options

    local hook fn arr key

    # hooks: whatever of ours is registered, in whichever order it landed
    for hook in precmd preexec chpwd zshexit; do
        arr="${hook}_functions"
        for fn in "${(@P)arr}"; do
            [[ $fn == (_pr_|_prompt_|_thm_|_utsav|_uamb_|_ufx_|_shlok_|_dl_)* ]] \
                && add-zsh-hook -d $hook $fn
        done
    done

    # the two chords — Alt-G (श्लोक) and Alt-J (उत्सव) — only if still ours
    for key in '\eg' "${PROMPT_UTSAV_KEY:-\ej}"; do
        [[ "$(bindkey $key 2>/dev/null)" == *(shlok-random|utsav-play)* ]] && bindkey -r $key
    done
    zle -D shlok-random utsav-play 2>/dev/null
    unset "_comps[theme]" 2>/dev/null

    # give the shell back its own prompt, file colors and environment
    PROMPT=$_pr_pre_prompt
    RPROMPT=$_pr_pre_rprompt
    if (( _pr_pre_lsset )); then export LS_COLORS=$_pr_pre_lscolors
    else                         unset LS_COLORS; fi
    if (( _pr_pre_venvset )); then export VIRTUAL_ENV_DISABLE_PROMPT=$_pr_pre_venv
    else                           unset VIRTUAL_ENV_DISABLE_PROMPT; fi

    # Only the styles we actually set: a blanket `zstyle -d ':vcs_info:*'` takes
    # the user's own styles in that context down with ours. Then replay the
    # snapshot, which puts back any of these they had set before we loaded.
    zstyle -d ':vcs_info:*'     enable
    zstyle -d ':vcs_info:git:*' check-for-changes formats actionformats
    zstyle -d ':completion:*'   list-colors
    [[ -n $_pr_pre_zstyles ]] && eval $_pr_pre_zstyles

    unset -m '_pr_*' '_prompt_*' '_thm_*' '_utsav*' '_uamb_*' '_ufx_*' '_shlok_*' '_dl_*'
    unset PROMPT_HOME
    unfunction -m '_pr_*' '_prompt_*' '_thm_*' '_utsav*' '_uamb_*' '_ufx_*' '_shlok_*' '_dl_*' 2>/dev/null
    unfunction theme shlok utsav delights gita ramayan sundarkand chalisa prompt-banner 2>/dev/null

    unfunction playful-zsh_plugin_unload
}
