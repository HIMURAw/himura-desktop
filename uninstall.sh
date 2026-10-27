#!/usr/bin/env bash
# Takes himura-desktop back out: extensions off and removed, GNOME's own theme, icons and
# file manager back, your own ~/.config/gtk-4.0/gtk.css restored. Distro packages and the
# themes it builds on (adw-gtk3, Orchis, Papirus) stay; the sources in ~/.local/src stay
# unless you pass --purge.
set -uo pipefail

SRC="${HIMURA_SRC:-$HOME/.local/src}"
PURGE=0
[[ "${1:-}" == --purge ]] && PURGE=1

for uuid in dynamic-island@himuraw glass-dock@himuraw glass-windows@himuraw glass-widgets@himuraw away-lock@himuraw; do
    gnome-extensions disable "$uuid" 2>/dev/null
    enabled=$(gsettings get org.gnome.shell enabled-extensions)
    gsettings set org.gnome.shell enabled-extensions "$(sed "s/, *'$uuid'//; s/'$uuid', *//; s/'$uuid'//" <<<"$enabled")"
    dest="$HOME/.local/share/gnome-shell/extensions/$uuid"
    [[ -L "$dest" ]] && rm "$dest"
done
rm -f "$HOME/.local/bin/dynada" "$HOME/.local/bin/tema-rengi"

[[ -x "$SRC/glass-files/install.sh" ]] && (cd "$SRC/glass-files" && ./install.sh --undo-default >/dev/null)
rm -f "$HOME/.local/bin/glass-files" "$HOME/.local/share/applications/io.github.himuraw.GlassFiles.desktop"

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
rm -rf "$HOME/.config/tema"

if ((PURGE)); then
    rm -rf "$SRC"/{mor-theme,mor-icons,glass-files,gnome-dynamic-island,gnome-glass-dock,glass-windows,gnome-glass-widgets,gnome-away-lock}
fi
echo "Removed. Log out and back in to finish."
