# sunset — warm orange, coral & dusk purple
_prompt_themes[sunset]='🌅 warm orange, coral & dusk'
# file colors: orange dirs, peach links, sun-yellow executables, dusk archives
_pr_ls_register sunset 208 215 227 131 197 173 205
_prompt_samples[sunset]=$'🌅 %F{208}~/horizon%f%F{215} on %F{205}main%f %F{197}●%f\n%F{214}➜%f'
_prompt_apply_sunset() {
    PROMPT='🌅 %F{208}%~%f$(_pr_gitstr 215 205 197)%(1j. %F{227}✦%j%f.)
%(?..%F{197}✘%? )%(?.%F{214}.%F{197})➜%f '
    RPROMPT='$(_pr_timestr 173)%F{131}%*%f'
}
