#!/usr/bin/env bash
# RoR Command Center — rorcc CLI smoke tests.
# No Ollama or jq required: validates syntax, help, build-agent codegen, and
# error handling. Run from anywhere: tests/smoke.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
RORCC="$ROOT/cli/rorcc"

PASS=0; FAIL=0
ok()   { printf '  \033[32mPASS\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }

# assert_exit <expected> <desc> -- <command...>
assert_exit() {
  local expected="$1" desc="$2"; shift 2; shift  # drop the "--"
  "$@" >/dev/null 2>&1; local rc=$?
  if [ "$rc" -eq "$expected" ]; then ok "$desc"; else bad "$desc (exit $rc, expected $expected)"; fi
}

printf '\033[1mrorcc smoke tests\033[0m\n\n'

printf 'syntax (bash -n):\n'
for f in "$RORCC" "$ROOT"/lib/rorcc/*.sh "$ROOT/install.sh" "$ROOT/setup.sh" "$ROOT/.githooks/pre-commit"; do
  if bash -n "$f" 2>/dev/null; then ok "$(basename "$f")"; else bad "$(basename "$f")"; fi
done

printf '\ncommands:\n'
assert_exit 0 "rorcc help"                 -- "$RORCC" help
assert_exit 2 "unknown command -> 2"       -- "$RORCC" frobnicate
assert_exit 2 "init (no arg) -> 2"         -- "$RORCC" init
assert_exit 2 "init bad flag -> 2"         -- "$RORCC" init --bogus
assert_exit 2 "init --docker (no dir) -> 2" -- "$RORCC" init --docker
assert_exit 2 "build-agent (no arg) -> 2"  -- "$RORCC" build-agent
assert_exit 1 "build-agent bad name -> 1"  -- "$RORCC" build-agent does-not-exist
assert_exit 2 "agent (no arg) -> 2"        -- "$RORCC" agent
assert_exit 2 "agent bad flag -> 2"        -- "$RORCC" agent rails-architect --bogus
# Cloud without credentials/jq must fail cleanly (exit 1), never hang.
assert_exit 1 "agent --cloud (no key) -> 1" -- env -u OPENAI_API_KEY -u ANTHROPIC_API_KEY "$RORCC" agent rails-architect --cloud
# Proxy prints config and exits 0 (no --start, so it never launches a server).
assert_exit 0 "proxy (info only) -> 0"     -- "$RORCC" proxy
assert_exit 2 "proxy bad flag -> 2"        -- "$RORCC" proxy --bogus
assert_exit 2 "skill (no arg) -> 2"        -- "$RORCC" skill
assert_exit 1 "skill bad name -> 1"        -- "$RORCC" skill does-not-exist
assert_exit 2 "skill bad flag -> 2"        -- "$RORCC" skill create-feature-spec --bogus
assert_exit 2 "workflow (no arg) -> 2"     -- "$RORCC" workflow
assert_exit 1 "workflow bad name -> 1"     -- "$RORCC" workflow does-not-exist
assert_exit 2 "workflow bad flag -> 2"     -- "$RORCC" workflow new-feature --bogus

printf '\nbuild-agent codegen (no Ollama needed):\n'
TMP="$(mktemp -d)"; export HOME="$TMP"
if (cd "$ROOT" && "$RORCC" build-agent rails-architect >/dev/null 2>&1); then
  mf="$ROOT/.rorcc/build/rails-architect/Modelfile"
  [ -f "$mf" ] && ok "Modelfile generated" || bad "Modelfile missing"
  grep -q '^FROM ' "$mf" 2>/dev/null && ok "Modelfile has FROM" || bad "Modelfile missing FROM"
  grep -q 'ROLE DEFINITION' "$mf" 2>/dev/null && ok "Modelfile inlines role" || bad "role not inlined"
else
  bad "build-agent rails-architect failed"
fi
rm -rf "$ROOT/.rorcc" "$TMP"

printf '\ninstall.sh excludes archive/:\n'
INSTOUT="$(cd "$ROOT" && ./install.sh --dry-run "$(mktemp -d)" 2>&1)"
printf '%s\n' "$INSTOUT" | grep -qi 'archive/' && bad "archive/ leaked into install" || ok "archive/ not copied"
printf '%s\n' "$INSTOUT" | grep -q '\.ai/' && ok ".ai/ is copied (sanity)" || bad ".ai/ missing from install"

printf '\ndocs/INSTALL.md stays in sync with install.sh CORE_ITEMS:\n'
INSTALL_DOC="$ROOT/docs/INSTALL.md"
# Labels as documented in INSTALL.md "What gets installed" (must match CORE_ITEMS).
for needle in \
  '.ai/' \
  '.cursor/' \
  '.claude/' \
  'AGENTS.md' \
  'CLAUDE.md' \
  'docs/integrations/' \
  'docs/how-to/' \
  'docs/CLAUDE.md' \
  'docs/COLLABORATIVE-DESIGN-PRINCIPLE.md' \
  'docs/USER-MANUAL.md' \
  '.github/copilot-instructions.md' \
  '--install-cli'
do
  if grep -Fq -- "$needle" "$INSTALL_DOC"; then
    ok "INSTALL.md mentions $needle"
  else
    bad "INSTALL.md missing $needle"
  fi
done
# CORE_ITEMS in install.sh must list the human-facing docs we document.
for item in AGENTS.md docs/how-to docs/USER-MANUAL.md; do
  if grep -Fq "\"$item\"" "$ROOT/install.sh"; then
    ok "install.sh CORE includes $item"
  else
    bad "install.sh CORE missing $item"
  fi
done

printf '\nollama_has_model (matches with/without tag):\n'
# Run in an isolated bash so common.sh's ok()/err() don't clobber this file's.
# Stub `ollama list` with a fixture mimicking real output (header + "name:latest").
check_model() {
  OLLAMA_FIXTURE='NAME	ID	SIZE
rorcc-product-owner:latest	a1	4.7 GB
qwen2.5-coder:7b	b2	4.7 GB' \
  bash -c '. "$1/lib/rorcc/common.sh"; ollama() { printf "%s\n" "$OLLAMA_FIXTURE"; }; ollama_has_model "$2"' _ "$ROOT" "$1"
}
assert_exit 0 "untagged agent name matches :latest" -- check_model "rorcc-product-owner"
assert_exit 0 "tagged base model matches"           -- check_model "qwen2.5-coder:7b"
assert_exit 1 "absent model does not match"         -- check_model "rorcc-nope"

printf '\nchat thinking indicator (TTY-guarded, stderr-only):\n'
# Critical: the hint must never reach stdout (it would pollute the saved reply),
# and must stay silent when stderr is not a TTY (clean pipes/logs). Run isolated
# so chat.sh helpers don't clobber this file's ok()/bad().
THINK_ERR="$(mktemp)"
THINK_OUT="$(bash -c '. "$1/lib/rorcc/chat.sh"; _chat_think_show; _chat_think_clear' _ "$ROOT" 2>"$THINK_ERR")"
[ -z "$THINK_OUT" ] && ok "no stdout pollution" || bad "stdout polluted: $THINK_OUT"
[ ! -s "$THINK_ERR" ] && ok "silent when stderr not a TTY" || bad "leaked to stderr off-TTY"
rm -f "$THINK_ERR"

printf '\nworkflow parsing:\n'
# Isolated so workflow.sh helpers do not clobber this file's ok()/bad().
wf_eval() {
  RORCC_LIB_DIR="$ROOT/lib/rorcc" bash -c '
    . "$1/lib/rorcc/common.sh"
    . "$1/lib/rorcc/workflow.sh"
    shift
    "$@"
  ' _ "$ROOT" "$@"
}

WFOUT="$(cd "$ROOT" && wf_eval _parse_phases .ai/workflows/new-feature.yaml)"
nlines="$(printf '%s\n' "$WFOUT" | grep -c .)"
[ "$nlines" -eq 8 ] && ok "new-feature parses 8 phases" || bad "phase count = $nlines (expected 8)"
printf '%s\n' "$WFOUT" | awk -F'|' 'NR==1{exit !($1=="idea" && $2=="Idea" && $3=="product-owner" && $4=="create-feature-spec")}' \
  && ok "phase 1 = idea/Idea/product-owner/create-feature-spec" || bad "phase 1 fields"
printf '%s\n' "$WFOUT" | awk -F'|' '
  $1=="development" {
    found=1
    ok = ($3 ~ /backend-rails-developer/ && $3 ~ /frontend-react-inertia-developer/ \
      && $4 ~ /create-api-endpoints/ && $4 ~ /review-db-migrations/ && $4 ~ /ponytail-review/)
  }
  END { exit !(found && ok) }
' && ok "development keeps both agents and all three skills" || bad "development arrays truncated"

# Inline vs block arrays must both preserve every element.
BLOCK_WF="$(mktemp)"
cat > "$BLOCK_WF" <<'EOF'
name: block-arrays
phases:
  - id: development
    label: Development
    agents:
      - backend-rails-developer
      - frontend-react-inertia-developer
    skills:
      - create-api-endpoints
      - review-db-migrations
      - ponytail-review
    depends_on:
      - implementation-plan
EOF
BLOCK_OUT="$(wf_eval _parse_phases "$BLOCK_WF")"
printf '%s\n' "$BLOCK_OUT" | awk -F'|' '
  $1=="development" {
    exit !($3=="backend-rails-developer,frontend-react-inertia-developer" \
      && $4=="create-api-endpoints,review-db-migrations,ponytail-review" \
      && $5=="implementation-plan")
  }
' && ok "block-style YAML arrays keep every element" || bad "block-style arrays"
rm -f "$BLOCK_WF"

UNITS="$(wf_eval _workflow_units "$ROOT/.ai/workflows/new-feature.yaml")"
[ "$UNITS" = "14" ] && ok "new-feature declared units = 14" || bad "declared units = $UNITS (expected 14)"

printf '\nworkflow --plan (no LLM):\n'
PLAN_OUT="$(cd "$ROOT" && env -u OPENAI_API_KEY -u ANTHROPIC_API_KEY -u OLLAMA_HOST \
  "$RORCC" workflow new-feature --plan 2>&1)"
plan_rc=$?
[ "$plan_rc" -eq 0 ] && ok "rorcc workflow new-feature --plan -> 0" || bad "--plan exit $plan_rc"
printf '%s\n' "$PLAN_OUT" | grep -q 'Declared units: 14' \
  && ok "--plan prints declared units" || bad "--plan missing declared units"
printf '%s\n' "$PLAN_OUT" | grep -q 'Selected units:' \
  && ok "--plan prints selected units" || bad "--plan missing selected units"
printf '%s\n' "$PLAN_OUT" | grep -q 'LLM calls performed: 0' \
  && ok "--plan reports 0 LLM calls" || bad "--plan missing LLM calls line"
printf '%s\n' "$PLAN_OUT" | grep -q 'create-api-endpoints' \
  && ok "--plan lists development skills" || bad "--plan missing development skills"
printf '%s\n' "$PLAN_OUT" | grep -q 'capistrano-review:no matching paths' \
  && ok "--plan omits capistrano-review in this repo" || bad "--plan should omit capistrano-review"
printf '%s\n' "$PLAN_OUT" | grep -q 'review-db-migrations' \
  && ok "--plan keeps review-db-migrations (create-* sibling)" || bad "review-db-migrations dropped"

FULL_PLAN="$(cd "$ROOT" && "$RORCC" workflow new-feature --plan --full 2>&1)"
printf '%s\n' "$FULL_PLAN" | grep -q 'Selected units: 14' \
  && ok "--full --plan selects all 14 units" || bad "--full should select 14"

ONLY_PLAN="$(cd "$ROOT" && "$RORCC" workflow new-feature --plan --only idea,specification 2>&1)"
printf '%s\n' "$ONLY_PLAN" | grep -q 'out of --only' \
  && ok "--only marks other phases out of scope" || bad "--only scope missing"
ONLY_SEL="$(printf '%s\n' "$ONLY_PLAN" | awk '/^Selected units:/{print $3}')"
[ "$ONLY_SEL" = "2" ] && ok "--only idea,specification → 2 selected units" || bad "--only selected=$ONLY_SEL"

AUTO_PLAN="$(cd "$ROOT" && env -u OPENAI_API_KEY -u ANTHROPIC_API_KEY \
  "$RORCC" workflow new-feature --plan --auto 2>&1)"
[ $? -eq 0 ] && printf '%s\n' "$AUTO_PLAN" | grep -q 'LLM calls performed: 0' \
  && ok "--plan --auto still 0 LLM calls" || bad "--plan --auto invoked a model?"

printf '\nworkflow preflight:\n'
preflight_wf() {
  local wf="$1"
  RORCC_LIB_DIR="$ROOT/lib/rorcc" bash -c '
    . "$1/lib/rorcc/common.sh"
    . "$1/lib/rorcc/workflow.sh"
    _preflight_workflow "$2" "$1"
  ' _ "$ROOT" "$wf"
}

BAD_SKILL="$(mktemp)"
cat > "$BAD_SKILL" <<'EOF'
name: bad-skill
phases:
  - id: only
    label: Only
    skill: definitely-not-a-skill
EOF
if ! preflight_wf "$BAD_SKILL" >/dev/null 2>&1; then ok "preflight rejects missing skill"; else bad "missing skill should fail"; fi
rm -f "$BAD_SKILL"

BAD_AGENT="$(mktemp)"
cat > "$BAD_AGENT" <<'EOF'
name: bad-agent
phases:
  - id: only
    label: Only
    agent: not-a-real-agent
EOF
if ! preflight_wf "$BAD_AGENT" >/dev/null 2>&1; then ok "preflight rejects missing agent"; else bad "missing agent should fail"; fi
rm -f "$BAD_AGENT"

BAD_DEP="$(mktemp)"
cat > "$BAD_DEP" <<'EOF'
name: bad-dep
phases:
  - id: only
    label: Only
    agent: product-owner
    depends_on: [no-such-phase]
EOF
if ! preflight_wf "$BAD_DEP" >/dev/null 2>&1; then ok "preflight rejects missing dependency"; else bad "missing dependency should fail"; fi
rm -f "$BAD_DEP"

SELF_DEP="$(mktemp)"
cat > "$SELF_DEP" <<'EOF'
name: self-dep
phases:
  - id: only
    label: Only
    agent: product-owner
    depends_on: [only]
EOF
if ! preflight_wf "$SELF_DEP" >/dev/null 2>&1; then ok "preflight rejects self-dependency"; else bad "self-dependency should fail"; fi
rm -f "$SELF_DEP"

printf '\nworkflow dependencies:\n'
DEP_STATE="$(mktemp)"
printf 'phase_id\tstatus\nphase-a\tskipped\n' > "$DEP_STATE"
DEP_OUT="$(RORCC_LIB_DIR="$ROOT/lib/rorcc" bash -c '
  . "$1/lib/rorcc/common.sh"
  . "$1/lib/rorcc/workflow.sh"
  _dep_outcome "phase-a" "$2"
' _ "$ROOT" "$DEP_STATE")"
[ "$DEP_OUT" = "blocked" ] && ok "skipped dependency blocks dependent phase" || bad "dep outcome = $DEP_OUT (expected blocked)"
rm -f "$DEP_STATE"

# Canonical workflows must still preflight clean (stale roster names would fail here).
for wf_name in new-feature aws-deployment legacy-onboarding production-incident; do
  preflight_wf "$ROOT/.ai/workflows/$wf_name.yaml" >/dev/null 2>&1 \
    && ok "preflight $wf_name" || bad "preflight $wf_name failed"
done

printf '\nworkflow router:\n'
route_eval() {
  RORCC_LIB_DIR="$ROOT/lib/rorcc" bash -c '
    . "$1/lib/rorcc/common.sh"
    . "$1/lib/rorcc/workflow.sh"
    WF_FULL=0
    _route_skills "$2" "$3"
    printf "SEL=%s\nOMIT=%s\n" "$WF_SELECTED" "$WF_OMITTED"
  ' _ "$ROOT" "$@"
}

# Isolated tree: review-db-migrations with no migrations and no create-* sibling.
BARE="$(mktemp -d)"
mkdir -p "$BARE/.ai/skills/review-db-migrations"
cp "$ROOT/.ai/skills/review-db-migrations/SKILL.md" "$BARE/.ai/skills/review-db-migrations/"
BARE_OUT="$(route_eval "$BARE" "review-db-migrations")"
printf '%s\n' "$BARE_OUT" | grep -q 'OMIT=review-db-migrations:no matching paths' \
  && ok "router omits review-db-migrations without db/" || bad "bare omit: $BARE_OUT"
mkdir -p "$BARE/db/migrate"
touch "$BARE/db/migrate/001_init.rb"
HIT_OUT="$(route_eval "$BARE" "review-db-migrations")"
printf '%s\n' "$HIT_OUT" | grep -q 'SEL=review-db-migrations' \
  && ok "router keeps review-db-migrations when paths match" || bad "hit: $HIT_OUT"
rm -rf "$BARE"

# create-* sibling keeps the review even without files (this repo has no db/migrate).
DEV_OUT="$(route_eval "$ROOT" "create-api-endpoints,review-db-migrations")"
printf '%s\n' "$DEV_OUT" | grep -q 'SEL=create-api-endpoints,review-db-migrations' \
  && ok "create-* sibling keeps contextual review" || bad "sibling: $DEV_OUT"

LEAN="$(RORCC_LIB_DIR="$ROOT/lib/rorcc" bash -c '
  . "$1/lib/rorcc/common.sh"
  . "$1/lib/rorcc/assemble.sh"
  assemble_lean "$1" backend-rails-developer
' _ "$ROOT")"
printf '%s\n' "$LEAN" | grep -q 'backend-rails-developer' \
  && ok "assemble_lean names the specialist" || bad "lean missing specialist"
printf '%s\n' "$LEAN" | grep -q 'STANDARD:' \
  && bad "assemble_lean dumped standards" || ok "assemble_lean stays lean"

printf '\n'
printf '\033[1mResult:\033[0m %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
