# shellcheck shell=bash
# Stack id for the path router. Rails markers win. Does not change which units are selected.
# Membership is .ai/stacks/<id>/STANDARDS; markdown stays in .ai/standards/.
# See docs/architecture/adr-0010-stack-core.md.

# _stack_id <project-root>
_stack_id() {
  local root="$1"
  if [ -f "$root/Gemfile" ] || [ -f "$root/config/application.rb" ] || [ -f "$root/bin/rails" ]; then
    printf '%s\n' rails
    return 0
  fi
  if [ -f "$root/next.config.js" ] || [ -f "$root/next.config.mjs" ] || [ -f "$root/next.config.ts" ]; then
    printf '%s\n' nextjs
    return 0
  fi
  printf '%s\n' unspecified
}
