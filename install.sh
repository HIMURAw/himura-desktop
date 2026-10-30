#!/usr/bin/env bash
# himura-desktop: a glass desktop for GNOME 50. Take all of it, or only the parts you want.
#
#   ./install.sh                         pick the parts from a list
#   ./install.sh island                  only Dynamic Island
#   ./install.sh island widgets theme    any parts, in any order
#   ./install.sh all                     everything except Away Lock
#
# Without cloning:
#   curl -fsSL https://raw.githubusercontent.com/HIMURAw/himura-desktop/main/install.sh | bash -s -- island
#
# Parts:
#   island     Dynamic Island: the top bar as a glass island
#   dock       Glass Dock: a dock with magnification and smart auto-hide
#   widgets    Glass Widgets: weather, calendar, clock, notes, music, system on the desktop
#   windows    Glass Windows: cut-corner window frames, snap layouts
#   files      Glass Files: a file manager laid out like Windows 11 Explorer
#   theme      Mor theme and icons: GTK 3/4, libadwaita, Shell and Papirus in one colour (tema-rengi)
#   away-lock  Away Lock: locks the screen when you walk away (needs Howdy)
#
# Options:
#   --no-deps               skip installing distro packages (you have them)
#   --default-file-manager  with files: Glass Files opens your folders
#   --force                 run on a GNOME other than 50 (untested)
#   --list                  print the parts and exit
#
# Everything goes to your home folder: sources in ~/.local/src, extensions in
# ~/.local/share/gnome-shell/extensions, themes in ~/.themes and ~/.local/share/themes.
# Only the distro packages need sudo. Run it again to update; ./uninstall.sh takes parts back out.
set -euo pipefail

GIT="${HIMURA_GIT:-https://github.com/HIMURAw}"
SRC="${HIMURA_SRC:-$HOME/.local/src}"

PARTS=(island dock widgets windows files theme away-lock)
declare -A NAME=(
    [island]="Dynamic Island" [dock]="Glass Dock" [widgets]="Glass Widgets" [windows]="Glass Windows"
    [files]="Glass Files" [theme]="Mor theme + icons" [away-lock]="Away Lock"
)
declare -A ABOUT=(
    [island]="the top bar as a glass island: control center, notifications, media"
    [dock]="a dock with magnification, bouncing launches and smart auto-hide"
    [widgets]="weather, calendar, clock, notes, music and system on the desktop"
    [windows]="cut-corner window frames, snap layouts (Super+Z), Super+arrows"
    [files]="a file manager laid out like Windows 11 Explorer"
    [theme]="GTK, libadwaita, Shell and icons in one colour; tema-rengi recolours all"
    [away-lock]="locks the screen when you walk away (needs Howdy and a camera)"
)
declare -A REPO=(
    [island]=gnome-dynamic-island [dock]=gnome-glass-dock [widgets]=gnome-glass-widgets
    [windows]=glass-windows [files]=glass-files [away-lock]=gnome-away-lock
)

say() { printf '\n\033[1;35m==>\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
usage() { sed -n '2,/^set -euo/p' "${BASH_SOURCE[0]}" | sed '$d; s/^# \{0,1\}//'; }

DEPS=1 DEFAULT_FM=0 FORCE=0
declare -A WANT=()
for arg in "$@"; do
    case "$arg" in
    --no-deps) DEPS=0 ;;
    --default-file-manager) DEFAULT_FM=1 ;;
    --force) FORCE=1 ;;
    --list) for p in "${PARTS[@]}"; do printf '  %-10s %s: %s\n' "$p" "${NAME[$p]}" "${ABOUT[$p]}"; done; exit 0 ;;
    -h|--help) usage 2>/dev/null || echo "See https://github.com/HIMURAw/himura-desktop"; exit 0 ;;
    all) for p in "${PARTS[@]}"; do [[ $p == away-lock ]] || WANT[$p]=1; done ;;
    *)
        if [[ -n "${NAME[$arg]+x}" ]]; then WANT[$arg]=1
        else echo "Unknown part or option: $arg (parts: ${PARTS[*]}; see --help)" >&2; exit 1
        fi ;;
    esac
done

