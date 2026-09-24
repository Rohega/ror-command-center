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
assert_exit 2 "workflow --size bad -> 2"    -- "$RORCC" workflow new-feature --plan --size Q
assert_exit 2 "workflow --request empty -> 2" -- "$RORCC" workflow new-feature --plan --request

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

printf '\nadaptive classifier:\n'
classify_eval() {
  RORCC_LIB_DIR="$ROOT/lib/rorcc" bash -c '
    . "$1/lib/rorcc/common.sh"
    . "$1/lib/rorcc/workflow.sh"
    _classify_request "$2"
    _classify_format
  ' _ "$ROOT" "$1"
}

S_CLASS="$(classify_eval "Cambiar el texto Login por Entrar")"
printf '%s\n' "$S_CLASS" | grep -q '^size: S$' \
  && ok "S: size S for Login→Entrar copy" || bad "S size: $S_CLASS"
printf '%s\n' "$S_CLASS" | grep -q 'auth_changed: false' \
  && ok "S: login label is not auth_changed" || bad "S auth: $S_CLASS"
printf '%s\n' "$S_CLASS" | grep -q 'user_behavior_changed: false' \
  && ok "S: copy-only is not user_behavior" || bad "S behavior: $S_CLASS"

M_CLASS="$(classify_eval "Agregar filtro por fecha a facturas")"
printf '%s\n' "$M_CLASS" | grep -q '^size: M$' \
  && ok "M: size M for date filter" || bad "M size: $M_CLASS"
printf '%s\n' "$M_CLASS" | grep -q 'user_behavior_changed: true' \
  && ok "M: filter sets user_behavior_changed" || bad "M behavior: $M_CLASS"
printf '%s\n' "$M_CLASS" | grep -q 'architecture_changed: false' \
  && ok "M: no architecture_changed" || bad "M arch: $M_CLASS"

L_CLASS="$(classify_eval "Agregar módulo de vacaciones con solicitudes y aprobación de RH")"
printf '%s\n' "$L_CLASS" | grep -q '^size: L$' \
  && ok "L: size L for vacation module" || bad "L size: $L_CLASS"
printf '%s\n' "$L_CLASS" | grep -q 'user_behavior_changed: true' \
  && ok "L: module sets user_behavior_changed" || bad "L behavior: $L_CLASS"

XL_CLASS="$(classify_eval "Migrar Sidekiq a Solid Queue")"
printf '%s\n' "$XL_CLASS" | grep -q '^size: XL$' \
  && ok "XL: size XL for Sidekiq→Solid Queue" || bad "XL size: $XL_CLASS"
printf '%s\n' "$XL_CLASS" | grep -q 'architecture_changed: true' \
  && ok "XL: architecture_changed" || bad "XL arch: $XL_CLASS"

plan_request() {
  (cd "$ROOT" && env -u OPENAI_API_KEY -u ANTHROPIC_API_KEY -u OLLAMA_HOST \
    "$RORCC" workflow new-feature --plan --request "$1" 2>&1)
}

plan_metrics() {
  awk '
    /^Declared units:/{d=$3}
    /^Selected units:/{s=$3}
    /^Omitted units:/{o=$3}
    /^LLM calls performed:/{l=$4}
    END{printf "%s %s %s %s\n", d,s,o,l}
  ' <<< "$1"
}

printf '\nadaptive --plan (new-feature):\n'
BASE_PLAN="$(cd "$ROOT" && env -u OPENAI_API_KEY -u ANTHROPIC_API_KEY -u OLLAMA_HOST \
  "$RORCC" workflow new-feature --plan 2>&1)"
BASE_M="$(plan_metrics "$BASE_PLAN")"
if printf '%s\n' "$BASE_PLAN" | grep -q 'Classification:'; then
  bad "baseline leaked classification"
else
  ok "--plan without --request prints no classification"
fi

S_PLAN="$(plan_request "Cambiar el texto Login por Entrar")"
S_M="$(plan_metrics "$S_PLAN")"
printf '%s\n' "$S_PLAN" | grep -q 'size: S' && ok "S plan prints size S" || bad "S plan class"
if printf '%s\n' "$S_PLAN" | grep -q 'create-feature-spec:applies_when' \
  && printf '%s\n' "$S_PLAN" | grep -q 'create-user-stories:applies_when' \
  && printf '%s\n' "$S_PLAN" | grep -q 'create-architecture-plan:applies_when' \
  && printf '%s\n' "$S_PLAN" | grep -q 'document-module:applies_when'; then
  ok "S omits spec, stories, ADR, module docs"
else
  bad "S still selected a planning/doc unit"
fi
printf '%s\n' "$S_PLAN" | grep -q 'create-api-endpoints' \
  && ok "S keeps development" || bad "S dropped development"
