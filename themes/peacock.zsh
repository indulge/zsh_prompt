# peacock — 🦚 Krishna's feather. Cool colors are structure (where you are),
# warm colors are data (what changed), and coral means broken — a peacock
# feather contains no red, so red on screen is never decoration.
#
#   quill ╭╰ 30 deep teal   path 43 emerald-teal   branch 220 gold (the eye)
#   alerts 208 copper       jobs ✦ 135 violet      venv 178 goldenrod
#   errors 203 coral        arrows ❯❯❯ shimmer along the feather as you work

_prompt_themes[peacock]='🦚 royal blue, emerald & gold'
# file colors: emerald dirs, feather-blue links, gold executables, coral broken
_pr_ls_register peacock 43 44 220 135 203 178 38
_prompt_samples[peacock]=$'%F{30}╭─%f 🦚 %B%F{43}~/vrindavan%f%b %F{30}on %F{220}main%f %F{208}●%f %F{220}⇡1%f\n%F{30}╰─%f%F{27}❯%F{38}❯%F{48}❯%f'

# The three arrows step one hue along the feather every command — the prompt
# catches the light as you work. All three turn coral when a command fails.
_pr_pc_arrows() {
    if (( _pr_last )); then print -n '%F{203}❯❯❯%f'; return; fi
    local -a r=(27 33 38 44 48 84)
    local -i i=$(( _pr_cmds % 6 ))
    print -n "%F{${r[i+1]}}❯%F{${r[(i+1)%6+1]}}❯%F{${r[(i+2)%6+1]}}❯%f"
}

_prompt_apply_peacock() {
    PROMPT='%F{30}╭─%f 🦚 $(_pr_sshstr 244 44)%B%F{43}%~%f%b$(_pr_gitstr 30 220 208)$(_pr_venvstr 178)%(1j. %F{135}✦%j%f.)
%F{30}╰─%f%(!.%F{196}#%f .)%(?..%F{203}✘%?%f )$(_pr_pc_arrows) '
    RPROMPT='$(_pr_timestr 178)$(_pr_trailstr 48 208)$(_pr_moonstr)%F{136}%*%f'
}
