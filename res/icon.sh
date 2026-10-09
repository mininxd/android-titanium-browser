#!/bin/bash
TARGET="$1"
SCRIPT_DIR=$(dirname "$0")
ICON="$SCRIPT_DIR/icon.png"
[ ! -f "$ICON" ] && ICON="$SCRIPT_DIR/../icon.png"

python3 -c '
import sys
from PIL import Image

src_path = sys.argv[1]
target_path = sys.argv[2]
src = Image.open(src_path).convert("RGBA")

try:
    w, h = Image.open(target_path).size
except Exception:
    w, h = 512, 512

resized = src.resize((w, h), Image.Resampling.LANCZOS)
resized.save(target_path)
print(f"Resized {src_path} -> {target_path} ({w}x{h})")
' "$ICON" "$TARGET"
