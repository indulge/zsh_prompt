# rainbow — every segment a different hue, triple-arrow gradient
_prompt_themes[rainbow]='🌈 full-spectrum, gradient arrows'
# file colors: a different hue per file kind — the whole pot of gold
_pr_ls_register rainbow 203 45 114 99 197 215 220
_prompt_samples[rainbow]=$'🌈 %F{203}~/%F{215}pot%F{220}-o-%F{114}gold%f%F{45} on %F{99}main%f %F{197}●%f\n%F{196}❯%F{208}❯%F{220}❯%f'
_prompt_apply_rainbow() {
    PROMPT='🌈 %F{203}%~%f$(_pr_gitstr 45 99 197)%(1j. %F{220}✦%j%f.)
%(?..%F{197}✘%? )%(?.%F{196}❯%F{208}❯%F{220}❯.%F{197}✘✘✘)%f '
    RPROMPT='$(_pr_timestr 114)%F{99}%*%f'
}
