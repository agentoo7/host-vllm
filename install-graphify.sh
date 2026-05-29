#!/usr/bin/env sh
# Install graphify on macOS / Linux.
# Usage:  curl -LsSf https://.../install-graphify.sh | sh
#         ./install-graphify.sh
set -eu

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m!! \033[0m %s\n' "$*" >&2; }

# 1. uv (the installer for the Python package)
if ! command -v uv >/dev/null 2>&1; then
  say "uv not found, installing from astral.sh..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  # uv installs to ~/.local/bin by default
  export PATH="$HOME/.local/bin:$PATH"
fi

if ! command -v uv >/dev/null 2>&1; then
  err "uv install failed. Add \$HOME/.local/bin to PATH and re-run."
  exit 1
fi

# 2. graphifyy (PyPI name) -> provides the `graphify` CLI
if uv tool list 2>/dev/null | grep -q '^graphifyy '; then
  say "graphifyy already installed, upgrading..."
  uv tool upgrade graphifyy
else
  say "Installing graphifyy..."
  uv tool install graphifyy
fi

# # 3. Install the Claude Code skill (copies SKILL.md to ~/.claude/skills/graphify/)
# say "Installing skill into Claude Code..."
# graphify install --platform claude

# say "Done. Restart Claude Code, then try:  /graphify --help"
