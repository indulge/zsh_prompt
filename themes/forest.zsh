# forest — mossy greens & lime
_prompt_themes[forest]='🌲 mossy greens & lime'
# file colors: moss dirs, fern links, lime executables, olive archives
_pr_ls_register forest 114 78 154 42 203 100 65
_prompt_samples[forest]=$'🌲 %F{114}~/woods%f%F{78} on %F{154}main%f %F{203}●%f\n%F{42}❯%f'
_prompt_apply_forest() {
    PROMPT='🌲 %F{114}%~%f$(_pr_gitstr 78 154 203)%(1j. %F{190}✦%j%f.)
%(?..%F{203}✘%? )%(?.%F{42}.%F{203})❯%f '
    RPROMPT='$(_pr_timestr 100)%F{65}%*%f'
}
