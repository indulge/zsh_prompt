#!/usr/bin/env sh
# playful-zsh uninstaller — removes the managed block from ~/.zshrc.
# Your theme files stay put; just delete the directory afterwards if you like.
set -eu
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
BEGIN='# >>> playful-zsh >>>'
END='# <<< playful-zsh <<<'
# Markers from before the rename to playful-zsh — removed too.
OLD_BEGIN='# >>> prompt.sh >>>'
OLD_END='# <<< prompt.sh <<<'
[ -f "$ZSHRC" ] || { echo "no $ZSHRC"; exit 0; }
tmp=$(mktemp)
awk -v b="$BEGIN" -v e="$END" -v ob="$OLD_BEGIN" -v oe="$OLD_END" '
    $0==b || $0==ob {skip=1} skip && ($0==e || $0==oe) {skip=0; next} !skip
' "$ZSHRC" > "$tmp"
mv "$tmp" "$ZSHRC"
printf '\033[38;5;213m✦ playful-zsh removed from %s\033[0m\n' "$ZSHRC"
