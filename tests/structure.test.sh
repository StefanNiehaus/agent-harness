#!/usr/bin/env bash
# Structural test for every plugin in a repo root.
#
#   structure.test.sh                 self-test against tests/fixtures/, then check this repo
#   structure.test.sh --check <root>  check one root; print "FAIL <file>:<line>: <reason>" lines
#
# Checks: portable skill frontmatter, no agent-specific tool names, no tracker-specific terms outside
# tracker sheets, op coverage in every tracker sheet, relative paths that resolve, unique skill names,
# manifests that parse, and no personal or employer values anywhere in the root.
set -u

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ALLOWED_KEYS=" name description license compatibility metadata allowed-tools "
AGENT_SPECIFIC='mcp__|CLAUDE_PLUGIN_ROOT|CLAUDE_SKILL_DIR|__PLUGIN_ROOT__|AskUserQuestion|TodoWrite|SessionStart|UserPromptSubmit|SubagentStart'
TRACKER_SPECIFIC='(^|[^a-z])gh (issue|api|label)([^a-z]|$)|(^|[^a-z])jql([^a-z]|$)|jira|cloud ?id|atlassian'
EMAIL='[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}'
EMAIL_OK='@example\.(com|org)$|noreply|^git@'
UUID='[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'

fails=0
fail() { # fail <path relative to root> <line or -> <reason>
  fails=$((fails + 1))
  if [ "$2" = "-" ]; then echo "FAIL $1: $3"; else echo "FAIL $1:$2: $3"; fi
}

# grep_lines <regex> <grep flags> <file>: print "line<TAB>text" for each match
grep_lines() { grep -nIE $2 -- "$1" "$3" 2>/dev/null | sed 's/:/\t/'; }

# A doc that must name trackers (config examples, the adding-a-tracker guide) opts out of the
# tracker-neutral check with this marker in its first five lines.
is_tracker_specific_doc() { head -n 5 "$1" | grep -q '<!-- tracker-specific -->'; }

check_frontmatter() { # <root> <SKILL.md>
  local root=$1 file=$2 rel=${2#"$1"/} dir name key n=0 in=0
  dir=$(basename "$(dirname "$file")")
  name=""
  while IFS= read -r line; do
    n=$((n + 1))
    if [ "$line" = "---" ]; then
      [ "$in" -eq 1 ] && break
      in=1
      continue
    fi
    [ "$in" -eq 1 ] || { fail "$rel" 1 "SKILL.md must start with frontmatter"; return; }
    case "$line" in
      [A-Za-z]*:*)
        key=${line%%:*}
        case "$ALLOWED_KEYS" in
          *" $key "*) ;;
          *) fail "$rel" "$n" "frontmatter key \`$key\` is not in the open Agent Skills spec" ;;
        esac
        if [ "$key" = "name" ]; then
          name=$(printf '%s' "${line#name:}" | sed 's/^ *//; s/ *$//')
          [ "$name" = "$dir" ] || fail "$rel" "$n" "skill name \`$name\` does not match its folder \`$dir\`"
        fi
        ;;
    esac
  done < "$file"
  [ -n "$name" ] || fail "$rel" 1 "frontmatter has no name"
}

