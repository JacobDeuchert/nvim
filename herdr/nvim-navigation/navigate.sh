#!/usr/bin/env bash
#
# herdr side of the Alt+neio nav. Vendored from vim-herdr-navigation (MIT).
#
# Invoked by a herdr keybind as: navigate.sh <focus|resize> <left|down|up|right>
#
# If the focused pane runs vim/nvim in the foreground, forward the chord into it
# (Alt+neio = focus, Alt+Ctrl+neio = resize) so smart-splits acts on splits
# and, at an edge, calls back into herdr — see lua/plugins/smart-splits.lua.
# Otherwise focus/resize the herdr pane directly.
# Needs `jq`; without it every press goes straight to herdr.

set -euo pipefail

op="${1:?usage: navigate.sh <focus|resize> <left|down|up|right>}"
dir="${2:?usage: navigate.sh <focus|resize> <left|down|up|right>}"
herdr="${HERDR_BIN_PATH:-herdr}"
pane="${HERDR_PANE_ID:-}"

case "$dir" in
  left)  letter="n" ;;
  down)  letter="e" ;;
  up)    letter="i" ;;
  right) letter="o" ;;
  *) echo "navigate.sh: unknown direction: $dir" >&2; exit 2 ;;
esac

case "$op" in
  focus)  key="alt+$letter" ;;
  resize) key="ctrl+alt+$letter" ;;
  *) echo "navigate.sh: unknown op: $op" >&2; exit 2 ;;
esac

# vim-tmux-navigator's matcher: vi, vim, nvim, view, gvim, *diff, ...
vim_re='^g?(view|l?n?vim?x?)(diff)?$'

forward=0
if [ -n "$pane" ] && command -v jq >/dev/null 2>&1; then
  if "$herdr" pane process-info --pane "$pane" 2>/dev/null \
    | jq -e --arg vim "$vim_re" \
        '.result.process_info.foreground_processes[]?.name
         | ascii_downcase
         | select(test($vim))' >/dev/null 2>&1; then
    forward=1
  fi
fi

if [ "$forward" -eq 1 ]; then
  exec "$herdr" pane send-keys "$pane" "$key"
elif [ -n "$pane" ]; then
  exec "$herdr" pane "$op" --direction "$dir" --pane "$pane"
else
  exec "$herdr" pane "$op" --direction "$dir" --current
fi