# ---------- which parts ----------
# No parts named: a checklist on the terminal (works through curl | bash too, via /dev/tty).
if ((${#WANT[@]} == 0)); then
    if [[ -r /dev/tty ]] && { exec 3</dev/tty; } 2>/dev/null; then
        for p in "${PARTS[@]}"; do [[ $p == away-lock ]] || WANT[$p]=1; done
        while :; do
            printf '\n\033[1mhimura-desktop\033[0m: pick what to install\n\n'
            i=1
            for p in "${PARTS[@]}"; do
                mark=' '; [[ -n "${WANT[$p]:-}" ]] && mark='x'
                printf '  %d [%s] \033[1m%-18s\033[0m %s\n' $i "$mark" "${NAME[$p]}" "${ABOUT[$p]}"
                i=$((i + 1))
            done
            printf '\nNumbers to switch parts on or off (e.g. "2 3"), a = all, n = none,\n'
            printf 'Enter to install, q to quit: '
            read -r reply <&3 || exit 1
            case "$reply" in
            '') break ;;
            q|Q) exit 0 ;;
            a|A) for p in "${PARTS[@]}"; do WANT[$p]=1; done ;;
            n|N) WANT=() ;;
            *)
                for n in $reply; do
                    [[ "$n" =~ ^[0-9]+$ ]] && ((n >= 1 && n <= ${#PARTS[@]})) || continue
                    p=${PARTS[$((n - 1))]}
                    if [[ -n "${WANT[$p]:-}" ]]; then unset "WANT[$p]"; else WANT[$p]=1; fi
                done ;;
            esac
        done
        exec 3<&-
    else
        for p in "${PARTS[@]}"; do [[ $p == away-lock ]] || WANT[$p]=1; done
    fi
fi
((${#WANT[@]})) || { echo "Nothing picked."; exit 0; }
want() { [[ -n "${WANT[$1]:-}" ]]; }
CHOSEN=(); for p in "${PARTS[@]}"; do want "$p" && CHOSEN+=("$p"); done
EXT=0; for p in island dock widgets windows away-lock; do want $p && EXT=1; done
echo "Installing: ${CHOSEN[*]}"

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

# ---------- distro packages: only what the chosen parts need ----------
if ((DEPS)); then
    if have dnf; then PM=dnf; elif have apt-get; then PM=apt; elif have pacman; then PM=pacman
    elif have zypper; then PM=zypper; else PM=; fi
    if [[ -z $PM ]]; then
        echo "Unknown package manager. Install git, gettext and the glib2 tools (and for files: GTK 4," >&2
        echo "libadwaita, PyGObject; for theme: curl, Pillow, ImageMagick, sassc, User Themes), then" >&2
        echo "run again with --no-deps." >&2
        exit 1
    fi
    pkgs=()
    add() {  # add DNF APT PACMAN ZYPPER  (space-separated package lists)
        local list
        case $PM in dnf) list=$1 ;; apt) list=$2 ;; pacman) list=$3 ;; zypper) list=$4 ;; esac
        read -ra more <<<"$list"
        pkgs+=("${more[@]}")
    }
    add "git" "git" "git" "git"
    if ((EXT)); then
        add "gettext glib2" "gettext libglib2.0-bin" "gettext glib2" "gettext-tools glib2-tools"
    fi
    if want files; then
        add "python3 python3-gobject gtk4 libadwaita desktop-file-utils xdg-utils" \
            "python3 python3-gi gir1.2-gtk-4.0 gir1.2-adw-1 desktop-file-utils xdg-utils" \
            "python python-gobject gtk4 libadwaita desktop-file-utils xdg-utils" \
            "python3 python3-gobject typelib-1_0-Gtk-4_0 typelib-1_0-Adw-1 desktop-file-utils xdg-utils"
    fi
    if want theme; then
        add "curl tar xz unzip python3 python3-pillow ImageMagick sassc dconf gnome-shell-extension-user-theme" \
            "curl tar xz-utils unzip python3 python3-pil imagemagick sassc dconf-cli gnome-shell-extensions" \
            "curl tar xz unzip python python-pillow imagemagick sassc dconf gnome-shell-extensions" \
            "curl tar xz unzip python3 python3-Pillow ImageMagick sassc dconf gnome-shell-extension-user-theme"
    fi
    say "Installing packages (needs sudo): ${pkgs[*]}"
    case $PM in
    dnf) sudo dnf install -y "${pkgs[@]}" ;;
    apt) sudo apt-get update && sudo apt-get install -y "${pkgs[@]}" ;;
    pacman) sudo pacman -S --needed --noconfirm "${pkgs[@]}" ;;
    zypper) sudo zypper install -y "${pkgs[@]}" ;;
    esac
