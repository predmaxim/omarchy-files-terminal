#!/bin/bash
# Test, then link open-terminal.py into the Files (nautilus-python) extensions folder.
# A link, so `git pull` upgrades it; Files loads extensions at startup, so restart it after.
set -euo pipefail
cd "$(dirname "$0")"

./test.sh >/dev/null
extensions="$HOME/.local/share/nautilus-python/extensions"
mkdir -p "$extensions"
ln -sfn "$PWD/open-terminal.py" "$extensions/open-terminal.py"
echo "Installed. Close all Files windows (or run nautilus -q) to load it."
