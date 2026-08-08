# playful-zsh 🌈

Tiny, playful, **dependency-free** zsh prompt themes. No Oh-My-Zsh, no Powerlevel,
no plugins, no Nerd Fonts — just small zsh scripts you can read in a minute.
Two-line prompts with git status, an exit-code marker, a command timer, a
right-side clock — and a fully **offline** श्लोक engine that greets you with
verses from the Bhagavad Gita, Ramcharitmanas, Sundarkand, and Hanuman Chalisa,
in Devanagari with Hindi and English meanings.

## Install

One command, anywhere:

```sh
git clone https://github.com/indulge/playful-zsh.git ~/.prompt && ~/.prompt/install.sh
```

Or install into any path and start on a chosen theme:

```sh
git clone https://github.com/indulge/playful-zsh.git ~/dotfiles/prompt && ~/dotfiles/prompt/install.sh peacock
```

The installer adds one managed block to your `~/.zshrc` (idempotent — safe to
re-run). Restart the shell, or `source ~/.zshrc`.

## Use

One command: `theme`.

```sh
theme                   # 🎨 panel: browse themes w/ full preview + effects
theme peacock           # switch now, remembered next time
theme list              # list themes, mark the current one
theme gallery           # preview every theme in color
theme random            # surprise me
theme glow [on|off]     # ✨ glow: bold prompt & file colors
```

Tab-completion knows every subcommand and theme name.

### The picker panel

Bare `theme` opens a full-screen picker panel. As you browse with
`↑↓`/`jk` (or `1-9`), the whole panel re-chromes itself in the highlighted
theme's colors and the preview re-renders **every themed element**: the
two-line prompt sample (path, git branch, dirty `●`, arrows) and the file
palette — folder, plain file, symlink, executable, pipe, archive, image,
broken link. `✓` marks the active theme.

```
╔═ themes ─ 8/14 ═════════════════════════════════
║    7   gruvbox    📼 retro groove: warm earth tones
║ ▸  8   matrix     💊 digital rain, phosphor green
╟─ preview ───────────────────────────────────────
║  「~/zion」 on main ●
║  λ
║  folder/  file  link@  bin*  pipe|  pack.tar  img.png  gone@
╟─ effects ───────────────────────────────────────
║  [g] glow: off   [p] full paths: on
║  ↑↓/jk browse · 1-9 jump · ⏎ apply · g/p effects · q quit
╚═════════════════════════════════════════════════
```

`⏎` applies + persists the highlighted theme; `q`/`Esc` keeps yours.
Effects toggle live from the panel and stick either way:

- `g` — ✨ glow: embolden the prompt and all file colors (persisted to `glow`)
- `p` — full paths: `%~` → `%d` in prompts (persisted to `fullpaths`,
  which overrides the `PROMPT_FULL_PATHS` env default)

Your choice is saved to `current` (and glow to `glow`) in the install
directory.

Themes color more than the prompt: each one ships a matching `LS_COLORS`
palette, so **folder names, symlinks, executables, broken links, archives and
media** in `ls`, `tree`, `fd` and tab-completion listings switch with the
theme too.

## श्लोक — verses, offline, any time

Every new shell opens with a gradient block-art card: a verse in Devanagari
with its meaning in Hindi **and** English. All text lives in plain files in
`quotes/` — no internet, ever.

```sh
shlok                   # a random verse (never the same one twice in a row)
shlok daily             # today's verse — same all day, changes at midnight
shlok gita 2.47         # a specific verse
gita · ramayan · sundarkand · chalisa      # shortcuts per collection
shlok list              # browse everything
```

**Alt-G** shows a fresh verse right above whatever you're typing, prompt
redrawn intact.

Add your own collection: drop a `quotes/mycollection.txt` in the same
`@title/@icon/@ramp/@art` + `[id]/t:/v:/hi:/en:` format and it joins the
rotation automatically.

## Little joys (all offline)

