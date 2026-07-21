# Development Environment

My personal dotfiles for an Arch Linux setup running the i3 window manager.

## What's included

| Area | Files |
| --- | --- |
| Window manager | `i3/config`, `i3status/config` |
| Terminal | [`st`](https://github.com/fooabobabar/st) (`config.h`), `.Xresources` |
| Editors | Emacs (`.emacs`, `.emacs.rc/`, `.emacs.local/`, `.emacs.snippets/`, `.emacs.custom.el`), Vim (`.vimrc`) |
| Shell | `.bashrc`, `.bash_profile`, `.xprofile` |
| Multiplexer | `.tmux.conf`, `.tmux-sessionizer` |
| Git | `.gitconfig` |
| Media / misc | `mpv.conf`, `.sqliterc`, `gf2_config.ini` (gf debugger) |
| Input / X11 | `00-keyboard.conf`, `40-libinput.conf` |
| Firefox | `policies.json` |
| Scripts | `scripts/tmux-sessionizer`, `scripts/clipboard_history` |

## Installation

### 1. Install packages

`packages.sh` bootstraps the [`yay`](https://github.com/Jguer/yay) AUR helper and
installs all the tools I use (tmux, fzf, ripgrep, docker, obs-studio, emacs deps,
etc.). It also builds a handful of programs from source (`st`, `boomer`, `sowon`,
`scrot`, `gf`) and downloads the Iosevka and JetBrains Mono fonts.

```sh
./packages.sh
```

### 2. Deploy the dotfiles

`deploy.sh` reads a manifest file and symlinks each entry into `$HOME` (creating
parent directories as needed). It refuses to overwrite existing non-symlink files.

Manifest format is `filename|operation|destination`, where `destination` is
relative to `$HOME` (empty means `$HOME` itself):

```sh
./deploy.sh MANIFEST         # Emacs, git, sqlite configs
./deploy.sh MANIFEST.linux   # X11, bash, vim, i3, tmux, mpv configs
```

## Fonts

- **Iosevka** — used across Emacs, Vim and i3
- **JetBrains Mono** — used for the Firefox CSS

## Keyboard layout

Add this config inside the `00-keyboard.conf` file in `/etc/X11/xorg.conf.d`:

```
Option "XkbLayout" "us,br"
Option "XkbOptions" "grp:shifts_toggle,ctrl:nocaps,compose:ralt,terminate:ctrl_alt_bksp"
```

## Firefox

### Addons I use
- uBlock Origin
- Vimium C
- Privacy Badger
- Dark Reader
- Return YouTube Dislike
- Control Panel for Twitter

### Install addons
Move the `policies.json` file to `/usr/lib/firefox/distribution`.

### Enabling Firefox CSS

Open `about:config` and set the following to `true`:

```
toolkit.legacyUserProfileCustomizations.stylesheets
browser.formfill.enable
```

Then open `about:support` and find the path of the profile directory. Inside it,
create a `chrome` folder with two files, `userChrome.css` and `userContent.css`,
and put the following in `userChrome.css`:

```css
* {
    font-family: JetBrainsMono Nerd Font;
}
```
