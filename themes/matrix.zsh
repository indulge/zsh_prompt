# matrix — 💊 digital rain. Phosphor greens only, darkest for structure,
# brightest for what matters; the path sits in CJK corner brackets 「」 and
# the prompt is a lambda. Red exists solely for the red pill (errors/alerts).
#
#   frame 28 dark green   path 46 bright green   branch 40 green
#   jobs ✦ 34             venv 118 lime          errors 196 red pill

_prompt_themes[matrix]='💊 digital rain, phosphor green'
# file colors: bright-green dirs, lime executables, red-pill broken links
_pr_ls_register matrix 46 40 118 34 196 28 77
_prompt_samples[matrix]=$'%F{28}「%f%B%F{46}~/zion%f%b%F{28}」%f %F{28}on %F{40}main%f %F{196}●%f\n%F{46}λ%f'

_prompt_apply_matrix() {
    PROMPT='%F{28}「%f$(_pr_sshstr 241 40)%B%F{46}%~%f%b%F{28}」%f$(_pr_gitstr 28 40 196)$(_pr_venvstr 118)%(1j. %F{34}✦%j%f.)
%(?..%F{196}✘%? )%(?.%F{46}.%F{196})λ%f '
    RPROMPT='$(_pr_timestr 118)$(_pr_trailstr 34 196)%F{28}%*%f'
}
