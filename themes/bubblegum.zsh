# bubblegum — soft pastels, easy on the eyes
_prompt_themes[bubblegum]='🫧 soft pastel candy floss'
# file colors: pastel-blue dirs, pink links, mint executables
_pr_ls_register bubblegum 153 218 158 182 211 223 146
_prompt_samples[bubblegum]=$'🫧 %F{153}~/pastel%f%F{218} on %F{223}main%f %F{211}●%f\n%F{218}✿%f'
_prompt_apply_bubblegum() {
    PROMPT='🫧 %F{153}%~%f$(_pr_gitstr 218 223 211)%(1j. %F{158}✦%j%f.)
%(?..%F{211}✘%? )%(?.%F{218}.%F{211})✿%f '
    RPROMPT='$(_pr_timestr 182)%F{146}%*%f'
}
