# dracula — 🧛 the beloved dark-editor palette, mapped to 256 colors:
# purple 141, pink 212, cyan 117, green 84, orange 215, red 203, comment 61.
# Structure is comment-grey, data is pink, success is green — just like a
# well-highlighted buffer.

_prompt_themes[dracula]='🧛 editor classic: purple, pink & cyan'
# file colors: purple dirs, cyan links, green executables, orange archives
_pr_ls_register dracula 141 117 84 212 203 215 228
_prompt_samples[dracula]=$'🧛 %F{141}~/castle%f%F{61} on %F{212}main%f %F{203}●%f\n%F{141}❯%f'

_prompt_apply_dracula() {
    PROMPT='🧛 $(_pr_sshstr 61 117)%F{141}%~%f$(_pr_gitstr 61 212 203)$(_pr_venvstr 84)%(1j. %F{117}✦%j%f.)
%(?..%F{203}✘%? )%(?.%F{141}.%F{203})❯%f '
    RPROMPT='$(_pr_timestr 215)$(_pr_trailstr 84 203)%F{61}%*%f'
}
