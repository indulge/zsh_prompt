#!/usr/bin/env sh
# playful-zsh installer — wires the prompt engine into your ~/.zshrc.
# Idempotent: safe to run repeatedly. Works from any location.
#
#   git clone https://github.com/indulge/playful-zsh.git ~/.prompt && ~/.prompt/install.sh
#
# Optional: pick a starting theme  ->  ~/.prompt/install.sh peacock

set -eu

# Directory this script lives in (the repo root), resolved absolutely.
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
BEGIN='# >>> playful-zsh >>>'
END='# <<< playful-zsh <<<'
# Markers from before the rename to playful-zsh — still stripped on re-install.
OLD_BEGIN='# >>> prompt.sh >>>'
OLD_END='# <<< prompt.sh <<<'

# Optional first arg = starting theme.
if [ "${1:-}" != "" ]; then
    printf '%s\n' "$1" > "$DIR/current"
fi

touch "$ZSHRC"

# Strip any previous managed block, then re-append a fresh one.
tmp=$(mktemp)
awk -v b="$BEGIN" -v e="$END" -v ob="$OLD_BEGIN" -v oe="$OLD_END" '
    $0==b || $0==ob {skip=1} skip && ($0==e || $0==oe) {skip=0; next} !skip
' "$ZSHRC" > "$tmp"
# Drop trailing blank lines for a tidy append.
printf '%s\n' "$(cat "$tmp")" > "$ZSHRC"
rm -f "$tmp"

{
    printf '\n%s\n' "$BEGIN"
    printf '[ -f "%s/init.zsh" ] && source "%s/init.zsh"\n' "$DIR" "$DIR"
    printf '%s\n' "$END"
} >> "$ZSHRC"

printf '\n\033[38;5;213m✦ playful-zsh installed\033[0m  (%s)\n' "$DIR"
printf '  Restart your shell or run:  \033[38;5;045msource %s\033[0m\n' "$ZSHRC"
printf '  Then:  \033[38;5;045mtheme\033[0m  to browse in the panel,  \033[38;5;045mtheme <name>\033[0m to pick.\n'
printf '  And:   \033[38;5;220mshlok\033[0m  for a verse — Gita, Ramayan, Sundarkand, Chalisa — any time.\n\n'