fi

# ---------- sources ----------
say "Getting the sources into $SRC"
mkdir -p "$SRC"
fetch() {  # fetch REPO
    local dir="$SRC/$1"
    if [[ -d "$dir/.git" ]]; then
        git -C "$dir" pull -q --ff-only || echo "  $1: could not update, using it as it is"
    else
        git clone -q --depth 1 "$GIT/$1" "$dir"
    fi
    echo "  $1"
}
for p in "${CHOSEN[@]}"; do
    if [[ $p == theme ]]; then fetch mor-theme; fetch mor-icons; else fetch "${REPO[$p]}"; fi
done

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

# ---------- theme ----------
if want theme; then
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

    say "Mor theme"
    mkdir -p "$HOME/.config/tema" "$HOME/.local/bin" "$HOME/.config/gtk-4.0"
    [[ -f "$HOME/.config/tema/current.json" ]] || echo '{"name": "mor"}' > "$HOME/.config/tema/current.json"
    gtk4="$HOME/.config/gtk-4.0/gtk.css"
    if [[ -f "$gtk4" && ! -f "$gtk4.before-himura" ]] && ! grep -q "mor-theme" "$gtk4"; then
        cp "$gtk4" "$gtk4.before-himura"   # your own libadwaita CSS, put back by uninstall.sh
    fi
    ln -sfn "$SRC/mor-theme/tema-rengi" "$HOME/.local/bin/tema-rengi"
    enable_ext user-theme@gnome-shell-extensions.gcampax.github.com
    # tema-rengi builds GTK 3/4 + Shell, sets them, the accent, and Zen/Spotify if you use them
    python3 "$SRC/mor-theme/tema-rengi" "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["name"])' \
        "$HOME/.config/tema/current.json")" --no-icons

    say "Mor icons (about 34,000, takes 2-3 minutes)"
    python3 "$SRC/mor-icons/build.py"
    gsettings set org.gnome.desktop.interface icon-theme Mor || true
fi

# ---------- extensions ----------
if ((EXT)); then
    say "Extensions"
    # Docks and top bars that fight with Glass Dock or Dynamic Island, only when those are chosen.
    clash=()
    want dock && clash+=(ubuntu-dock@ubuntu.com dash-to-dock@micxgx.gmail.com dash2dock-lite@icedman.github.com)
    want island && clash+=(dash-to-panel@jderose9.github.com)
    for uuid in "${clash[@]}"; do
        if gsettings get org.gnome.shell enabled-extensions 2>/dev/null | grep -q "'$uuid'" ||
            [[ "$uuid" == ubuntu-dock@ubuntu.com && -d /usr/share/gnome-shell/extensions/$uuid ]]; then
            gnome-extensions disable "$uuid" 2>/dev/null || true
            echo "  turned off $uuid (it clashes; turn it back on in Extensions if you want it)"
        fi
    done
    for p in island dock widgets windows away-lock; do
        want $p || continue
        (cd "$SRC/${REPO[$p]}" && ./install.sh >/dev/null)
        echo "  ${NAME[$p]}"
    done
fi

# ---------- Glass Files ----------
if want files; then
    say "Glass Files"
    if ((DEFAULT_FM)); then
        (cd "$SRC/glass-files" && ./install.sh --default)
    else
        (cd "$SRC/glass-files" && ./install.sh)
    fi
fi

echo
echo "Done: ${CHOSEN[*]}"
if ((EXT)); then echo "Log out and back in: GNOME loads new extensions only at login (on Wayland)."; fi
if want theme; then echo "  tema-rengi turkuaz | yesil | mavi | mor | gri | cam   recolour the whole desktop"; fi
echo "  Add more parts later the same way; uninstall.sh [part...] takes them back out."