if printf '%s\n' "$S_PLAN" | grep -q 'release-checklist:applies_when' \
  && printf '%s\n' "$S_PLAN" | grep -q 'capistrano-review:applies_when'; then
  ok "S retags every deployment unit as applies_when"
else
  bad "S deployment omit reasons mixed or incomplete"
fi
printf '%s\n' "$S_PLAN" | grep -q 'LLM calls performed: 0' \
  && ok "S --plan is 0 LLM" || bad "S plan called a model?"

M_PLAN="$(plan_request "Agregar filtro por fecha a facturas")"
if printf '%s\n' "$M_PLAN" | grep -q 'size: M' \
  && printf '%s\n' "$M_PLAN" | grep -q 'create-api-endpoints' \
  && printf '%s\n' "$M_PLAN" | grep -q 'qa-plan' \
  && printf '%s\n' "$M_PLAN" | grep -q 'ponytail-review' \
  && printf '%s\n' "$M_PLAN" | grep -q 'create-feature-spec:applies_when' \
  && printf '%s\n' "$M_PLAN" | grep -q 'create-architecture-plan:applies_when'; then
  ok "M: develop+test+review, no spec/ADR"
else
  bad "M plan mismatch"
fi

L_PLAN="$(plan_request "Agregar módulo de vacaciones con solicitudes y aprobación de RH")"
if printf '%s\n' "$L_PLAN" | grep -q 'size: L' \
  && printf '%s\n' "$L_PLAN" | grep -q 'selected: create-feature-spec' \
  && printf '%s\n' "$L_PLAN" | grep -q 'selected: create-user-stories' \
  && printf '%s\n' "$L_PLAN" | grep -q 'qa-plan' \
  && printf '%s\n' "$L_PLAN" | grep -q 'document-module'; then
  ok "L: spec + stories + develop + QA + docs"
else
  bad "L plan mismatch"
fi

XL_PLAN="$(plan_request "Migrar Sidekiq a Solid Queue")"
if printf '%s\n' "$XL_PLAN" | grep -q 'size: XL' \
  && printf '%s\n' "$XL_PLAN" | grep -q 'selected: create-architecture-plan' \
  && printf '%s\n' "$XL_PLAN" | grep -q 'selected: create-feature-spec' \
  && printf '%s\n' "$XL_PLAN" | grep -q 'release-checklist'; then
  ok "XL: architecture + rollout + full pipeline"
else
  bad "XL plan mismatch"
fi

AUTH_PLAN="$(cd "$ROOT" && "$RORCC" workflow new-feature --plan --size S --signals auth_changed 2>&1)"
if printf '%s\n' "$AUTH_PLAN" | grep -q 'size: S' \
  && printf '%s\n' "$AUTH_PLAN" | grep -q 'auth_changed: true' \
  && printf '%s\n' "$AUTH_PLAN" | grep -q 'security-audit' \
  && printf '%s\n' "$AUTH_PLAN" | grep -q 'create-feature-spec:applies_when'; then
  ok "S+auth_changed keeps security-audit, omits spec"
else
  bad "S+auth plan mismatch"
fi

FULL_REQ="$(cd "$ROOT" && "$RORCC" workflow new-feature --plan --full --request "Cambiar el texto Login por Entrar" 2>&1)"
printf '%s\n' "$FULL_REQ" | grep -q 'Selected units: 14' \
  && ok "--full ignores applies_when (14 selected)" || bad "--full + --request should select 14"

ONLY_REQ="$(cd "$ROOT" && "$RORCC" workflow new-feature --plan --only idea --request "Cambiar el texto Login por Entrar" 2>&1)"
ONLY_REQ_SEL="$(printf '%s\n' "$ONLY_REQ" | awk '/^Selected units:/{print $3}')"
[ "$ONLY_REQ_SEL" = "1" ] && ok "--only idea ignores applies_when" || bad "--only + --request selected=$ONLY_REQ_SEL"

printf '\nadaptive metrics (declared / selected / omitted / LLM):\n'
printf '  %-22s %s\n' "baseline (no class)" "$BASE_M"
printf '  %-22s %s\n' "S copy" "$S_M"
printf '  %-22s %s\n' "M date filter" "$(plan_metrics "$M_PLAN")"
printf '  %-22s %s\n' "L vacation module" "$(plan_metrics "$L_PLAN")"
printf '  %-22s %s\n' "XL Solid Queue" "$(plan_metrics "$XL_PLAN")"
printf '  %-22s %s\n' "S+auth" "$(plan_metrics "$AUTH_PLAN")"

