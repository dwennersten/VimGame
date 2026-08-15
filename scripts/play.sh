#!/usr/bin/env sh
# Launch VimQuest in an isolated Neovim profile.
#
# NVIM_APPNAME=vimquest makes Neovim use its own config/data directories, so
# your real ~/.config/nvim configuration is never read or written.

set -e
repo="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v nvim >/dev/null 2>&1; then
  echo "Neovim not found on PATH. Install it first." >&2
  exit 1
fi

NVIM_APPNAME=vimquest exec nvim -u "$repo/init.lua"
