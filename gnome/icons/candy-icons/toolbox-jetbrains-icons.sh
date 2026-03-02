#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${HOME}/.local/share/applications"

# Find newest backup folder
latest="$(ls -1dt "${APP_DIR}"/.jb-bak-* 2>/dev/null | head -n 1 || true)"
if [[ -z "${latest}" ]]; then
  echo "No backup folder found in: ${APP_DIR} (expected .jb-bak-*)"
  exit 1
fi

shopt -s nullglob
bak_files=("${latest}"/jetbrains-*.desktop)
if ((${#bak_files[@]} == 0)); then
  echo "No jetbrains-*.desktop files in backup: ${latest}"
  exit 1
fi

cp -a "${bak_files[@]}" "${APP_DIR}/"
echo "Restored from: ${latest}"

update-desktop-database "${APP_DIR}" >/dev/null 2>&1 || true
rm -f "${HOME}/.cache/icon-cache.kcache" 2>/dev/null || true
rm -rf "${HOME}/.cache/gnome-shell" 2>/dev/null || true

echo "Rollback done. Log out/in if GNOME doesn't refresh immediately."
