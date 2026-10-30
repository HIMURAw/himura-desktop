# himura-desktop

A frosted glass desktop for GNOME 50 with its own shape (45° cut corners, thin lavender
lines): a dynamic island in the top bar, a dock, desktop widgets, Windows-style snapping, a
file manager and a theme for everything else, all switching colour together.

**You do not have to take all of it.** Seven separate parts, each works on its own. The
installer lets you tick the ones you want, or you name them on the command line:

```bash
# Pick from a checklist (island, dock, widgets, windows, files, theme, away-lock)
curl -fsSL https://raw.githubusercontent.com/HIMURAw/himura-desktop/main/install.sh | bash

# Or name exactly what you want
curl -fsSL https://raw.githubusercontent.com/HIMURAw/himura-desktop/main/install.sh | bash -s -- dock
curl -fsSL https://raw.githubusercontent.com/HIMURAw/himura-desktop/main/install.sh | bash -s -- island widgets theme
```

Then log out and back in. Only the packages the chosen parts need are installed, and you can
add or remove parts any time later.

Prefer to read the script first?

```bash
git clone https://github.com/HIMURAw/himura-desktop
cd himura-desktop
./install.sh
```

![Glass Dock](screenshots/dock.png)

<!-- screenshot: a full desktop with the island, dock, widgets and a snapped window in the same colour theme, no personal data (use a neutral weather city, an empty notes widget, no chat or assistant icons, no company logos) -->

## What you get

| Part | Name to install it | What it is |
| --- | --- | --- |
| [Dynamic Island](https://github.com/HIMURAw/gnome-dynamic-island) | `island` | The top bar as a small glass island: control center, notifications, what is playing, side islands |
| [Glass Dock](https://github.com/HIMURAw/gnome-glass-dock) | `dock` | A dock with magnification, bouncing launches, badges and smart auto-hide |
| [Glass Widgets](https://github.com/HIMURAw/gnome-glass-widgets) | `widgets` | Desktop widgets: weather, calendar, clock, notes, music, system, network |
| [Glass Windows](https://github.com/HIMURAw/glass-windows) | `windows` | Cut-corner window frames, snap layouts (`Super+Z`), snap assist, `Super`+arrows |
| [Glass Files](https://github.com/HIMURAw/glass-files) | `files` | A file manager laid out like Windows 11 Explorer, in the same look |
| [Mor theme](https://github.com/HIMURAw/mor-theme) + [Mor icons](https://github.com/HIMURAw/mor-icons) | `theme` | GTK 3, GTK 4 / libadwaita and GNOME Shell theme, Papirus recoloured, plus `tema-rengi` |
| [Away Lock](https://github.com/HIMURAw/gnome-away-lock) | `away-lock` | Locks the screen when you walk away (needs Howdy and a camera; not in `all`) |

`./install.sh all` takes everything except Away Lock; `./install.sh --list` prints the parts.

## Which part do I want?

- **I want a nicer top bar and quick settings:** `island`
- **I want a macOS-style dock:** `dock`
- **I want weather, a calendar or notes on my desktop:** `widgets`
- **I want Windows-style snapping and cut-corner window frames:** `windows`
- **I want a file manager that looks like Windows 11 Explorer:** `files`
- **I want apps, icons and the Shell to share one colour:** `theme`
- **I want the screen to lock when I leave my desk:** `away-lock` (needs Howdy face
  recognition and a camera)
- **I just want to try it:** `island dock theme` shows the most change; remove it again with
  `./uninstall.sh`

## One colour for the whole desktop

`tema-rengi` comes with `theme`:

```bash
tema-rengi turkuaz    # turquoise
tema-rengi yesil      # green
tema-rengi mavi       # blue
tema-rengi mor        # violet (the original)
tema-rengi gri        # grey
tema-rengi cam        # glass: dusk lake wallpaper, soft blue
```

The island, dock, widgets, window frames and Glass Files change at once (if you installed
them); the GTK and Shell theme, accent colour and wallpaper are rebuilt; the icons are
repainted in the background (2-3 minutes). If you use them, Zen Browser and Spotify
([Spicetify](https://spicetify.app)) follow too; see the
[Mor theme](https://github.com/HIMURAw/mor-theme) README for those.

## Options

```bash
./install.sh --no-deps                     # you installed the packages yourself
./install.sh files --default-file-manager  # Glass Files opens your folders
./install.sh --force                       # GNOME other than 50, at your own risk
./install.sh --list                        # print the parts and exit
```

## Uninstall

```bash
./uninstall.sh              # everything, back to GNOME's own look; sources stay
./uninstall.sh dock         # only some parts
./uninstall.sh --purge      # also delete the sources in ~/.local/src
```

Extensions are turned off and removed. `theme` brings back GNOME's own theme and icons and
your own `~/.config/gtk-4.0/gtk.css`, if you had one. `files` gives your folders back to
Nautilus. Distro packages and the themes the set builds on (adw-gtk3, Orchis, Papirus) stay.
Log out and back in afterwards.

## FAQ

**Which GNOME version?**
GNOME 50. The extensions are made and tested for it. The installer stops on any other
version; `--force` lets you try anyway, at your own risk.

**Which distros?**
Any with GNOME 50 (Fedora 44, Ubuntu 26.04 and Arch have it). The installer knows `dnf`,
`apt`, `pacman` and `zypper`. On another package manager, install the packages it lists
yourself and run `./install.sh --no-deps`. It does not work on KDE, Xfce or other desktops.

**Why do I have to log out?**
On Wayland GNOME loads new extensions only at login. Log out and back in after installing
or uninstalling extension parts (island, dock, widgets, windows, away-lock).

**How do I update?**
Run `./install.sh` again (or the `curl` line). It pulls the newest sources into
`~/.local/src` and reinstalls the parts you name. If a source cannot be updated, it tells you
and uses what is there.

**Can I add or remove parts later?**
Yes. `./install.sh widgets` adds one; `./uninstall.sh widgets` removes one. The other parts
stay as they are.

**What is `sudo` used for?**
Only for installing distro packages (`dnf`, `apt-get`, `pacman` or `zypper`), and only the
packages the parts you picked need. Everything else is written to your home folder. With
`--no-deps` nothing uses `sudo`.

**Where is everything installed?**
Sources in `~/.local/src`, extensions in `~/.local/share/gnome-shell/extensions`, themes in
`~/.themes` and `~/.local/share/themes`, icons in `~/.local/share/icons`, the `tema-rengi`
command in `~/.local/bin`, the chosen colour in `~/.config/tema/current.json`. The `theme`
part also writes `~/.config/gtk-4.0/gtk.css`; your own is saved as `gtk.css.before-himura`
and put back by `uninstall.sh`.

**Does it clash with my current dock or top bar?**
Only when you pick `dock` or `island`. With `dock`, the installer turns off Ubuntu Dock,
Dash to Dock and Dash2Dock; with `island`, Dash to Panel. It prints each one it turned off;
turn it back on in the Extensions app if you want it. Nothing is turned off for the other
parts.

**Does `away-lock` need anything special?**
Yes: [Howdy](https://github.com/boltgolt/howdy) face recognition and a camera. That is why
it is not part of `all`.

## License

GPL-3.0, like every part of the set. See [LICENSE](LICENSE).
