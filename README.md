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
prompt-theme glow       # ✨ toggle glow: bold prompt & file colors
hop                     # 🐇 panel: list / preview / rename / jump terminals
```

Your choice is saved to `current` (and glow to `glow`) in the install
directory.

Themes color more than the prompt: each one ships a matching `LS_COLORS`
palette, so **folder names, symlinks, executables, broken links, archives and
media** in `ls`, `tree`, `fd` and tab-completion listings switch with the
theme too.

## hop 🐇 — jump between your terminals

Every shell running this prompt registers itself in a tiny session registry
(`sessions/`, one file per shell — created automatically, cleaned on exit).
`hop` opens an in-terminal panel over it: scroll through your terminals with
a live preview, name them for your own reference, press Enter to jump.
Pure zsh + ANSI escapes — no tmux required, no fzf, no dependencies, works
over SSH, on x86 and ARM alike.

```
╔═ hop ─ 3 shells ═══════════════════════════════════════╗
║    1 · api-server      ~/projects/bookbase  (this shell)║
║ ▸  2 ● notes-vim       ~/notes              vim journal ║
║    3 · scratch         ~/tmp                —           ║
╟────────────────────────────────────────────────────────╢
║ notes-vim · tty pts/7 · pid 4211 · on main             ║
║ cwd:  ~/notes                                          ║
║ last: vim journal.md ▸ 0 · 2m ago                      ║
╟────────────────────────────────────────────────────────╢
║ ↑↓/jk move · 1-9 jump · ⏎ switch · r rename · q quit   ║
╚════════════════════════════════════════════════════════╝
```

```sh
hop              # open the panel
hop name api     # name this terminal "api" (no panel needed)
hop list         # plain listing, for scripts
hop help         # cheat sheet
```

**Keys:** `↑↓` or `j/k` move (the preview follows) · `1-9` jump straight to a
row · `⏎` switch · `r` rename the selected terminal · `q`/`Esc` quit.
`●` marks a terminal where a command is running right now, `·` one at rest.
The panel is drawn in your active theme's colors — matrix gets a green panel,
crt an amber one. Box-drawing falls back to pure ASCII automatically in
non-UTF-8 locales (or force it with `HOP_ASCII=1`).

**Naming** is the heart of it: `r` (or `hop name`) stores the name in the
registry *and* writes it into the terminal's tab/window title. So your names
also show up in your terminal's own tab bar, and hop's window-focus backends
find windows by exactly those titles. Renaming another session takes effect
at its next prompt. Names survive `cd`s and long-running commands; they die
with the shell.

**What Enter actually does** — best available backend, probed in order:

| # | environment | result |
|---|-------------|--------|
| 1 | both shells inside the same tmux server | true switch to that session/window/pane |
| 2 | macOS (Terminal.app or iTerm2) | focuses the window/tab by title, via `osascript` |
| 3 | Linux X11 with `wmctrl` or `xdotool` installed | focuses the window by title |
| 4 | everywhere else | **teleport**: your current shell `cd`s to the target's directory |

Honesty corner: no OS offers a portable "focus that other terminal window"
primitive, which is why the ladder exists. The live screen preview inside the
panel (last lines of what the other terminal shows) appears only for tmux
panes — nothing else can read another terminal's screen.

### Linux

Works out of the box; how far Enter gets depends on your display stack:

- **Best: run your shells in tmux** (`sudo apt install tmux` / `dnf install
  tmux`). Any hop from inside tmux to another tmux pane is a real switch —
  including between sessions — and previews go live.
- **X11 desktops:** install one small helper for window focus:
  `sudo apt install wmctrl` (or `xdotool`). Name your terminals (`hop name
  api`) — focus matches on the title.
- **Wayland** (default GNOME/KDE on recent distros): there is no standard
  window-activation protocol, so cross-window focus isn't attempted. Use
  tmux for real switching, or rely on named tab titles + your desktop's own
  switcher; Enter otherwise teleports.
- **SSH / bare consoles:** registry, naming, preview and teleport all work;
  use tmux on the remote host for true switching.

### macOS

Works out of the box — `osascript` ships with the OS.

1. Name your terminals (`hop name api`) — focus needs titles to match on.
2. First switch: macOS asks to let your terminal control
   Terminal/iTerm2 — approve it (System Settings ▸ Privacy & Security ▸
   Automation). One-time.
3. Terminal.app and iTerm2 are both supported; hop reads which one the
   target runs in from the registry.
4. tmux users get backend 1 automatically, same as Linux.

### Windows

Run zsh inside **WSL2** (Ubuntu etc.) with **Windows Terminal**:

- The panel, naming, previews and teleport all work as on Linux.
- Windows window focus can't be scripted portably from inside WSL, so hop
  won't move you between Windows Terminal tabs itself — but your `hop
  name`s land in each tab's title (at that shell's next prompt), so the tabs
  are labelled: pick with `Ctrl+Tab`, the tab dropdown, or the command
  palette's "focus tab".
- For true in-place switching, run tmux inside WSL — hop then switches panes
  for real, and you keep one Windows Terminal tab total.
- Git-Bash/Cygwin zsh: untested; the registry and teleport are plain POSIX
  files + escapes and should behave like the SSH case.

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
