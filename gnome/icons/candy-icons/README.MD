# Candy Icons (GNOME) — JetBrains Toolbox IDE Icons (Arch Linux)

## Goal
Force JetBrains IDE launchers installed via **JetBrains Toolbox** to use the **Candy** icon theme (`candy-icons-git`) in GNOME.

Toolbox creates `.desktop` files with **absolute icon paths** like:
Icon=/home/<user>/.local/share/JetBrains/Toolbox/apps/webstorm/bin/webstorm.svg

Absolute paths bypass GNOME theme lookup, so Candy is ignored.

Fix: replace `Icon=` with a **theme icon name**, e.g.:
Icon=webstorm
Icon=phpstorm
Icon=pycharm-professional
Icon=intellij-idea-ultimate

---

## Repo layout
arch-linux-notes/
  gnome/
    icons/
      candy-icons/
        README.md
        toolbox-jetbrains-icons.sh
        rollback-toolbox-jetbrains-icons.sh

---

## Prerequisites
- Arch Linux
- GNOME (Wayland or X11)
- JetBrains Toolbox + IDEs installed via Toolbox
- Candy icons installed: `candy-icons-git`

Install Candy (if needed):
yay -S candy-icons-git

Confirm Candy is installed system-wide:
pacman -Qo /usr/share/icons/candy-icons

Recommended: remove duplicate Candy installs from `$HOME` (if you previously copied it manually):
rm -rf ~/.local/share/icons/candy-icons ~/.icons/candy-icons

Set GNOME icon theme:
gsettings set org.gnome.desktop.interface icon-theme 'candy-icons'
gsettings get org.gnome.desktop.interface icon-theme

---

## Verify Candy contains JetBrains icons
ls /usr/share/icons/candy-icons/apps/scalable/{webstorm,phpstorm,pycharm-professional,intellij-idea-ultimate,jetbrains-toolbox}.svg

---

## Patch JetBrains Toolbox launchers
Toolbox launchers live here:
~/.local/share/applications/jetbrains-*.desktop

Run from this folder:
cd arch-linux-notes/gnome/icons/candy-icons
bash ./toolbox-jetbrains-icons.sh

What it does:
- Creates a backup inside:
  ~/.local/share/applications/.jb-bak-<timestamp>/
- Rewrites `Icon=` to Candy icon names when available
- Rebuilds desktop database and clears GNOME icon caches
- (Optionally) rebuilds Candy icon cache via `sudo gtk-update-icon-cache`

### Verify results
grep -H '^Icon=' ~/.local/share/applications/jetbrains-*.desktop

You should see:
Icon=webstorm
Icon=phpstorm
Icon=pycharm-professional
Icon=intellij-idea-ultimate
Icon=jetbrains-toolbox

---

## GNOME still shows old icons?
Do these (in order):
1) Log out / log in (Wayland often needs it)
2) If the app is pinned in the dock: **Unpin** it, then **Add to Favorites** again
3) Confirm no duplicates:
ls -1 ~/.local/share/applications | grep -E '^jetbrains-.*\.desktop$' | sort

---

## Rollback
cd arch-linux-notes/gnome/icons/candy-icons
bash ./rollback-toolbox-jetbrains-icons.sh

Restores the newest backup back into `~/.local/share/applications`.

---

## Note about Toolbox updates
JetBrains Toolbox may regenerate `.desktop` files during IDE updates and restore absolute icon paths.

If icons revert, re-run:
bash ./toolbox-jetbrains-icons.sh
