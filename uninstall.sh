#!/bin/sh
# tb-heal uninstaller - removes what install.sh put down (best effort, both modes).
set -eu

removed=0
for f in /usr/local/bin/tb-heal "${HOME}/.local/bin/tb-heal" "${HOME}/bin/tb-heal"; do
  if [ -e "$f" ] && { [ "$(id -u)" = 0 ] || [ -w "$f" ]; }; then
    rm -f "$f"; echo "removed: $f"; removed=$((removed + 1))
  fi
done

if [ -e /etc/udev/rules.d/99-turtlebeach.rules ]; then
  if [ "$(id -u)" = 0 ]; then
    rm -f /etc/udev/rules.d/99-turtlebeach.rules
    udevadm control --reload 2>/dev/null || true
    echo "removed: /etc/udev/rules.d/99-turtlebeach.rules"
    removed=$((removed + 1))
  else
    echo "note: udev rule needs root: sudo ./uninstall.sh" >&2
  fi
fi

[ "$removed" -gt 0 ] || echo "nothing to remove"
