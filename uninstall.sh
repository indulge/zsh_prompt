#!/usr/bin/env sh
# prompt.sh uninstaller — removes the managed block from ~/.zshrc.
# Your theme files stay put; just delete the directory afterwards if you like.
set -eu
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
BEGIN='# >>> prompt.sh >>>'
END='# <<< prompt.sh <<<'
[ -f "$ZSHRC" ] || { echo "no $ZSHRC"; exit 0; }
tmp=$(mktemp)
awk -v b="$BEGIN" -v e="$END" '$0==b {skip=1} skip && $0==e {skip=0; next} !skip' "$ZSHRC" > "$tmp"
mv "$tmp" "$ZSHRC"
printf '\033[38;5;213m✦ prompt.sh removed from %s\033[0m\n' "$ZSHRC"
