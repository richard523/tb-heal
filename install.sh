#!/bin/sh
# tb-heal installer - Linux (status + self-heal + udev access) and macOS (status).
# Windows: see install.ps1.
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MODE=${1:-system}

case $(uname -s) in
  Linux)  OS=linux ;;
  Darwin) OS=macos ;;
  *) echo "unsupported OS: $(uname -s) - Windows users: see install.ps1"; exit 1 ;;
esac

if [ "$MODE" = "--user" ]; then
  if [ "$OS" = linux ]; then BIN_DIR=${HOME}/.local/bin; else BIN_DIR=${HOME}/bin; fi
  mkdir -p "$BIN_DIR"
  install -m 0755 "$SCRIPT_DIR/tb-heal" "$BIN_DIR/tb-heal"
  echo "installed: $BIN_DIR/tb-heal"
  if [ "$OS" = linux ] && [ "$(id -u)" != 0 ]; then
    echo "note: --user mode does not install the udev rule; for the status query"
    echo "      without sudo, also run once: sudo ./install.sh"
  fi
  exit 0
fi

if [ "$MODE" != "system" ]; then
  echo "usage: [sudo] ./install.sh [system|--user]" >&2
  exit 1
fi

if [ "$(id -u)" != 0 ]; then
  echo "system install needs root: sudo ./install.sh" >&2
  exit 1
fi

install -m 0755 "$SCRIPT_DIR/tb-heal" /usr/local/bin/tb-heal
echo "installed: /usr/local/bin/tb-heal"

if [ "$OS" = linux ]; then
  install -m 0644 "$SCRIPT_DIR/udev/99-turtlebeach.rules" /etc/udev/rules.d/99-turtlebeach.rules
  udevadm control --reload
  # re-trigger every 10f5 device so permissions apply without a replug
  found=0
  for vfile in /sys/bus/usb/devices/*/idVendor; do
    if [ "$(cat "$vfile")" = "10f5" ]; then
      udevadm trigger --action=add "$(dirname "$vfile")"
      found=$((found + 1))
    fi
  done
  echo "udev rule installed + re-triggered ($found Turtle Beach device(s))"
else
  echo "macOS: no udev rule needed - make sure `brew install hidapi` if the"
  echo "       status query reports a missing hidapi library"
fi
echo "done. try: tb-heal"
