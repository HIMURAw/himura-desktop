# himura-desktop

A frosted glass desktop for GNOME 50 with its own shape (45° cut corners, thin lavender
lines): a dynamic island in the top bar, a dock, desktop widgets, Windows-style snapping, a
file manager and a theme for everything else, all switching colour together.

**Take all of it, or only the parts you like.** Each part works on its own: only the
island, only the dock, the widgets with your own theme, anything.

![Dynamic Island control center](screenshots/island.png)

```bash
curl -fsSL https://raw.githubusercontent.com/HIMURAw/himura-desktop/main/install.sh | bash
```

It shows the parts with a checkbox each; pick, press Enter, then log out and back in. Or name
the parts straight away:

```bash
curl -fsSL https://raw.githubusercontent.com/HIMURAw/himura-desktop/main/install.sh | bash -s -- island
curl -fsSL https://raw.githubusercontent.com/HIMURAw/himura-desktop/main/install.sh | bash -s -- island widgets theme
```

Prefer to read it first? `git clone https://github.com/HIMURAw/himura-desktop && cd himura-desktop && ./install.sh`

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

`./install.sh all` takes everything but Away Lock; `./install.sh --list` prints the parts.
Only the packages the chosen parts need are installed.

![Glass Dock](screenshots/dock.png)

![Glass Widgets](screenshots/widgets.png)

## One colour for the whole desktop

```bash
tema-rengi turkuaz    # turquoise
tema-rengi yesil      # green
tema-rengi mavi       # blue
tema-rengi mor        # violet (the original)
tema-rengi gri        # grey
tema-rengi cam        # glass: dusk lake wallpaper, soft blue
```

`tema-rengi` comes with `theme`. The island, dock, widgets, window frames and Glass Files change at once; the GTK and Shell
theme, accent colour and wallpaper are rebuilt; the icons are repainted in the background
(2-3 minutes). If you use them, Zen Browser and Spotify ([Spicetify](https://spicetify.app))
follow too; see the [Mor theme](https://github.com/HIMURAw/mor-theme) README for those.

## Does it work on my distro?

It needs **GNOME 50**, not a particular distro. Fedora 44, Ubuntu 26.04 and Arch have it.
The installer knows `dnf`, `apt`, `pacman` and `zypper`; on anything else install the
packages it lists and run `./install.sh --no-deps`.

It does not work on KDE, Xfce or other desktops, and the extensions are not tested on
GNOME 49 or older (`--force` lets you try).

## Options

```bash
./install.sh --no-deps               # you installed the packages yourself
./install.sh files --default-file-manager  # Glass Files opens your folders
./install.sh --force                 # GNOME other than 50, at your own risk
```

Only when you take the dock or the island, the installer turns off the docks and top bars
that clash with them (Ubuntu Dock, Dash to Dock, Dash2Dock; Dash to Panel) and tells you which.

Everything lives in your home folder; only the distro packages need `sudo`. Sources go to
`~/.local/src`; run the installer again to update, or to add more parts later.

## Uninstall

```bash
./uninstall.sh              # everything, back to GNOME's own look; sources stay
./uninstall.sh dock         # only some parts
./uninstall.sh --purge      # also delete the sources
```

Your own `~/.config/gtk-4.0/gtk.css`, if you had one, is put back.

## License

GPL-3.0, like every part of the set.
