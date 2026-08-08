# gruvbox — 📼 retro groove. Warm cream-on-dark hues from the classic scheme:
# blue 109, aqua 108, green 142, yellow 214, orange 208, purple 175, red 167.
# Earthy and low-contrast, like a terminal with a wood-grain bezel.

_prompt_themes[gruvbox]='📼 retro groove: warm earth tones'
# file colors: gruv-blue dirs, aqua links, green executables, orange archives
_pr_ls_register gruvbox 109 108 142 175 167 208 214
_prompt_samples[gruvbox]=$'📼 %F{214}~/tape-deck%f%F{108} on %F{142}main%f %F{167}●%f\n%F{208}▸%f'

_prompt_apply_gruvbox() {
    PROMPT='📼 $(_pr_sshstr 245 109)%F{214}%~%f$(_pr_gitstr 108 142 167)$(_pr_venvstr 142)%(1j. %F{175}✦%j%f.)
%(?..%F{167}✘%? )%(?.%F{208}.%F{167})▸%f '
    RPROMPT='$(_pr_timestr 109)$(_pr_trailstr 142 167)%F{137}%*%f'
}