S_SEL="$(printf '%s' "$S_M" | awk '{print $2}')"
M_SEL="$(plan_metrics "$M_PLAN" | awk '{print $2}')"
L_SEL="$(plan_metrics "$L_PLAN" | awk '{print $2}')"
XL_SEL="$(plan_metrics "$XL_PLAN" | awk '{print $2}')"
BASE_SEL="$(printf '%s' "$BASE_M" | awk '{print $2}')"
if [ "$S_SEL" -lt "$M_SEL" ] && [ "$M_SEL" -lt "$L_SEL" ] && [ "$L_SEL" -le "$XL_SEL" ] \
  && [ "$S_SEL" -lt "$BASE_SEL" ] && [ "$M_SEL" -lt "$BASE_SEL" ]; then
  ok "S/M select fewer units than baseline and scale up to L/XL"
else
  bad "unit counts did not reduce for S/M (S=$S_SEL M=$M_SEL L=$L_SEL XL=$XL_SEL base=$BASE_SEL)"
fi

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

printf '\nbuilder:\n'
assert_exit 2 "builder bad flag -> 2" -- "$RORCC" builder --bogus
FIX="$(mktemp -d)"
mkdir -p "$FIX/.ai/agents"
PLAN_OUT="$(cd "$FIX" && "$RORCC" builder --plan 2>&1)"
plan_rc=$?
[ "$plan_rc" -eq 0 ] && ok "builder --plan -> 0" || bad "builder --plan exit $plan_rc"
printf '%s\n' "$PLAN_OUT" | grep -q 'rorcc workflow new-feature' \
  && ok "builder --plan prints the workflow command" || bad "builder --plan missing command"
[ -z "$(find "$FIX/docs" -type f 2>/dev/null)" ] \
  && ok "builder --plan writes no plan file" || bad "builder --plan wrote a file"
DRAFT="$(cd "$FIX" && "$RORCC" builder --request "I want a page where staff mark an order as packed" \
  --who staff --data yes --sign-in no --area change --done "Staff can mark an order packed." 2>&1)"
printf '%s\n' "$DRAFT" | grep -q 'draft saved' && ok "answers without --accept stay a draft" || bad "draft: $DRAFT"
find "$FIX/docs/plans" -name 'builder-*.md' | grep -q . \
  && ok "draft plan file exists" || bad "draft plan missing"
grep -q 'size: M' "$FIX"/docs/plans/builder-*.md \
  && ok "change + data maps to size M" || bad "size M missing"
grep -q 'database_changed' "$FIX"/docs/plans/builder-*.md \
  && ok "data yes sets database_changed" || bad "database_changed missing"
grep -q 'user_behavior_changed' "$FIX"/docs/plans/builder-*.md \
  && ok "page in the request sets user_behavior_changed" || bad "user_behavior_changed missing"
NEW="$(cd "$FIX" && "$RORCC" builder --request "Add a packed-orders area" \
  --who staff --data no --sign-in yes --area new --done "Staff sign in and open the new area." 2>&1)"
printf '%s\n' "$NEW" | grep -q -- '--size L' && ok "new area maps to size L" || bad "size L: $NEW"
printf '%s\n' "$NEW" | grep -q 'auth_changed' && ok "sign-in yes sets auth_changed" || bad "auth missing: $NEW"
assert_exit 2 "builder rejects a secret" -- "$RORCC" builder --request "store the password hunter2" \
  --who staff --data no --sign-in no --area change --done "no"
rm -rf "$FIX"

printf '\nactions:\n'
ACT="$(mktemp -d)"
git -C "$ACT" init -q
git -C "$ACT" config user.email t@example.com
git -C "$ACT" config user.name t
mkdir -p "$ACT/.ai/agents"
printf 'keep\n' >"$ACT/.ai/agents/.keep"
printf 'base\n' >"$ACT/keep.txt"
git -C "$ACT" add keep.txt .ai && git -C "$ACT" commit -qm init
printf 'base\nextra\n' >"$ACT/keep.txt"
printf 'pre\n' >"$ACT/note.txt"
LIST="$(mktemp)"
cat >"$LIST" <<'EOF'
--- file created.txt
hi
--- shell false
EOF
set +e
FAIL_OUT="$(cd "$ACT" && "$RORCC" actions "$LIST" 2>&1)"
fail_rc=$?
set +e
[ "$fail_rc" -ne 0 ] && ok "failed shell exits non-zero" || bad "failed shell exit 0"
printf '%s\n' "$FAIL_OUT" | grep -q 'failed shell false' && ok "prints failed" || bad "status: $FAIL_OUT"
[ ! -f "$ACT/created.txt" ] && ok "failed action removes its file" || bad "created.txt survived"
printf 'base\nextra\n' | cmp -s - "$ACT/keep.txt" && ok "dirty tracked file restored" || bad "keep.txt changed"
printf 'pre\n' | cmp -s - "$ACT/note.txt" && ok "untracked file restored" || bad "note.txt lost"
cat >"$LIST" <<'EOF'
--- file created.txt
hi
EOF
(cd "$ACT" && "$RORCC" actions "$LIST" >/dev/null) && ok "file action completes" || bad "file action failed"
[ -f "$ACT/created.txt" ] && ok "file action writes" || bad "created.txt missing"
(cd "$ACT" && "$RORCC" actions --undo >/dev/null) && ok "undo exits 0" || bad "undo failed"
[ ! -f "$ACT/created.txt" ] && ok "undo removes the action file" || bad "undo left created.txt"
printf 'base\nextra\n' | cmp -s - "$ACT/keep.txt" && ok "undo keeps prior edits" || bad "undo lost edits"
BAD="$(mktemp)"
printf '%s\n' '--- file ../escape.txt' 'x' >"$BAD"
assert_exit 1 "actions reject .." -- bash -c 'cd "$1" && "$2" actions "$3"' _ "$ACT" "$RORCC" "$BAD"
rm -rf "$ACT" "$LIST" "$BAD"

