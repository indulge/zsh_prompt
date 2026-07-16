# prompt.sh 🌈

Tiny, playful, **dependency-free** zsh prompt themes. No Oh-My-Zsh, no Powerlevel,
no plugins, no Nerd Fonts — just small zsh scripts you can read in a minute.
Two-line prompts with git status, an exit-code marker, a command timer, a
right-side clock — and a fully **offline** श्लोक engine that greets you with
verses from the Bhagavad Gita, Ramcharitmanas, Sundarkand, and Hanuman Chalisa,
in Devanagari with Hindi and English meanings.

## Install

One command, anywhere:

```sh
git clone https://github.com/indulge/zsh_prompt.git ~/.prompt && ~/.prompt/install.sh
```

Or install into any path and start on a chosen theme:

```sh
git clone https://github.com/indulge/zsh_prompt.git ~/dotfiles/prompt && ~/dotfiles/prompt/install.sh peacock
```

The installer adds one managed block to your `~/.zshrc` (idempotent — safe to
re-run). Restart the shell, or `source ~/.zshrc`.

## Use

```sh
prompt-theme            # list themes, mark the current one
prompt-theme gallery    # preview every theme in color
prompt-theme peacock    # switch now, remembered next time
prompt-theme random     # surprise me
```

Your choice is saved to `current` in the install directory.

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
`PROMPT_SHLOK=0`, `PROMPT_KARMA=0`, `PROMPT_FAREWELL=0`.

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

`peacock` also shows: user@host over SSH, active venv/conda 🐍, background
jobs ✦, the moon 🌔, and iridescent ❯❯❯ arrows that shift one hue along the
feather with every command.

## Add your own theme

Drop a file in `themes/`, e.g. `themes/mint.zsh`:

```zsh
_prompt_themes[mint]='🌿 cool fresh mint'
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
