#!/usr/bin/env bash
# himura-desktop: the whole Mor desktop for GNOME 50 in one go.
#
#   ./install.sh                         everything below
#   ./install.sh --no-deps               skip installing distro packages (you have them)
#   ./install.sh --with-away-lock        also Away Lock (needs Howdy for the camera check)
#   ./install.sh --default-file-manager  make Glass Files the default file manager
#   ./install.sh --force                 run on a GNOME other than 50 (untested)
#
# Everything goes to your home folder: sources in ~/.local/src, extensions in
# ~/.local/share/gnome-shell/extensions, themes in ~/.themes and ~/.local/share/themes.
# Only the distro packages need sudo. ./uninstall.sh takes it all back out.
set -euo pipefail

GIT="${HIMURA_GIT:-https://github.com/HIMURAw}"
SRC="${HIMURA_SRC:-$HOME/.local/src}"
EXTENSIONS=(gnome-dynamic-island gnome-glass-dock glass-windows gnome-glass-widgets)
DEPS=1 AWAY=0 DEFAULT_FM=0 FORCE=0
for arg in "$@"; do
    case "$arg" in
    --no-deps) DEPS=0 ;;
    --with-away-lock) AWAY=1 ;;
    --default-file-manager) DEFAULT_FM=1 ;;
    --force) FORCE=1 ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg (see --help)" >&2; exit 1 ;;
    esac
done
((AWAY)) && EXTENSIONS+=(gnome-away-lock)

say() { printf '\n\033[1;35m==>\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# ---------- GNOME ----------
if ! ((FORCE)); then
    if ! have gnome-shell; then
        echo "GNOME Shell not found. This set is made for GNOME 50 (Fedora 44, Ubuntu 26.04, Arch...)." >&2
        exit 1
    fi
    major=$(gnome-shell --version | grep -oE '[0-9]+' | head -1)
    if [[ "$major" != 50 ]]; then
        echo "You have GNOME $major; the extensions are made and tested for GNOME 50." >&2
        echo "Run with --force to try anyway." >&2
        exit 1
    fi
fi

# ---------- distro packages ----------
if ((DEPS)); then
    say "Installing packages (needs sudo)"
    if have dnf; then
        sudo dnf install -y git curl tar xz unzip python3 python3-pillow python3-gobject gtk4 libadwaita \
            ImageMagick sassc gettext glib2 dconf desktop-file-utils xdg-utils gnome-shell-extension-user-theme
    elif have apt-get; then
        sudo apt-get update
        sudo apt-get install -y git curl tar xz-utils unzip python3 python3-pil python3-gi gir1.2-gtk-4.0 \
            gir1.2-adw-1 imagemagick sassc gettext libglib2.0-bin dconf-cli desktop-file-utils xdg-utils gnome-shell-extensions
    elif have pacman; then
        sudo pacman -S --needed --noconfirm git curl tar xz unzip python python-pillow python-gobject gtk4 \
            libadwaita imagemagick sassc gettext glib2 dconf desktop-file-utils xdg-utils gnome-shell-extensions
    elif have zypper; then
        sudo zypper install -y git curl tar xz unzip python3 python3-Pillow python3-gobject \
            typelib-1_0-Gtk-4_0 typelib-1_0-Adw-1 ImageMagick sassc gettext-tools glib2-tools dconf \
            gnome-shell-extension-user-theme
    else
        echo "Unknown package manager. Install these yourself, then run with --no-deps:" >&2
        echo "  git curl tar xz unzip python3 + Pillow + PyGObject, GTK 4, libadwaita, ImageMagick," >&2
        echo "  sassc, gettext, glib2 tools, GNOME's User Themes extension" >&2
        exit 1
    fi
fi

# ---------- sources ----------
say "Getting the sources into $SRC"
mkdir -p "$SRC"
fetch() {  # fetch REPO [DIR]
    local dir="$SRC/${2:-$1}"
    if [[ -d "$dir/.git" ]]; then
        git -C "$dir" pull -q --ff-only || echo "  $dir: could not update, using it as it is"
    else
        git clone -q --depth 1 "$GIT/$1" "$dir"
    fi
}
for repo in mor-theme mor-icons glass-files "${EXTENSIONS[@]}"; do
    fetch "$repo"
    echo "  $repo"
done

# ---------- themes it builds on ----------
THEMES="$HOME/.local/share/themes"
mkdir -p "$THEMES" "$HOME/.themes"
if [[ ! -d "$THEMES/adw-gtk3-dark" && ! -d /usr/share/themes/adw-gtk3-dark ]]; then
    say "adw-gtk3 (GTK 3 apps in the libadwaita style)"
    url=$(curl -fsSL https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest |
        grep -oE '"browser_download_url": *"[^"]+\.tar\.xz"' | head -1 | cut -d'"' -f4)
    curl -fsSL "$url" | tar -xJ -C "$THEMES"
fi
if [[ ! -d "$HOME/.themes/Orchis-Purple-Dark" && ! -d "$THEMES/Orchis-Purple-Dark" ]]; then
    say "Orchis (the Shell theme Mor is drawn from)"
    tmp=$(mktemp -d)
    git clone -q --depth 1 https://github.com/vinceliuice/Orchis-theme "$tmp/orchis"
    (cd "$tmp/orchis" && ./install.sh -t purple -c dark >/dev/null)
    rm -rf "$tmp"
fi
if [[ ! -d /usr/share/icons/Papirus && ! -d "$SRC/papirus-icon-theme" ]]; then
    say "Papirus (the icons Mor recolours)"
    git clone -q --depth 1 https://github.com/PapirusDevelopmentTeam/papirus-icon-theme "$SRC/papirus-icon-theme"
fi

# ---------- Mor theme ----------
say "Mor theme"
mkdir -p "$HOME/.config/tema" "$HOME/.local/bin" "$HOME/.config/gtk-4.0"
[[ -f "$HOME/.config/tema/current.json" ]] || echo '{"name": "mor"}' > "$HOME/.config/tema/current.json"
gtk4="$HOME/.config/gtk-4.0/gtk.css"
if [[ -f "$gtk4" && ! -f "$gtk4.before-himura" ]] && ! grep -q "mor-theme" "$gtk4"; then
    cp "$gtk4" "$gtk4.before-himura"   # your own libadwaita CSS, put back by uninstall.sh
fi
ln -sfn "$SRC/mor-theme/tema-rengi" "$HOME/.local/bin/tema-rengi"
enable_ext() {
    local uuid=$1 enabled
    enabled=$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null || echo "@as []")
    [[ "$enabled" == *"'$uuid'"* ]] && return
    if [[ "$enabled" == "@as []" || "$enabled" == "[]" ]]; then
        gsettings set org.gnome.shell enabled-extensions "['$uuid']" || true
    else
        gsettings set org.gnome.shell enabled-extensions "${enabled%]}, '$uuid']" || true
    fi
}
enable_ext user-theme@gnome-shell-extensions.gcampax.github.com
# tema-rengi builds GTK 3/4 + Shell, sets them, the accent, and Zen/Spotify if you use them
python3 "$SRC/mor-theme/tema-rengi" "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["name"])' \
    "$HOME/.config/tema/current.json")" --no-icons

