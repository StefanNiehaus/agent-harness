#!/usr/bin/env bash
# The pw-board reader against a filled fixture and against the raw templates, so a template change that
# breaks the reader fails here. Fixtures are copied into temp folders; nothing in the clone is written.
set -u

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
clone="$(cd -P "$here/.." && pwd -P)"
plugin="$clone/plugins/project-workflow"
reader="$plugin/bin/pw-board"
fixtures="$here/fixtures/pw-board"
export PW_BOARD_TODAY=2026-11-26

bad=0
ok() { echo "ok - $1"; }
not_ok() { echo "not ok - $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/    /'; bad=$((bad + 1)); }
check() { if [ "$2" = "$3" ]; then ok "$1"; else not_ok "$1" "expected: $3 / got: $2"; fi; }
has() { if printf '%s\n' "$2" | grep -qF -- "$3"; then ok "$1"; else not_ok "$1" "missing: $3"$'\n'"$2"; fi; }
lacks() { if printf '%s\n' "$2" | grep -qF -- "$3"; then not_ok "$1" "unexpected: $3"; else ok "$1"; fi; }
jq_() { python3 -c "import json,sys; d=json.load(sys.stdin); print($1)"; }
row() { printf '%s\n' "$1" | jq_ "next(r for r in d['board']['rows'] if r['id']=='$2')['$3']"; }

temps=()
new_temp() { local t; t=$(mktemp -d); temps+=("$t"); echo "$t"; }
trap 'chmod -R u+w "${temps[@]}" 2>/dev/null; rm -rf "${temps[@]}"' EXIT

work=$(new_temp)
cp -R "$fixtures/GH-12-stoep-sync" "$fixtures/old-shape" "$work/"
fx="$work/GH-12-stoep-sync"
tracker="$fx/tracker.md"
line_for() { echo "$1 GH-12-stoep-sync, $2 — first read the tracker at $tracker"; }

# ---- the reader itself ----
[ -x "$reader" ] && ok "the reader is executable" || not_ok "the reader is executable"
third=$(python3 - "$reader" <<'PY'
import re, sys
mods = set()
for line in open(sys.argv[1], encoding="utf-8"):
    m = re.match(r"\s*(?:import|from)\s+([\w.]+)", line)
    if m:
        mods.add(m.group(1).split(".")[0])
print(" ".join(sorted(m for m in mods if m not in sys.stdlib_module_names)))
PY
)
check "the reader imports only the standard library" "$third" ""

# ---- dispatch lines ----
out=$("$reader" line "$fx" D3); rc=$?
check "a row naming its skill exits 0" "$rc" 0
check "a row naming its skill gets the rules-doc line, keyed by folder name" "$out" "$(line_for /ce-work D3)"

for id in D4 D1:B1 D2; do
  out=$("$reader" line "$fx" "$id" 2>/dev/null); rc=$?
  check "$id (done, folded or cancelled) exits 4" "$rc" 4
  check "$id prints no line" "$out" ""
done

check "a blocked row naming a skill gets a line" "$("$reader" line "$fx" D5)" "$(line_for /ce-work D5)"
check "a clause naming two skills takes the first" "$("$reader" line "$fx" D6)" "$(line_for /ce-code-review D6)"

out=$("$reader" line "$fx" D1:B3); rc=$?
check "a row with no skill in its clause exits 3" "$rc" 3
check "a sub-deliverable offers its parent's recipe: Entry, /ce-work, Exit" "$out" \
  "$(for s in /ce-brainstorm /ce-plan /ce-work /ce-compound; do line_for "$s" D1:B3; done)"

out=$("$reader" line "$fx" retry-backoff 2>/dev/null); rc=$?
check "a Queue handle gets no line (exit 4)" "$rc" 4
"$reader" line "$fx" D99 >/dev/null 2>&1
check "an unknown row exits 2" "$?" 2

# ---- json ----
json=$("$reader" json "$fx"); rc=$?
check "json exits 0" "$rc" 0
printf '%s\n' "$json" | python3 -m json.tool >/dev/null && ok "json parses" || not_ok "json parses"
check "json carries its schema" "$(printf '%s\n' "$json" | jq_ "d['schema']")" "pw-board/1"
check "json says the board is raw file state" "$(printf '%s\n' "$json" | jq_ "d['raw']")" "True"
check "D4 has status none" "$(row "$json" D4 status)" none
check "D1:B1 has status none" "$(row "$json" D1:B1 status)" none
check "D1 without a skill has status pick" "$(row "$json" D1 status)" pick
check "D1 keeps its roll-up" "$(row "$json" D1 rollup)" 1/3
check "D1:B2 has D1 as parent" "$(row "$json" D1:B2 parent)" D1
check "rows keep board order with sub-deliverables under their parent" \
  "$(printf '%s\n' "$json" | jq_ "','.join(r['id'] for r in d['board']['rows'])")" "D1,D1:B1,D1:B2,D1:B3,D2,D3,D4,D5,D6"
check "the queue lists handles in order, skipping placeholders and comments" \
  "$(printf '%s\n' "$json" | jq_ "','.join(d['board']['queue']['handles'])")" "retry-backoff,export-csv"
check "verified date and age" "$(printf '%s\n' "$json" | jq_ "d['board']['verified'], d['board']['verified_age_days']")" "2026-11-22 4"
check "open decisions skip the struck one" "$(printf '%s\n' "$json" | jq_ "len(d['board']['decisions'])")" 2
check "a .md brief resolves to an absolute path that exists" \
  "$(printf '%s\n' "$json" | jq_ "d['board']['decisions'][0]['brief_path'], d['board']['decisions'][0]['exists']")" \
  "$fx/briefs/d1-merge-strategy.md True"
check "a legacy .html brief resolves, flagged missing" \
  "$(printf '%s\n' "$json" | jq_ "d['board']['decisions'][1]['brief_path'], d['board']['decisions'][1]['exists']")" \
  "$fx/briefs/d6-archive-format.html False"

# ---- rows ----
rows=$("$reader" rows "$fx")
check "every rows line has seven tab-separated fields" \
  "$(printf '%s\n' "$rows" | awk -F'\t' 'NF != 7' | wc -l | tr -d ' ')" 0
has "a Queue handle is a queue row with no line" "$rows" $'retry-backoff\tqueue\t\tnone\t'
has "a row with a line carries it" "$rows" $'D3\tdeliverable\t🟡\tline\t'"$(line_for /ce-work D3)"
has "a decision row carries its brief path" "$rows" $'\t'"$fx/briefs/d1-merge-strategy.md"$'\t'

# ---- show ----
glance=$("$reader" show "$fx" --width 100)
has "the glance says it is raw file state" "$glance" "RAW FILE"
has "the glance shows the verified date and age" "$glance" "verified 2026-11-22 (4d ago)"
has "the glance shows the critical path" "$glance" "D1 → D3"
for id in D1 D1:B1 D1:B2 D1:B3 D2 D3 D4 D5 D6; do
  printf '%s\n' "$glance" | grep -qE "^ *[^ ]+ $id " || not_ok "the glance lists $id" "$glance"
done
ok "the glance lists every row id"
has "the glance shows the first next action" "$glance" "D3 — run the plan"
has "the glance shows the second next action" "$glance" "D1:B3 — start once B2 merges"
has "the glance shows the Queue count" "$glance" "2 waiting: retry-backoff, export-csv"
has "the glance shows the .md brief" "$glance" "→ briefs/d1-merge-strategy.md"
has "the glance shows the .html brief" "$glance" "→ briefs/d6-archive-format.html"
check "D3 ends with its skill" "$(printf '%s\n' "$glance" | grep ' D3 ' | grep -c '/ce-work$')" 1
check "D1:B3 ends with ?" "$(printf '%s\n' "$glance" | grep ' D1:B3 ' | grep -c '?$')" 1
check "D4 has no skill marker" "$(printf '%s\n' "$glance" | grep ' D4 ' | grep -cE '(/[a-z-]+|\?)$')" 0

narrow=$("$reader" show "$fx" --width 80)
widest=$(printf '%s\n' "$narrow" | python3 -c '
import sys, unicodedata
def w(s):
    return sum(0 if unicodedata.combining(c) or "︀" <= c <= "️" else
               2 if unicodedata.east_asian_width(c) in "WF" else 1 for c in s)
print(max(w(l.rstrip("\n")) for l in sys.stdin))')
[ "$widest" -le 80 ] && ok "show --width 80 keeps every line within 80 columns" || not_ok "show --width 80 keeps every line within 80 columns" "widest: $widest"
has "a long outcome is cut with …" "$(printf '%s\n' "$narrow" | grep ' D6 ')" "…"

nodecomp=$(new_temp)/GH-12-stoep-sync
cp -R "$fx" "$nodecomp" && rm "$nodecomp/decomposition.md"
out=$("$reader" show "$nodecomp"); rc=$?
check "no decomposition.md still renders" "$rc" 0
has "no decomposition.md gives an empty Queue" "$out" "Queue     empty"

# ---- the raw templates ----
raw=$(new_temp)/GH-99-template
mkdir -p "$raw"
cp "$plugin/templates/tracker.md" "$plugin/templates/decomposition.md" "$raw/"
for cmd in show rows json; do
  "$reader" "$cmd" "$raw" >/dev/null 2>&1
  check "$cmd on the raw templates exits 0" "$?" 0
done
out=$("$reader" show "$raw")
has "the raw template's placeholder date reads as never verified" "$out" "verified: never"
lacks "the template's <handle> Queue line is not listed" "$out" "<handle>"
rawjson=$("$reader" json "$raw")
check "the template's none-open line yields no decisions" "$(printf '%s\n' "$rawjson" | jq_ "len(d['board']['decisions'])")" 0

# ---- old shape ----
old="$work/old-shape"
out=$("$reader" json "$old"); rc=$?
check "json on an old-shape tracker exits 1" "$rc" 1
check "json on an old-shape tracker has no board" "$(printf '%s\n' "$out" | jq_ "d['board']")" None
has "json on an old-shape tracker gives a reason" "$(printf '%s\n' "$out" | jq_ "d['reason']")" "old-shape tracker"
err=$("$reader" line "$old" D1 2>&1 >/dev/null); rc=$?
check "line on an old-shape tracker exits 1" "$rc" 1
has "line on an old-shape tracker says why" "$err" "/pw-land old-shape close"

# ---- project resolution through the main checkout ----
repo=$(new_temp)
main="$repo/main"
git init -q "$main"
git -C "$main" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m init
git -C "$main" worktree add -q "$main/.worktrees/x" -b x 2>/dev/null
mkdir -p "$main/scratch"
cp -R "$fx" "$main/scratch/GH-12-stoep-sync"
expected="/ce-work GH-12-stoep-sync, D3 — first read the tracker at $(cd -P "$main" && pwd -P)/scratch/GH-12-stoep-sync/tracker.md"
check "from a worktree, a root key resolves to the main checkout's project" \
  "$(cd "$main/.worktrees/x" && "$reader" line GH-12 D3)" "$expected"
check "from a worktree, a folder name resolves too" \
  "$(cd "$main/.worktrees/x" && "$reader" line GH-12-stoep-sync D3)" "$expected"
check "--repo resolves from elsewhere" "$(cd / && "$reader" --repo "$main/.worktrees/x" line gh-12 D3)" "$expected"
check "with one project, no argument picks it" "$(cd "$main" && "$reader" json | jq_ "d['project']['folder']")" GH-12-stoep-sync
"$reader" --repo "$main" line GH-77 D1 >/dev/null 2>&1
check "an unknown key exits 2" "$?" 2
cp -R "$old" "$main/scratch/old-shape"
touch -t 202601010000 "$main/scratch/GH-12-stoep-sync/tracker.md"
err=$("$reader" --repo "$main" show 2>&1); rc=$?
check "two projects and no argument exits 2" "$rc" 2
has "two projects and no argument lists the first" "$err" "GH-12-stoep-sync"
has "two projects and no argument lists the second" "$err" "old-shape"
projects=$("$reader" --repo "$main" projects)
check "projects lists the newest tracker first, marking the old shape" \
  "$(printf '%s\n' "$projects" | cut -f1,2,4 | tr '\t\n' ' ')" "old-shape GH-3 old GH-12-stoep-sync GH-12 v1 "

# ---- the reader writes nothing ----
ro=$(new_temp)/GH-12-stoep-sync
cp -R "$fx" "$ro"
chmod -R a-w "$ro"
sums() { (cd "$ro" && find . -type f -exec cksum {} + | sort; ls -laR . | grep -v '^total'); }
before=$(sums)
fails=0
for args in "show $ro" "rows $ro" "json $ro" "line $ro D3"; do
  "$reader" $args >/dev/null 2>&1 || fails=$((fails + 1))
done
check "every subcommand runs against a read-only copy" "$fails" 0
check "the folder is unchanged after every subcommand" "$(sums)" "$before"

[ "$bad" -eq 0 ]
