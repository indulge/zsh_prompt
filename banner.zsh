# banner.zsh — a super-colorful ASCII-art startup banner (dependency-free).
# Sourced by init.zsh, which calls `prompt-banner` once at shell startup.

# A smooth-ish rainbow ramp of 256-color indices.
typeset -ga _pr_banner_ramp=(196 202 208 214 220 190 154 84 43 45 39 63 99 135 171 207 213)

# Print a string with a per-character rainbow gradient (offset by $2 for motion).
_pr_grad() {
    local s=$1 off=${2:-0} n=${#_pr_banner_ramp} i c
    for (( i = 1; i <= ${#s}; i++ )); do
        c=${_pr_banner_ramp[ (( (i + off - 1) % n ) + 1 ) ]}
        print -Pn "%F{$c}${s[i]}%f"
    done
    print
}

prompt-banner() {
    [[ -t 1 ]] || return

    # ASCII-art "hello" — each line gets the next hue on the ramp.
    local -a art=(
'    __         ____'
'   / /_  ___  / / /___'
'  / __ \/ _ \/ / / __ \'
' / / / /  __/ / / /_/ /'
'/_/ /_/\___/_/_/\____/'
    )
    print
    local i
    for (( i = 1; i <= ${#art}; i++ )); do
        print -Pn '  '; _pr_grad "${art[i]}" $(( (i - 1) * 2 ))
    done

    # A rainbow rule under the art.
    print -n '  '; _pr_grad '─────────────────────────────' 3

    # System info — pull distro/version like the classic banner did.
    local distro='' ver='' host=${(%):-%m} user=${(%):-%n}
    if [[ -r /etc/os-release ]]; then
        distro=$(sed -n 's/^NAME=//p' /etc/os-release | tr -d '"')
        ver=$(sed -n 's/^VERSION=//p;s/^VERSION_ID=//p' /etc/os-release | tr -d '"' | head -1)
    fi
    print -P "  %F{213}❄ %F{219}${user}%F{242}@%F{117}${host}%f   %F{242}%D{%a %d %b · %H:%M}%f"
    print -P "  %F{214}🐧 %F{223}${distro} ${ver}%f   %F{80}🐚 zsh ${ZSH_VERSION}%f"
    print -P "  %F{141}📂 %F{189}%~%f"
    print
}
