# galaxy — cosmic violets & starlight
_prompt_themes[galaxy]='🌌 cosmic violets & starlight'
# file colors: violet dirs, lilac links, starlight executables
_pr_ls_register galaxy 141 183 227 99 204 97 60
_prompt_samples[galaxy]=$'🌌 %F{141}~/cosmos%f%F{99} on %F{183}main%f %F{204}●%f\n%F{141}✦%f'
_prompt_apply_galaxy() {
    PROMPT='🌌 %F{141}%~%f$(_pr_gitstr 99 183 204)%(1j. %F{227}★%j%f.)
%(?..%F{204}✘%? )%(?.%F{141}.%F{204})✦%f '
    RPROMPT='$(_pr_timestr 97)%F{60}%*%f'
}
