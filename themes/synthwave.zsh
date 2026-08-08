# synthwave — 80s neon: magenta, cyan, electric purple
_prompt_themes[synthwave]='🌆 80s neon magenta & cyan'
# file colors: magenta dirs, neon-pink links, cyan executables
_pr_ls_register synthwave 201 213 51 135 198 99 135
_prompt_samples[synthwave]=$'🌆 %F{201}~/neon%f%F{99} on %F{51}main%f %F{198}●%f\n%F{51}▶%f'
_prompt_apply_synthwave() {
    PROMPT='🌆 %F{201}%~%f$(_pr_gitstr 99 51 198)%(1j. %F{213}✦%j%f.)
%(?..%F{198}✘%? )%(?.%F{51}.%F{198})▶%f '
    RPROMPT='$(_pr_timestr 99)%F{135}%*%f'
}
