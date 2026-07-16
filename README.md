# prompt.sh 🌈

Tiny, playful, **dependency-free** zsh prompt themes. No Oh-My-Zsh, no Powerlevel,
no plugins, no Nerd Fonts — just a couple of small zsh scripts you can read in a
minute. Two-line prompts with git status, an exit-code marker, a command timer,
and a right-side clock, wrapped in cheerful color palettes you can switch live.

## Install

One command, anywhere:

```sh
git clone <repo-url> ~/.prompt && ~/.prompt/install.sh
```

Or install into any path and start on a chosen theme:

```sh
git clone <repo-url> ~/dotfiles/prompt && ~/dotfiles/prompt/install.sh ocean
```

The installer adds one managed block to your `~/.zshrc` (idempotent — safe to
re-run). Restart the shell, or `source ~/.zshrc`.

## Use

```sh
prompt-theme            # list themes, mark the current one
prompt-theme gallery    # preview every theme in color
prompt-theme ocean      # switch now, remembered next time
prompt-theme random     # surprise me
```

Your choice is saved to `~/.prompt/current`.

## Themes

| name        | vibe |
|-------------|------|
| `candy`     | 🍭 bubblegum pinks & mint |
| `bubblegum` | 🫧 soft pastel candy floss |
| `synthwave` | 🌆 80s neon magenta & cyan |
| `galaxy`    | 🌌 cosmic violets & starlight |
| `ocean`     | 🌊 deep blues, teal & aqua |
| `forest`    | 🌲 mossy greens & lime |
| `sunset`    | 🌅 warm orange, coral & dusk |
| `rainbow`   | 🌈 full-spectrum, gradient arrows |

## Add your own

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

Helpers available to themes: `_pr_gitstr <onColor> <branchColor> [alertColor]`
and `_pr_timestr <color>` (the command-duration segment), plus vars
`$_pr_elapsed` (last command duration) and `$_pr_last` (exit code).
Colors are standard zsh `%F{0-255}` codes.

## Uninstall

```sh
~/.prompt/uninstall.sh   # removes the block from ~/.zshrc; files stay
```
