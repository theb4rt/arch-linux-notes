# arch-linux-notes/gnome/icons/candy-icons/toolbox-jetbrains-icons.sh
#!/usr/bin/env bash
set -euo pipefail

THEME_DIR="/usr/share/icons/candy-icons/apps/scalable"
APP_DIR="${HOME}/.local/share/applications"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${APP_DIR}/.jb-bak-${TS}"

mkdir -p "$BACKUP_DIR"

shopt -s nullglob

# Backup only JetBrains launchers (Toolbox-generated)
files=("${APP_DIR}"/jetbrains-*.desktop)
if ((${#files[@]} == 0)); then
  echo "No JetBrains .desktop files found in: $APP_DIR"
  exit 0
fi

cp -a "${files[@]}" "$BACKUP_DIR/"
echo "Backup created: $BACKUP_DIR"

# Map desktop file -> Candy icon name
pick_icon() {
  local base name lower icon=""
  base="$(basename "$1")"
  name="$(grep -m1 '^Name=' "$1" | cut -d= -f2- || true)"
  lower="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"

  case "$lower" in
    *"intellij"*"ultimate"*)   icon="intellij-idea-ultimate" ;;
    *"intellij"*"community"*)  icon="intellij-idea-community" ;;
    *"intellij"*"idea"*)       icon="intellij" ;; # fallback
    *"webstorm"*)              icon="webstorm" ;;
    *"phpstorm"*)              icon="phpstorm" ;;
    *"pycharm"*"professional"*)icon="pycharm-professional" ;;
    *"pycharm"*"community"*)   icon="pycharm-community" ;;
    *"goland"*)                icon="goland" ;;
    *"clion"*)                 icon="clion" ;;
    *"datagrip"*)              icon="datagrip" ;;
    *"rider"*)                 icon="rider" ;;
    *"rubymine"*)              icon="rubymine" ;;
    *"dataspell"*)             icon="dataspell" ;;
    *"rustrover"*)             icon="rustrover" ;;
    *"fleet"*)                 icon="fleet" ;;
    *"toolbox"*)               icon="jetbrains-toolbox" ;;
    *)                         icon="" ;;
  esac

  # If Name= parsing failed or ambiguous, fallback by filename
  if [[ -z "$icon" ]]; then
    case "$base" in
      jetbrains-webstorm-*.desktop) icon="webstorm" ;;
      jetbrains-phpstorm-*.desktop) icon="phpstorm" ;;
      jetbrains-pycharm-*.desktop) icon="pycharm-professional" ;;
      jetbrains-idea-*.desktop) icon="intellij-idea-ultimate" ;;
      jetbrains-toolbox.desktop) icon="jetbrains-toolbox" ;;
      *) icon="" ;;
    esac
  fi

  # Ensure icon exists in Candy
  if [[ -n "$icon" && -f "${THEME_DIR}/${icon}.svg" ]]; then
    printf '%s' "$icon"
  else
    printf ''
  fi
}

patched=0
missed=0

for f in "${files[@]}"; do
  icon="$(pick_icon "$f")"
  name="$(grep -m1 '^Name=' "$f" | cut -d= -f2- || true)"

  if [[ -n "$icon" ]]; then
    # Replace or add Icon=
    if grep -q '^Icon=' "$f"; then
      sed -i "s|^Icon=.*|Icon=${icon}|" "$f"
    else
      printf '\nIcon=%s\n' "$icon" >> "$f"
    fi
    echo "OK: $(basename "$f") -> Icon=${icon} (Name: ${name})"
    ((patched++))
  else
    echo "MISS: $(basename "$f") (Name: ${name}) - no matching Candy icon found"
    ((missed++))
  fi
done

# Refresh .desktop cache
update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true

# Clear GNOME caches (zsh-safe)
rm -f "${HOME}/.cache/icon-cache.kcache" 2>/dev/null || true
rm -rf "${HOME}/.cache/gnome-shell" 2>/dev/null || true

# Rebuild icon cache for Candy theme (requires sudo)
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  if sudo -n true 2>/dev/null; then
    sudo gtk-update-icon-cache -f /usr/share/icons/candy-icons >/dev/null 2>&1 || true
  else
    echo "NOTE: Run this once to rebuild Candy icon cache:"
    echo "  sudo gtk-update-icon-cache -f /usr/share/icons/candy-icons"
  fi
fi

echo "Done. Patched: ${patched}, Missed: ${missed}"
echo "If icons still look old: log out/in, then unpin + repin dock favorites."
