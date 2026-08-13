# holi — 🎨 उत्सव occasion-wear: gulal in the air. Every structural element
# wears a different handful of color — magenta path, cyan git, three arrows
# in three colors; nothing is allowed to be beige today. On होली itself,
# switching here also throws the colors; the palette you may wear any day.
_prompt_themes[holi]='🎨 उत्सव · a handful of every color'
# file colors: magenta dirs, cyan links, basant-yellow executables, red broken
_pr_ls_register holi 201 51 226 129 196 208 82
_prompt_samples[holi]=$'🎨 %B%F{201}~/vrindavan%f%b %F{51}on %F{226}main%f %F{196}●%f\n%F{201}❯%F{226}❯%F{51}❯%f'
_prompt_apply_holi() {
    PROMPT='🎨 $(_pr_sshstr 244 51)%B%F{201}%~%f%b$(_pr_gitstr 51 226 196)$(_pr_venvstr 82)%(1j. %F{129}✦%j%f.)
%(?..%F{196}✘%?%f )%F{201}❯%F{226}❯%F{51}❯%f '
    RPROMPT='$(_pr_timestr 82)$(_pr_trailstr 51 196)%F{129}%*%f'
}