- 🌔 **The real moon lives in your prompt.** Phase is computed from pure date
  arithmetic; the banner names the पक्ष, and on the true full/new moon it says
  पूर्णिमा / अमावस्या.
- 📿 **Japa-mala:** every 108th command earns `एक माला पूर्ण`.
- 🪶 **Karma-phala consolation:** when a command runs ≥10s and *fails*, one dim
  Gita line appears — the effort was yours; the fruit was never yours to hold.
- ●·● **Feather of fortune** (peacock theme): the last 8 exit codes as tiny dots
  on the right — visible only when something recently failed.
- 🙏 **Farewell:** leaving the shell prints धन्यवाद with your session stats.

Knobs (set before the managed block in `~/.zshrc`): `PROMPT_BANNER=0`,
`PROMPT_SHLOK=0`, `PROMPT_KARMA=0`, `PROMPT_FAREWELL=0`, `PROMPT_FOLLOW=0`
(shells stop following theme switches made in other shells).

## Themes

| name        | vibe |
|-------------|------|
| `peacock`   | 🦚 the flagship — royal blue, emerald & gold; coral only for failure (a feather has no red) |
| `candy`     | 🍭 bubblegum pinks & mint |
| `bubblegum` | 🫧 soft pastel candy floss |
| `synthwave` | 🌆 80s neon magenta & cyan |
| `galaxy`    | 🌌 cosmic violets & starlight |
| `ocean`     | 🌊 deep blues, teal & aqua |
| `forest`    | 🌲 mossy greens & lime |
| `sunset`    | 🌅 warm orange, coral & dusk |
| `rainbow`   | 🌈 full-spectrum, gradient arrows |
| `matrix`    | 💊 digital rain — phosphor greens, 「path」 in CJK brackets, λ prompt |
| `dracula`   | 🧛 the editor classic: purple, pink & cyan |
| `gruvbox`   | 📼 retro groove — warm earth tones |
| `nord`      | 🧊 arctic frost blues & aurora accents |
| `crt`       | 🖥️ amber phosphor terminal — one color, five brightnesses, ▮ block cursor |

`peacock` also shows: user@host over SSH, active venv/conda 🐍, background
jobs ✦, the moon 🌔, and iridescent ❯❯❯ arrows that shift one hue along the
feather with every command.

## Add your own theme

Drop a file in `themes/`, e.g. `themes/mint.zsh`:

```zsh
_prompt_themes[mint]='🌿 cool fresh mint'
# file colors: <dir> <link> <exec> <special> <broken> <archive> <media>
_pr_ls_register mint 158 115 121 108 210 65 121
_prompt_samples[mint]=$'🌿 %F{158}~/garden%f%F{115} on %F{121}main%f\n%F{121}❯%f'
_prompt_apply_mint() {
    PROMPT='🌿 %F{158}%~%f$(_pr_gitstr 115 121 210)%(1j. %F{121}✦%j%f.)
%(?..%F{210}✘%? )%(?.%F{121}.%F{210})❯%f '
    RPROMPT='$(_pr_timestr 108)%F{65}%*%f'
}
```

Helpers available to themes (each renders nothing when idle):
`_pr_gitstr <onColor> <branchColor> [alertColor]` — branch, dirty ●, ⇡⇣ ahead/behind, ≡ stash ·
`_pr_timestr <color>` — command duration ·
`_pr_venvstr <color>` — venv/conda ·
`_pr_sshstr <userColor> <hostColor>` — user@host over SSH ·
`_pr_trailstr <okColor> <badColor>` — last 8 exit codes ·
`_pr_moonstr` — today's moon ·
`_pr_grad <text> [offset] [ramp…]` — per-character 256-color gradient.
Vars: `$_pr_elapsed` (last duration), `$_pr_last` (exit code), `$_pr_cmds`
(commands this session). Colors are standard zsh `%F{0-255}` codes.

## Uninstall

```sh
~/.prompt/uninstall.sh   # removes the block from ~/.zshrc; files stay
```
