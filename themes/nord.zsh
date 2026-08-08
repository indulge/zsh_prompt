# nord — 🧊 arctic, north-bluish. Frost blues 109/110/111 carry structure,
# aurora colors carry state: green 144 ok, yellow 222 attention, red 131 bad,
# purple 139 jobs. Calm, dim, glacial.

_prompt_themes[nord]='🧊 arctic frost blues & aurora'
# file colors: frost-blue dirs, ice links, aurora-green executables
_pr_ls_register nord 110 109 144 139 131 173 222
_prompt_samples[nord]=$'🧊 %F{110}~/fjord%f%F{60} on %F{109}main%f %F{131}●%f\n%F{111}❯%f'

_prompt_apply_nord() {
    PROMPT='🧊 $(_pr_sshstr 60 110)%F{110}%~%f$(_pr_gitstr 60 109 131)$(_pr_venvstr 144)%(1j. %F{139}✦%j%f.)
%(?..%F{131}✘%? )%(?.%F{111}.%F{131})❯%f '
    RPROMPT='$(_pr_timestr 144)$(_pr_trailstr 144 131)%F{60}%*%f'
}