check_relative_paths() { # <root> <SKILL.md>
  local root=$1 file=$2 rel=${2#"$1"/} dir ref n
  dir=$(dirname "$file")
  while IFS=$'\t' read -r n ref; do
    ref=${ref%.}
    ref=${ref%/}
    [ -e "$dir/$ref" ] || fail "$rel" "$n" "relative path \`$ref\` does not resolve"
  done < <(grep -nIoE '\.\./\.\./[A-Za-z0-9_./-]+' "$file" | sed 's/:/\t/')
}

check_banned() { # <root> <file> <regex> <grep flags> <reason>
  local root=$1 file=$2 rel=${2#"$1"/} n text
  while IFS=$'\t' read -r n text; do
    fail "$rel" "$n" "$5: $(printf '%s' "$text" | grep -oE $4 -- "$3" | head -n 1)"
  done < <(grep_lines "$3" "$4" "$file")
}

check_ops() { # <root> <plugin dir>
  local root=$1 plugin=$2 contract=$2/trackers/contract.md sheet op
  [ -f "$contract" ] || return 0
  for sheet in "$plugin"/trackers/*.md; do
    [ "$sheet" = "$contract" ] && continue
    while IFS= read -r op; do
      grep -qF "## \`$op\`" "$sheet" || fail "${sheet#"$root"/}" - "missing op \`$op\`"
    done < <(sed -n 's/^## `\([a-z-]*\)`.*/\1/p' "$contract")
  done
}

check_manifests() { # <root>
  local root=$1
  python3 - "$root" <<'PY'
import json, os, sys
root = sys.argv[1]
def load(path):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception as e:  # missing or malformed
        print(f"FAIL {os.path.relpath(path, root)}: does not parse as JSON ({e.__class__.__name__})")
        return None
market = load(os.path.join(root, ".claude-plugin", "marketplace.json"))
plugins_dir = os.path.join(root, "plugins")
dirs = sorted(d for d in os.listdir(plugins_dir) if os.path.isdir(os.path.join(plugins_dir, d))) if os.path.isdir(plugins_dir) else []
for d in dirs:
    path = os.path.join(plugins_dir, d, ".claude-plugin", "plugin.json")
    data = load(path)
    if data is not None and data.get("name") != d:
        print(f"FAIL {os.path.relpath(path, root)}: name does not match the plugin folder `{d}`")
if market is not None:
    if not market.get("name"):
        print("FAIL .claude-plugin/marketplace.json: has no name")
    listed = [p.get("name") for p in market.get("plugins", [])]
    for d in dirs:
        if listed.count(d) != 1:
            print(f"FAIL .claude-plugin/marketplace.json: plugin `{d}` is listed {listed.count(d)} times, expected once")
    for name in listed:
        if name not in dirs:
            print(f"FAIL .claude-plugin/marketplace.json: lists `{name}`, which has no folder under plugins/")
PY
}

list_text_files() { # <root>: every file to scan for personal values, relative to root
  local root=$1
  if [ "$(git -C "$root" rev-parse --show-toplevel 2>/dev/null)" = "$(cd "$root" && pwd -P)" ]; then
    # The fixtures hold the banned shapes on purpose.
    git -C "$root" ls-files -co --exclude-standard | grep -v '^tests/fixtures/'
  else
    (cd "$root" && find . -type f -not -name expect | sed 's#^\./##')
  fi
}

check_personal_values() { # <root>
  local root=$1 denylist=${PW_DENYLIST_FILE:-$1/.denylist.local} rel file n text pattern
  while IFS= read -r rel; do
    file=$root/$rel
    [ -f "$file" ] || continue
    while IFS=$'\t' read -r n text; do
      if printf '%s\n' "$text" | grep -oE "$EMAIL" | grep -qvE "$EMAIL_OK"; then
        fail "$rel" "$n" "email address outside example and noreply hosts"
      fi
    done < <(grep_lines "$EMAIL" "" "$file")
    while IFS=$'\t' read -r n text; do
      fail "$rel" "$n" "tracker site host (use example.atlassian.net)"
    done < <(grep_lines '[A-Za-z0-9-]+\.atlassian\.net' "" "$file" | grep -vE '(^|[^A-Za-z0-9-])example\.atlassian\.net')
    while IFS=$'\t' read -r n text; do
      fail "$rel" "$n" "cloud id value"
    done < <(grep_lines "$UUID" "" "$file" | grep -iE 'cloud.?id')
    if [ -f "$denylist" ]; then
      while IFS= read -r pattern; do
        case "$pattern" in "" | \#*) continue ;; esac
        while IFS=$'\t' read -r n text; do
          fail "$rel" "$n" "denylisted string"
        done < <(grep -nIiF -- "$pattern" "$file" 2>/dev/null | sed 's/:/\t/')
      done < "$denylist"
    fi
  done < <(list_text_files "$root")
}

check_root() { # <root>
  local root=${1%/} plugin skill file names dup
  fails=0
  [ -d "$root/plugins" ] || fail plugins - "no plugins/ directory"
  for plugin in "$root"/plugins/*/; do
    plugin=${plugin%/}
    [ -d "$plugin" ] || continue
    for skill in "$plugin"/skills/*/SKILL.md; do
      [ -f "$skill" ] || continue
      check_frontmatter "$root" "$skill"
      check_relative_paths "$root" "$skill"
    done
    while IFS= read -r file; do
      check_banned "$root" "$file" "$AGENT_SPECIFIC" "" "agent-specific name"
    done < <(find "$plugin/skills" "$plugin/docs" "$plugin/templates" "$plugin/trackers" -type f 2>/dev/null)
    while IFS= read -r file; do
      is_tracker_specific_doc "$file" && continue
      check_banned "$root" "$file" "$TRACKER_SPECIFIC" "-i" "tracker-specific term outside a tracker sheet"
    done < <(find "$plugin/skills" "$plugin/docs" "$plugin/templates" -type f 2>/dev/null)
    check_ops "$root" "$plugin"
  done
  names=$(for skill in "$root"/plugins/*/skills/*/; do [ -d "$skill" ] && basename "$skill"; done | sort)
  for dup in $(printf '%s\n' "$names" | uniq -d); do
    fail plugins - "skill name \`$dup\` is used by more than one plugin"
  done
  while IFS= read -r line; do
    [ -n "$line" ] && { fails=$((fails + 1)); echo "$line"; }
  done < <(check_manifests "$root")
  check_personal_values "$root"
  [ "$fails" -eq 0 ]
}

if [ "${1:-}" = "--check" ]; then
  [ -n "${2:-}" ] || { echo "usage: structure.test.sh --check <root>" >&2; exit 2; }
  check_root "$2"
  exit $?
fi

# ---- self-test: every fixture fails for its own reason, and the clean one passes ----
bad=0
expect_fail() { # <fixture> [env assignment]
  local fx=$here/fixtures/$1 want out
  want=$(cat "$fx/expect")
  out=$(env ${2:-PW_DENYLIST_FILE=/dev/null} bash "$0" --check "$fx")
  if [ $? -eq 0 ]; then echo "not ok - $1: expected a failure, got none"; bad=$((bad + 1)); return; fi
  if ! printf '%s\n' "$out" | grep -qF -- "$want"; then
    echo "not ok - $1: output lacks \"$want\""; printf '%s\n' "$out" | sed 's/^/    /'; bad=$((bad + 1)); return
  fi
  if [ "$(printf '%s\n' "$out" | grep -c '^FAIL ')" -ne 1 ]; then
    echo "not ok - $1: expected exactly one FAIL line"; printf '%s\n' "$out" | sed 's/^/    /'; bad=$((bad + 1)); return
  fi
  if ! printf '%s\n' "$out" | grep -qE '^FAIL [^ ]+(:[0-9]+)?: '; then
    echo "not ok - $1: FAIL line does not name a file"; bad=$((bad + 1)); return
  fi
  echo "ok - $1"
}
expect_pass() { # <fixture> <label> [env assignment]
  local out
  out=$(env ${3:-PW_DENYLIST_FILE=/dev/null} bash "$0" --check "$here/fixtures/$1")
  if [ $? -ne 0 ]; then echo "not ok - $2"; printf '%s\n' "$out" | sed 's/^/    /'; bad=$((bad + 1)); return; fi
  echo "ok - $2"
}

for fx in bad-mcp-tool bad-plugin-root-var bad-frontmatter-key bad-name-mismatch bad-tracker-term \
  bad-missing-op bad-email bad-root-email bad-relative-path bad-manifest; do
  expect_fail "$fx"
done
expect_pass clean "clean fixture passes"

deny=$(mktemp)
echo "acmecorp" > "$deny"
expect_pass denylist-term "denylist fixture passes with no denylist"
expect_fail denylist-term "PW_DENYLIST_FILE=$deny"
rm -f "$deny"

# ---- the real repo ----
repo=$(cd "$here/.." && pwd)
if out=$(bash "$0" --check "$repo"); then
  echo "ok - repo passes the structural checks"
else
  echo "not ok - repo fails the structural checks"; printf '%s\n' "$out" | sed 's/^/    /'; bad=$((bad + 1))
fi

[ "$bad" -eq 0 ]
