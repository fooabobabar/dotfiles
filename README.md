# Development Environment

## Firefox Addons that I use
- uBlock Origin
- Vimium C
- Privacy Badger
- Dark Reader
- Return YouTube Dislike
- Mouse Tooltip Translator
- AI Subtitles & Immersive Translate - Trancy
- Control Panel for Twitter

## Font
Iosevka

## Install Firefox Addons
Move the policies.json file to the following path `/usr/lib/firefox/distribution`.

## Enabling Firefox CSS

Open `about:config` and set the following:

```
toolkit.legacyUserProfileCustomizations.stylesheets
browser.formfill.enable
```

to `true`.

After set the value to `true`, open `about:support` and get the path of the profile directory. Then open the profile directory and create a folder named `chrome`.

Inside the `chrome` folder, create two files named `userChrome.css` and `userContent.css` and put the following content inside `userChrome.css`:

```css
* {
    font-family: JetBrainsMono Nerd Font;
}
```

Add this config inside `00-keyboard.conf` file in `/etc/X11/xorg.conf.d` folder.
```
Option "XkbLayout" "us,br"
Option "XkbOptions" "grp:shifts_toggle,ctrl:nocaps,compose:ralt,terminate:ctrl_alt_bksp"
```