say "Mor icons (about 34,000, takes 2-3 minutes)"
python3 "$SRC/mor-icons/build.py"
gsettings set org.gnome.desktop.interface icon-theme Mor || true

# ---------- extensions ----------
say "Extensions"
# docks and top-bar extensions that fight with Glass Dock and Dynamic Island
for uuid in ubuntu-dock@ubuntu.com dash-to-dock@micxgx.gmail.com dash2dock-lite@icedman.github.com \
    dash-to-panel@jderose9.github.com; do
    if gsettings get org.gnome.shell enabled-extensions 2>/dev/null | grep -q "'$uuid'" ||
        [[ "$uuid" == ubuntu-dock@ubuntu.com && -d /usr/share/gnome-shell/extensions/$uuid ]]; then
        gnome-extensions disable "$uuid" 2>/dev/null || true
        echo "  turned off $uuid (it clashes; turn it back on in Extensions if you want it)"
    fi
done
for repo in "${EXTENSIONS[@]}"; do
    (cd "$SRC/$repo" && ./install.sh >/dev/null)
    echo "  $repo"
done

# ---------- Glass Files ----------
say "Glass Files"
if ((DEFAULT_FM)); then
    (cd "$SRC/glass-files" && ./install.sh --default)
else
    (cd "$SRC/glass-files" && ./install.sh)
fi

cat <<'EOF'

Done. Log out and back in: GNOME loads new extensions only at login (on Wayland).

  tema-rengi turkuaz      turquoise | yesil | mavi | mor | gri: recolour the whole desktop
  ./uninstall.sh          take it all back out
EOF
