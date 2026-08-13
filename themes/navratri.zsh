# navratri — 🌺 उत्सव occasion-wear: nine nights, nine colors. The arrows wear
# the next of the nine canonical colors with every command — a garba circle
# turning in the prompt. All three turn red when a command fails.
_prompt_themes[navratri]='🌺 उत्सव · nine nights, nine colors'
# file colors: saffron dirs, teal links, yellow executables, red broken
_pr_ls_register navratri 208 43 226 129 196 245 40
_prompt_samples[navratri]=$'🌺 %B%F{208}~/garba%f%b %F{43}on %F{226}main%f %F{196}●%f\n%F{208}❯%F{255}❯%F{196}❯%f'

# the nine canonical Navratri colors, in their fixed set
typeset -ga _pr_nvr_nine=(208 255 196 21 226 40 245 129 43)
_pr_nvr_arrows() {
    (( _pr_last )) && { print -n '%F{196}❯❯❯%f'; return }
    local -i i=$(( _pr_cmds % 9 ))
    print -n "%F{${_pr_nvr_nine[i+1]}}❯%F{${_pr_nvr_nine[(i+1)%9+1]}}❯%F{${_pr_nvr_nine[(i+2)%9+1]}}❯%f"
}
_prompt_apply_navratri() {
    PROMPT='🌺 $(_pr_sshstr 244 43)%B%F{208}%~%f%b$(_pr_gitstr 95 226 196)$(_pr_venvstr 40)%(1j. %F{129}✦%j%f.)
%(?..%F{196}✘%?%f )$(_pr_nvr_arrows) '
    RPROMPT='$(_pr_timestr 245)$(_pr_trailstr 43 196)%F{129}%*%f'
}
