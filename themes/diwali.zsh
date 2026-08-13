# diwali — 🪔 उत्सव occasion-wear: अमावस्या night lit by rows of lamps. The
# darkest night of the year is the one with the most light — lamp-gold path,
# saffron flame before the arrow, smoke-grey structure. On दीपावली itself,
# switching here also brings the fireworks; the palette you may wear any day.
_prompt_themes[diwali]='🪔 उत्सव · lamp-gold on the darkest night'
# file colors: gold dirs, warm-sand links, amber executables, coral broken
_pr_ls_register diwali 220 180 214 208 203 130 178
_prompt_samples[diwali]=$'🪔 %B%F{220}~/ayodhya%f%b %F{95}on %F{214}main%f %F{208}●%f\n%F{208}✦%f %F{220}❯%f'
_prompt_apply_diwali() {
    PROMPT='🪔 $(_pr_sshstr 244 180)%B%F{220}%~%f%b$(_pr_gitstr 95 214 203)$(_pr_venvstr 178)%(1j. %F{135}✦%j%f.)
%(?..%F{203}✘%?%f )%F{208}✦%f%F{220}❯%f '
    RPROMPT='$(_pr_timestr 180)$(_pr_trailstr 220 203)%F{95}%*%f'
}
