# crt — 🖥️ vintage amber phosphor. One color, five brightnesses: 220 hot,
# 214 bright, 208 warning, 172 mid, 136 dim, 94 burnt-in. The bezel corners
# ▛ ▙ frame each command and the cursor is a hardware block ▮ — no red
# anywhere, a real terminal only had amber.

_prompt_themes[crt]='🖥️ amber phosphor terminal'
# file colors: every file type an amber brightness, like a real CRT listing
_pr_ls_register crt 220 178 214 136 94 136 172
_prompt_samples[crt]=$'%F{136}▛%f %F{214}~/mainframe%f %F{136}on %F{220}main%f %F{208}●%f\n%F{136}▙%f %F{220}▮%f'

_prompt_apply_crt() {
    PROMPT='%F{136}▛%f $(_pr_sshstr 136 214)%F{214}%~%f$(_pr_gitstr 136 220 208)$(_pr_venvstr 178)%(1j. %F{172}✦%j%f.)
%F{136}▙%f %(?..%F{208}✘%? )%F{220}▮%f '
    RPROMPT='$(_pr_timestr 172)$(_pr_trailstr 136 208)%F{136}%*%f'
}
