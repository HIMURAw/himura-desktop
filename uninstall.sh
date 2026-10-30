#!/usr/bin/env bash
# Takes himura-desktop back out, all of it or only some parts:
#
#   ./uninstall.sh                  everything
#   ./uninstall.sh dock widgets     only these parts (island dock widgets windows files theme away-lock)
#   ./uninstall.sh --purge [...]    also delete their sources in ~/.local/src
#
# Extensions are turned off and removed; theme brings back GNOME's own theme, icons and your
# own ~/.config/gtk-4.0/gtk.css; files gives folders back to Nautilus. Distro packages and the
# themes it builds on (adw-gtk3, Orchis, Papirus) stay.
set -uo pipefail

SRC="${HIMURA_SRC:-$HOME/.local/src}"
PARTS=(island dock widgets windows files theme away-lock)
declare -A UUID=(
    [island]=dynamic-island@himuraw [dock]=glass-dock@himuraw [widgets]=glass-widgets@himuraw
    [windows]=glass-windows@himuraw [away-lock]=away-lock@himuraw
)
declare -A SOURCES=(
    [island]=gnome-dynamic-island [dock]=gnome-glass-dock [widgets]=gnome-glass-widgets
    [windows]=glass-windows [files]=glass-files [theme]="mor-theme mor-icons" [away-lock]=gnome-away-lock
)

PURGE=0
declare -A WANT=()
for arg in "$@"; do
    case "$arg" in
    --purge) PURGE=1 ;;
    -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)
        if [[ -n "${SOURCES[$arg]+x}" ]]; then WANT[$arg]=1
        else echo "Unknown part: $arg (parts: ${PARTS[*]})" >&2; exit 1
        fi ;;
    esac
done
if ((${#WANT[@]} == 0)); then for p in "${PARTS[@]}"; do WANT[$p]=1; done; fi
want() { [[ -n "${WANT[$1]:-}" ]]; }

for p in island dock widgets windows away-lock; do
    want $p || continue
    uuid=${UUID[$p]}
    gnome-extensions disable "$uuid" 2>/dev/null
    enabled=$(gsettings get org.gnome.shell enabled-extensions)
    gsettings set org.gnome.shell enabled-extensions "$(sed "s/, *'$uuid'//; s/'$uuid', *//; s/'$uuid'//" <<<"$enabled")"
    dest="$HOME/.local/share/gnome-shell/extensions/$uuid"
    [[ -L "$dest" ]] && rm "$dest"
    echo "  removed $p"
done
want island && rm -f "$HOME/.local/bin/dynada"

if want files; then
    [[ -x "$SRC/glass-files/install.sh" ]] && (cd "$SRC/glass-files" && ./install.sh --undo-default >/dev/null)
    rm -f "$HOME/.local/bin/glass-files" "$HOME/.local/share/applications/io.github.himuraw.GlassFiles.desktop"
    echo "  removed files"
fi

if want theme; then
    rm -f "$HOME/.local/bin/tema-rengi"
    gsettings reset org.gnome.desktop.interface gtk-theme
    gsettings reset org.gnome.desktop.interface icon-theme
    gsettings reset org.gnome.desktop.interface accent-color
    gsettings reset org.gnome.shell.extensions.user-theme name 2>/dev/null
    rm -rf "$HOME/.themes/Mor" "$HOME/.local/share/icons/Mor" "$HOME/.local/share/icons/Mor-Base"
    gtk4="$HOME/.config/gtk-4.0/gtk.css"
    if [[ -f "$gtk4.before-himura" ]]; then
        mv "$gtk4.before-himura" "$gtk4"
    elif grep -q "mor-theme" "$gtk4" 2>/dev/null; then
        rm "$gtk4"
    fi
    # The extensions follow ~/.config/tema too; without it they go back to their own violet.
    rm -rf "$HOME/.config/tema"
    echo "  removed theme"
fi

if ((PURGE)); then
    for p in "${PARTS[@]}"; do
        want "$p" || continue
        for repo in ${SOURCES[$p]}; do rm -rf "${SRC:?}/$repo"; done
    done
fi
echo "Done. Log out and back in to finish."
