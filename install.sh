#!/usr/bin/env sh
# prompt.sh installer — wires the prompt engine into your ~/.zshrc.
# Idempotent: safe to run repeatedly. Works from any location.
#
#   git clone https://github.com/indulge/zsh-prompt.git ~/.prompt && ~/.prompt/install.sh
#
# Optional: pick a starting theme  ->  ~/.prompt/install.sh peacock

set -eu

# Directory this script lives in (the repo root), resolved absolutely.
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
BEGIN='# >>> prompt.sh >>>'
END='# <<< prompt.sh <<<'

# Optional first arg = starting theme.
if [ "${1:-}" != "" ]; then
    printf '%s\n' "$1" > "$DIR/current"
fi

touch "$ZSHRC"

# Strip any previous managed block, then re-append a fresh one.
tmp=$(mktemp)
awk -v b="$BEGIN" -v e="$END" '
    $0==b {skip=1} skip && $0==e {skip=0; next} !skip
' "$ZSHRC" > "$tmp"
# Drop trailing blank lines for a tidy append.
printf '%s\n' "$(cat "$tmp")" > "$ZSHRC"
rm -f "$tmp"

{
    printf '\n%s\n' "$BEGIN"
    printf '[ -f "%s/init.zsh" ] && source "%s/init.zsh"\n' "$DIR" "$DIR"
    printf '%s\n' "$END"
} >> "$ZSHRC"

printf '\n\033[38;5;213m✦ prompt.sh installed\033[0m  (%s)\n' "$DIR"
printf '  Restart your shell or run:  \033[38;5;045msource %s\033[0m\n' "$ZSHRC"
printf '  Then:  \033[38;5;045mprompt-theme gallery\033[0m  to browse,  \033[38;5;045mprompt-theme <name>\033[0m to pick.\n'
printf '  And:   \033[38;5;220mshlok\033[0m  for a verse — Gita, Ramayan, Sundarkand, Chalisa — any time.\n\n'
