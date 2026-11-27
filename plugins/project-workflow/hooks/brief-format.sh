#!/usr/bin/env bash
# Optional Claude Code extra: states the brief format for this session so /pw-brief can pick markdown in a
# terminal and HTML elsewhere. The skill works without it. Reads environment variables only.
# Entrypoints: the terminal sets CLAUDE_CODE_ENTRYPOINT=cli; the desktop app, IDE extension and SDK set other
# values; Claude Code on the web sets CLAUDE_CODE_REMOTE=true (its entrypoint may still be cli).
set -u

if [ -n "${TMUX:-}" ] || { [ "${CLAUDE_CODE_ENTRYPOINT:-}" = "cli" ] && [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; }; then
  echo "project-workflow brief format: md"
else
  echo "project-workflow brief format: html"
fi
exit 0
