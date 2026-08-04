#!/bin/zsh
set -euo pipefail

ROOT="/Users/youer/Downloads/telegram-discovery 3/kislap-ios"
ASSETS="$ROOT/app-store/1.1"
SRC="$ASSETS/source"
IPHONE="$ASSETS/en-US/iphone-6.9"
IPAD="$ASSETS/en-US/ipad-13"

mkdir -p "$SRC" "$IPHONE" "$IPAD"
if [[ -f /tmp/kislap-1.1-learning-hub.png ]]; then
  cp /tmp/kislap-1.1-learning-hub.png "$SRC/iphone-6.3.png"
fi
if [[ -f /tmp/kislap-1.1-learning-hub-ipad-v2.png ]]; then
  cp /tmp/kislap-1.1-learning-hub-ipad-v2.png "$SRC/ipad-13.png"
fi

[[ -f "$SRC/iphone-6.3.png" ]] || { echo "Missing source/iphone-6.3.png" >&2; exit 1; }
[[ -f "$SRC/ipad-13.png" ]] || { echo "Missing source/ipad-13.png" >&2; exit 1; }

if ! PYTHONPATH=/tmp/kislap-pillow python3 -c 'import PIL' >/dev/null 2>&1; then
  echo "Pillow is required. Install it into /tmp/kislap-pillow first." >&2
  exit 1
fi

PYTHONPATH=/tmp/kislap-pillow python3 "$ASSETS/generate_kislap_store_assets.py"

printf 'Generated App Store screenshot suite in %s\n' "$ASSETS"
