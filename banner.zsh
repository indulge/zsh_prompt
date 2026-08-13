# banner.zsh — the startup banner: gradient block-art NAMASTE, a day-part
# greeting in Hindi, the real moon's phase (computed offline in init.zsh),
# and a line of system info. Sourced by init.zsh; fully dependency-free.

# Peacock ramp for the art — indigo → sapphire → turquoise → emerald → gold.
typeset -ga _pr_banner_ramp=(27 33 39 45 44 43 42 48 84 154 220 214 178 135 99 63)

prompt-banner() {
    [[ -t 1 ]] || return

    # NAMASTE in a 2-row block font (pure single-width glyphs — the gradient
    # never breaks alignment, no Nerd Fonts needed).
    local -a art=(
'█▄░█ ▄▀█ █▀▄▀█ ▄▀█ █▀ ▀█▀ █▀▀'
'█░▀█ █▀█ █░▀░█ █▀█ ▄█ ░█░ ██▄'
    )
    print
    local -i i
    for (( i = 1; i <= ${#art}; i++ )); do
        print -n '  '; _pr_grad "${art[i]//░/ }" $(( (i - 1) * 3 )) $_pr_banner_ramp
    done
    print -n '  '; _pr_grad '──────────────✦──────────────' 5 $_pr_banner_ramp

    # Greeting by hour + today's moon (शुक्ल/कृष्ण पक्ष, पूर्णिमा, अमावस्या).
    local h=${(%):-%D{%H}}; h=${h#0}
    local greet icon
    if   (( h >= 5 && h < 12 )); then greet='सुप्रभात'   icon='🌅'
    elif (( h >= 12 && h < 17 )); then greet='नमस्ते'     icon='🌞'
    elif (( h >= 17 && h < 21 )); then greet='शुभ संध्या' icon='🌆'
    else                               greet='शुभ रात्रि'  icon='🌙'; fi
    _pr_moon
    # the greeting knows your साधना title from level 2 on (delights.zsh)
    local who=''
    typeset -f _dl_titlestr >/dev/null && who=$(_dl_titlestr)
    print -P "  ${icon} %F{219}${greet}, %F{213}%n${who}%f%F{243}!%f  %F{242}%D{%a %d %b · %H:%M}%f  ${_pr_moon_icon} %F{111}${_pr_moon_name}%f"

    # System info — distro, shell, where you are (os-release parsed in pure zsh).
    local distro='' ver='' line
    if [[ -r /etc/os-release ]]; then
        for line in "${(@f)$(</etc/os-release)}"; do
            case $line in
                (NAME=*)       distro=${${line#NAME=}//\"/} ;;
                (VERSION=*)    ver=${${line#VERSION=}//\"/} ;;
                (VERSION_ID=*) : ${ver:=${${line#VERSION_ID=}//\"/}} ;;
            esac
        done
    fi
    print -P "  %F{242}🐧 ${distro} ${ver} · 🐚 zsh ${ZSH_VERSION} · 💻 %m · 📂 %~%f"
}
