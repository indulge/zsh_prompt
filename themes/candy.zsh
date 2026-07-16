# candy — bubblegum pinks & cyan
_prompt_themes[candy]='🍭 bubblegum pinks & mint'
_prompt_samples[candy]=$'🍭 %F{219}~/candy-shop%f%F{213} on %F{212}main%f %F{197}●%f\n%F{205}❯%f'
_prompt_apply_candy() {
    PROMPT='🍭 %F{219}%~%f$(_pr_gitstr 213 212 197)%(1j. %F{206}✦%j%f.)
%(?..%F{197}✘%? )%(?.%F{205}.%F{197})❯%f '
    RPROMPT='$(_pr_timestr 171)%F{218}%*%f'
}