printf '\nsecurity:\n'
SEC="$(mktemp -d)"
git -C "$SEC" init -q
mkdir -p "$SEC/.ai/agents" "$SEC/app"
printf 'keep\n' >"$SEC/.ai/agents/.keep"
printf 'class User\nend\n' >"$SEC/app/clean.rb"
printf 'password = "hunter2"\n' >"$SEC/app/leaky.rb"
SKIP="$(cd "$SEC" && "$RORCC" security --size S 2>&1)"
printf '%s\n' "$SKIP" | grep -q 'security pass skipped' && ok "size S skips the pass" || bad "skip: $SKIP"
[ -z "$(find "$SEC/docs/security" -type f 2>/dev/null)" ] && ok "skipped pass writes nothing" || bad "skip wrote a file"
HIT="$(cd "$SEC" && "$RORCC" security --size S --signals auth_changed --paths app/leaky.rb,app/clean.rb 2>&1)"
printf '%s\n' "$HIT" | grep -q 'security findings:' && ok "auth signal writes findings" || bad "hit: $HIT"
REPORT="$(find "$SEC/docs/security" -name 'findings-*.md' | head -1)"
grep -q 'files: app/leaky.rb' "$REPORT" && ok "finding cites the opened leaky file" || bad "cite missing"
grep -q 'files: app/clean.rb' "$REPORT" && bad "finding cites a file with no issue" || ok "clean file is not a finding"
grep -q 'opened: app/leaky.rb,app/clean.rb' "$REPORT" && ok "report lists both opened files" || bad "opened list: $(cat "$REPORT")"
rm -rf "$SEC"

printf '\npreview:\n'
PRE="$(mktemp -d)"
mkdir -p "$PRE/.ai/agents"
printf 'services: {}\n' >"$PRE/docker-compose.yml"
printf 'RAILS_PORT=3010\n' >"$PRE/.env"
VIEW="$(cd "$PRE" && "$RORCC" preview 2>&1)"
printf '%s\n' "$VIEW" | grep -q 'preview: http://localhost:3010' && ok "preview prints the compose URL" || bad "url: $VIEW"
printf '%s\n' "$VIEW" | grep -q 'preview status: down' && ok "down preview is only a status" || bad "status: $VIEW"
REF="$(cd "$PRE" && "$RORCC" preview refresh 2>&1)"
ref_rc=$?
[ "$ref_rc" -ne 0 ] && ok "refresh fails when the preview is down" || bad "refresh exit 0"
printf '%s\n' "$REF" | grep -qi 'docker compose' && bad "refresh tells the user to type a command" || ok "refresh does not print a shell command"
BIN="$(mktemp -d)"
cat >"$BIN/docker" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >"$RORCC_DOCKER_LOG"
exit 0
EOF
chmod +x "$BIN/docker"
LOG="$(mktemp)"
(cd "$PRE" && RORCC_DOCKER="$BIN/docker" RORCC_DOCKER_LOG="$LOG" "$RORCC" preview restart >/dev/null) \
  && ok "restart exits 0" || bad "restart failed"
grep -q 'compose -f docker-compose.yml restart web' "$LOG" && ok "restart restarts the web service" || bad "restart args: $(cat "$LOG")"
EMPTY="$(mktemp -d)"
mkdir -p "$EMPTY/.ai/agents"
assert_exit 1 "preview without compose -> 1" -- bash -c 'cd "$1" && "$2" preview' _ "$EMPTY" "$RORCC"
rm -rf "$PRE" "$BIN" "$LOG" "$EMPTY"

printf '\n'
printf '\033[1mResult:\033[0m %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
