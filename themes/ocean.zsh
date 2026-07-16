# ocean — deep blues, teal & aqua
_prompt_themes[ocean]='🌊 deep blues, teal & aqua'
_prompt_samples[ocean]=$'🌊 %F{39}~/reef%f%F{45} on %F{87}main%f %F{209}●%f\n%F{45}➜%f'
_prompt_apply_ocean() {
    PROMPT='🌊 %F{39}%~%f$(_pr_gitstr 45 87 209)%(1j. %F{123}✦%j%f.)
%(?..%F{209}✘%? )%(?.%F{45}.%F{209})➜%f '
    RPROMPT='$(_pr_timestr 75)%F{31}%*%f'
}
