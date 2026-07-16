# galaxy — cosmic violets & starlight
_prompt_themes[galaxy]='🌌 cosmic violets & starlight'
_prompt_samples[galaxy]=$'🌌 %F{141}~/cosmos%f%F{99} on %F{183}main%f %F{204}●%f\n%F{141}✦%f'
_prompt_apply_galaxy() {
    PROMPT='🌌 %F{141}%~%f$(_pr_gitstr 99 183 204)%(1j. %F{227}★%j%f.)
%(?..%F{204}✘%? )%(?.%F{141}.%F{204})✦%f '
    RPROMPT='$(_pr_timestr 97)%F{60}%*%f'
}
