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
git clone https://github.com/indulge/zsh-prompt.git ~/.prompt && ~/.prompt/install.sh
```

Or install into any path and start on a chosen theme:

```sh
git clone https://github.com/indulge/zsh-prompt.git ~/dotfiles/prompt && ~/dotfiles/prompt/install.sh peacock
```

The installer adds one managed block to your `~/.zshrc` (idempotent — safe to
re-run). Restart the shell, or `source ~/.zshrc`.

## Use

```sh
prompt-theme            # list themes, mark the current one
prompt-theme gallery    # preview every theme in color
prompt-theme peacock    # switch now, remembered next time
theme                   # 🎨 panel: browse themes w/ full preview + effects
prompt-theme random     # surprise me
prompt-theme glow       # ✨ toggle glow: bold prompt & file colors
hop                     # 🐇 the hub: all your sessions, sidebar + live pane
```

### `theme` — the picker panel

`theme` opens a full-screen panel in the hop family. As you browse with
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

Anything else falls through to `prompt-theme`: `theme matrix`,
`theme gallery`, `theme random` all work.

Your choice is saved to `current` (and glow to `glow`) in the install
directory.

Themes color more than the prompt: each one ships a matching `LS_COLORS`
palette, so **folder names, symlinks, executables, broken links, archives and
media** in `ls`, `tree`, `fd` and tab-completion listings switch with the
theme too.

## hop 🐇 — your terminals, multiplexed

`hop` gives you one place where all your sessions live: a left sidebar
listing them (name them, rename them, kill them, spawn new ones) and a right
pane that **is** the actual terminal — claude, vim, top, a build, anything,
at full fidelity. Nothing to alt-tab to: switching sessions is an
in-terminal operation, identical on every platform.

```
┌─ 🦚 hop ───────┬──────────────────────────────────────────────┐
│ ▸ 1 ● claude   │  $ claude                                    │
│   2 · api      │  ╭─ Claude Code ────────────────────────╮    │
│   3 · notes    │  │ ...actual live session...            │    │
│                │  ╰──────────────────────────────────────╯    │
│ ⏎ open  r name │                                              │
│ n new   x kill │     (a real terminal, full fidelity —        │
│ d detach q hide│      tmux is the emulator underneath)        │
│ · peacock      │                                              │
└────────────────┴──────────────────────────────────────────────┘
```

Under the hood it's a dedicated tmux server (own socket — it never touches
any tmux you already use) called the **hub**. Every session is a named
window in it; the sidebar is a themed zsh script in a slim pane.

```sh
hop              # outside the hub: attach — creates it the first time
                 # inside the hub:  jump back to the sidebar from anywhere
hop name api     # rename the current session
hop list         # list hub sessions from any terminal
hop help         # cheat sheet
```

**Sidebar keys:** `↑↓`/`j k` browse — the right pane switches live as you
move · `1-9` jump · `⏎` into the session · `r` rename (also lands in the
terminal-tab title) · `n` new session · `x` kill (asks first) · `t` themes
mode (below) · `d` detach · `q` hide the sidebar (`hop` brings it back).

**Themes mode (`t`):** the rail flips to the theme list and browsing IS
previewing — every `j`/`k` applies the highlighted theme for real: the rail
re-inks, the hub's borders recolor, and every running shell follows at its
next prompt. A compact preview shows the theme's glyphs and file colors.
`⏎` keeps what you see, `Esc` restores the theme *and* glow you entered
with, `g` toggles glow live. (`PROMPT_FOLLOW=0` stops shells from following
the persisted theme.)

```
🎨 themes ──────────────
  1 ✓ forest
▸ 2   matrix
  3   dracula        ↓ …
─ preview ──────────────
💊 ❯ on main ●
dir/ ln@ bin* img gone@
────────────────────────
⏎ keep  g glow
esc undo
· glow off
```

**The "outside" section:** plain terminals that never joined the hub are
listed dimly under `─ outside ─` (from the session registry) so the rail
shows *all* running terminals. They're list-only — an already-running shell
sits on its own pty and physically cannot be moved into tmux — so to make
everything switchable, let new tabs join (below) and start work inside the
hub.

**Jumping between the panes:** **`Alt+h`** → sidebar, **`Alt+l`** → session
pane (vim-style h/l). Both work even while claude, vim, or top own the pane,
because tmux intercepts the keys before the app sees them — and `Alt+h`
respawns the sidebar if you had hidden it. At a shell prompt, typing `hop`
also lands you on the sidebar; tmux's own `C-b o` / `C-b ←→` work too. From
the sidebar, `⏎` is the same as `Alt+l`.

**Layout:** the sidebar takes 20% of the window (set `HOP_WIDTH=25%` — or a
column count like `HOP_WIDTH=30` — before the managed block to change it);
resizing the terminal window resizes both sides proportionally, and the
sidebar adapts its columns to whatever width it gets.

**Sessions survive.** Close the terminal window, reboot your laptop's
emulator, come back tomorrow — `hop` reattaches and everything is still
running. `d` detaches on purpose; the hub keeps working in the background.

**It wears your theme.** The sidebar, its highlights, and the hub's pane
split lines all draw in the active prompt theme's palette — and re-ink
themselves live when you switch (`theme`, `prompt-theme matrix`, …), matrix
green to crt amber, sidebar and borders alike. The theme's emoji sits in the
sidebar header and the theme name in its footer.

**Auto-join** (recommended): `HOP_AUTO=1` before the managed block in
`~/.zshrc` makes every new terminal tab attach to the hub **as its own
fresh session** — open three tabs, and all three appear in every sidebar,
switchable from anywhere. Each tab is an independent view (its own current
session, same shared list). `d` detaches back to the plain outer shell;
`HOP_AUTO=0` turns it off.

### Dependencies & platforms

The prompt, themes, glow, and the `theme` panel need **zsh ≥ 5.0 and
nothing else**. `hop` needs exactly one extra thing: **tmux** (≥ 3.0; it is
the terminal emulator that makes a live right pane possible — a shell
script alone cannot be one).

| platform | install tmux | notes |
|---|---|---|
| Ubuntu / Debian / **WSL2** | `sudo apt install tmux` | works in Windows Terminal, ConEmu, anything |
| Fedora / RHEL | `sudo dnf install tmux` | |
| Arch | `sudo pacman -S tmux` | |
| Alpine | `apk add tmux` | |
| macOS — Apple Silicon & Intel | `brew install tmux` (or MacPorts) | Terminal.app and iTerm2 both fine |
| SSH / headless / ARM boards | distro package, same as above | tmux is plain C — every arch |

Everything else about hop is dependency-free zsh. If tmux is missing, `hop`
says so and tells you the install line for your platform; the rest of the
package works untouched.

**Windows note:** run the package inside WSL2 (any distro). The hub replaces
the old tab-juggling entirely — your Claude/build/notes sessions all live in
one Windows Terminal tab, and survive closing it.

**Nesting note:** `hop` inside a *different* tmux/screen session refuses
politely rather than nesting — run it from a plain terminal.

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
(shells stop following theme switches made elsewhere), `HOP_AUTO=1`
(new terminals auto-join the hop hub).

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
