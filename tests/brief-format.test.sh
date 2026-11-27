#!/usr/bin/env bash
# The optional session-start hook that states the brief format, run through its real entry point with a
# clean environment so nothing ambient leaks in.
set -u

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
clone="$(cd -P "$here/.." && pwd -P)"
plugin="$clone/plugins/project-workflow"
script="$plugin/hooks/brief-format.sh"
hooks="$plugin/hooks/hooks.json"

bad=0
ok() { echo "ok - $1"; }
not_ok() { echo "not ok - $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/    /'; bad=$((bad + 1)); }
check() { if [ "$2" = "$3" ]; then ok "$1"; else not_ok "$1" "expected: $3 / got: $2"; fi; }

run() { env -i PATH="$PATH" "$@" bash "$script" 2>/dev/null; }
md="project-workflow brief format: md"
html="project-workflow brief format: html"

check "terminal entrypoint gives md" "$(run CLAUDE_CODE_ENTRYPOINT=cli)" "$md"
check "terminal entrypoint on the web gives html" "$(run CLAUDE_CODE_ENTRYPOINT=cli CLAUDE_CODE_REMOTE=true)" "$html"
check "desktop entrypoint gives html" "$(run CLAUDE_CODE_ENTRYPOINT=claude-desktop)" "$html"
check "IDE entrypoint gives html" "$(run CLAUDE_CODE_ENTRYPOINT=claude-vscode)" "$html"
check "no entrypoint gives html" "$(run)" "$html"
check "tmux with desktop entrypoint gives md" "$(run TMUX=/tmp/tmux-1/default,1,0 CLAUDE_CODE_ENTRYPOINT=claude-desktop)" "$md"

err="$(env -i PATH="$PATH" CLAUDE_CODE_ENTRYPOINT=cli bash "$script" 2>&1 >/dev/null)"
out="$(env -i PATH="$PATH" CLAUDE_CODE_ENTRYPOINT=cli bash "$script" 2>/dev/null)"; rc=$?
check "exits 0" "$rc" "0"
check "prints exactly one line" "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" "1"
check "writes nothing to stderr" "$err" ""

if python3 - "$hooks" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
cmds = [h["command"] for g in d["hooks"]["SessionStart"] for h in g["hooks"] if h.get("type") == "command"]
sys.exit(0 if any("hooks/brief-format.sh" in c for c in cmds) else 1)
PY
then ok "hooks.json registers SessionStart running hooks/brief-format.sh"
else not_ok "hooks.json registers SessionStart running hooks/brief-format.sh"; fi
if [ -x "$script" ]; then ok "brief-format.sh is executable"; else not_ok "brief-format.sh is executable"; fi

[ "$bad" -eq 0 ]
