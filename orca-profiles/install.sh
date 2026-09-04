#!/usr/bin/env bash
# Install the Northworks 600x OrcaSlicer profiles.
#
#   ./install.sh            auto-detect the OrcaSlicer config dir and install
#   ./install.sh --dir DIR  install into a specific ".../user/<id>" directory
#   ./install.sh --force    overwrite existing files of the same name
#
# Nothing is overwritten unless --force is given. Restart OrcaSlicer afterwards
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORCE=0
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)   TARGET="${2:?--dir needs a path}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

# Candidate OrcaSlicer data directories, most specific first.
CANDIDATES=(
  "$HOME/.var/app/com.orcaslicer.OrcaSlicer/config/OrcaSlicer"   # Linux, Flatpak
  "$HOME/.config/OrcaSlicer"                                     # Linux, AppImage / native
  "$HOME/Library/Application Support/OrcaSlicer"                 # macOS
)

found=()
if [[ -n "$TARGET" ]]; then
  found+=("$TARGET")
else
  for c in "${CANDIDATES[@]}"; do
    [[ -d "$c/user" ]] || continue
    # 'default' when logged out; otherwise a user-id folder. Prefer ones that already look real.
    for u in "$c"/user/*/; do
      [[ -d "$u" ]] || continue
      found+=("${u%/}")
    done
  done
fi

if [[ ${#found[@]} -eq 0 ]]; then
  cat >&2 <<EOF
ERROR: no OrcaSlicer profile directory found.

Looked in:
$(printf '  %s/user/*\n' "${CANDIDATES[@]}")

Run OrcaSlicer once so it creates its config, or pass the path explicitly:
  ./install.sh --dir ~/.config/OrcaSlicer/user/default
On Windows, copy machine/ process/ filament/ into
  %APPDATA%\\OrcaSlicer\\user\\default\\
EOF
  exit 1
fi

echo "Installing Northworks 600x profiles from: $SRC"
echo

installed=0 skipped=0
for dest in "${found[@]}"; do
  echo "→ $dest"
  for kind in machine process filament; do
    mkdir -p "$dest/$kind"
    shopt -s nullglob
    for f in "$SRC/$kind"/*.json; do
      base="$(basename "$f")"
      if [[ -e "$dest/$kind/$base" && $FORCE -eq 0 ]]; then
        echo "    skip (exists): $kind/$base"; skipped=$((skipped+1))
      else
        cp "$f" "$dest/$kind/$base"
        echo "    ok:            $kind/$base"; installed=$((installed+1))
      fi
    done
    shopt -u nullglob
  done
done

echo
echo "installed $installed, skipped $skipped"
[[ $skipped -gt 0 ]] && echo "(re-run with --force to overwrite the skipped files)"

cat <<'EOF'

NEXT STEPS
  1. Restart OrcaSlicer
EOF
