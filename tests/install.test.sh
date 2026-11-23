#!/usr/bin/env bash
# bin/install against a temporary HOME. The real home is never written.
set -u

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
clone="$(cd -P "$here/.." && pwd -P)"
install="$clone/bin/install"
skills="$clone/plugins/project-workflow/skills"
expected=$(find "$skills" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')

bad=0
ok() { echo "ok - $1"; }
not_ok() { echo "not ok - $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/    /'; bad=$((bad + 1)); }
check() { if [ "$2" = "$3" ]; then ok "$1"; else not_ok "$1" "expected: $3 / got: $2"; fi; }
links_into_clone() { # <dir>: count links that resolve to a skill folder in this clone
  local n=0 l
  for l in "$1"/*; do
    [ -L "$l" ] && [ "$(readlink "$l")" = "$skills/$(basename "$l")" ] && n=$((n + 1))
  done
  echo "$n"
}
case "$(uname -s)" in MINGW* | MSYS* | CYGWIN*) windows=1 ;; *) windows=0 ;; esac
foreign_link() { # <src> <link>: a link bin/install did not make (Git Bash's ln -s would copy)
  if [ "$windows" -eq 1 ]; then
    MSYS2_ARG_CONV_EXCL="*" cmd /c mklink /J "$(cygpath -w "$2")" "$(cygpath -w "$1")" >/dev/null
  else
    ln -s "$1" "$2"
  fi
}
homes=()
new_home() { HOME=$(mktemp -d); export HOME; homes+=("$HOME"); }
trap 'rm -rf "${homes[@]}"' EXIT

# default target
new_home
out=$("$install" project-workflow 2>&1); rc=$?
check "default install exits zero" "$rc" 0
check "default install links every skill into ~/.agents/skills" "$(links_into_clone "$HOME/.agents/skills")" "$expected"
[ -e "$HOME/.claude" ] && not_ok "default install leaves ~/.claude alone" || ok "default install leaves ~/.claude alone"

# the rules doc is reachable two levels above the resolved skill folder
real=$(cd -P "$HOME/.agents/skills/pw-open" && pwd -P)
[ -f "$real/../../docs/project-workflow.md" ] && ok "rules doc is reachable through an installed link" || not_ok "rules doc is reachable through an installed link" "$real"

# idempotent
out=$("$install" project-workflow 2>&1); rc=$?
check "second run exits zero" "$rc" 0
check "second run reports links as present" "$(printf '%s\n' "$out" | grep -c '^present ')" "$expected"

# uninstall leaves unrelated skills alone
mkdir -p "$HOME/.agents/skills/someone-elses-skill"
out=$("$install" project-workflow --uninstall 2>&1); rc=$?
check "uninstall exits zero" "$rc" 0
check "uninstall removes every link" "$(links_into_clone "$HOME/.agents/skills")" 0
[ -d "$HOME/.agents/skills/someone-elses-skill" ] && ok "uninstall leaves an unrelated skill alone" || not_ok "uninstall leaves an unrelated skill alone"

# --agent claude
new_home
"$install" project-workflow --agent claude >/dev/null 2>&1
check "--agent claude links into ~/.claude/skills" "$(links_into_clone "$HOME/.claude/skills")" "$expected"
[ -e "$HOME/.agents" ] && not_ok "--agent claude links nowhere else" || ok "--agent claude links nowhere else"

# --dir
new_home
"$install" project-workflow --dir "$HOME/custom/skills" >/dev/null 2>&1
check "--dir links into that path" "$(links_into_clone "$HOME/custom/skills")" "$expected"

# a real folder is never replaced
new_home
mkdir -p "$HOME/.agents/skills/pw-open"
echo mine > "$HOME/.agents/skills/pw-open/SKILL.md"
out=$("$install" project-workflow 2>&1); rc=$?
check "a real folder in the way makes the run exit non-zero" "$rc" 1
check "a real folder in the way is left untouched" "$(cat "$HOME/.agents/skills/pw-open/SKILL.md")" mine
printf '%s\n' "$out" | grep -q "refused  $HOME/.agents/skills/pw-open" && ok "a real folder in the way is reported" || not_ok "a real folder in the way is reported" "$out"

# a foreign link is never replaced
new_home
mkdir -p "$HOME/.agents/skills" "$HOME/elsewhere"
foreign_link "$HOME/elsewhere" "$HOME/.agents/skills/pw-open"
out=$("$install" project-workflow 2>&1); rc=$?
check "a foreign link makes the run exit non-zero" "$rc" 1
check "a foreign link is left untouched" "$(readlink "$HOME/.agents/skills/pw-open")" "$HOME/elsewhere"
out=$("$install" project-workflow --uninstall 2>&1)
check "uninstall does not remove a foreign link" "$(readlink "$HOME/.agents/skills/pw-open")" "$HOME/elsewhere"

# a link that cannot be made stops the run; nothing is copied in its place
new_home
mkdir -p "$HOME/fakebin"
for tool in ln cmd; do printf '#!/bin/sh\nexit 1\n' > "$HOME/fakebin/$tool"; chmod +x "$HOME/fakebin/$tool"; done
out=$(PATH="$HOME/fakebin:$PATH" "$install" project-workflow 2>&1); rc=$?
check "a failed link exits non-zero" "$rc" 1
printf '%s\n' "$out" | grep -q '^error: could not link ' && ok "a failed link is reported" || not_ok "a failed link is reported" "$out"
check "a failed link leaves nothing in its place" "$(find "$HOME/.agents/skills" -mindepth 1 | wc -l | tr -d ' ')" 0

# on Windows Git Bash the links are directory junctions
if [ "$windows" -eq 1 ]; then
  new_home
  "$install" project-workflow >/dev/null 2>&1
  check "Git Bash install makes a junction per skill" \
    "$(cmd //c dir "$(cygpath -w "$HOME/.agents/skills")" | grep -c '<JUNCTION>')" "$expected"
  "$install" project-workflow --uninstall >/dev/null 2>&1
  check "Git Bash uninstall leaves the skill folders intact" \
    "$(find "$skills" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')" "$expected"
else
  echo "ok - # skip junction checks (not Windows Git Bash)"
fi

# no plugin named
new_home
out=$("$install" 2>&1); rc=$?
check "no plugin argument exits non-zero" "$rc" 1
printf '%s\n' "$out" | grep -q '^  project-workflow$' && ok "no plugin argument lists the plugins" || not_ok "no plugin argument lists the plugins" "$out"
check "no plugin argument creates nothing" "$(find "$HOME" -mindepth 1 | wc -l | tr -d ' ')" 0

# unknown plugin, unknown agent
out=$("$install" no-such-plugin 2>&1); rc=$?
check "an unknown plugin exits non-zero" "$rc" 1
check "an unknown plugin creates nothing" "$(find "$HOME" -mindepth 1 | wc -l | tr -d ' ')" 0
out=$("$install" project-workflow --agent no-such-agent 2>&1); rc=$?
check "an unknown agent exits non-zero" "$rc" 2
check "an unknown agent creates nothing" "$(find "$HOME" -mindepth 1 | wc -l | tr -d ' ')" 0

[ "$bad" -eq 0 ]
