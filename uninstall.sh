#!/usr/bin/env bash
# engco — standalone uninstaller. Removes copied files and unwires hooks.
# Leaves ~/.claude/state/engco-* in place (history). Idempotent.

set -euo pipefail

DST="${HOME}/.claude"
SETTINGS="${DST}/settings.json"
TS="$(date +%Y%m%d-%H%M%S)"

echo "→ engco uninstaller (standalone mode)"

rm -f "$DST/hooks/engco_suggest.py" \
      "$DST/hooks/engco_worker.py"  \
      "$DST/hooks/engco_status.py"

rm -f "$DST/commands/"engco*.md
rm -rf "$DST/skills/english-check"

echo "✓ files removed"

if [ -f "$SETTINGS" ] && command -v jq >/dev/null 2>&1; then
  cp "$SETTINGS" "${SETTINGS}.bak.${TS}"
  jq '
    .hooks.UserPromptSubmit |= (
      if . == null then null
      else map(select(.hooks | any(.command | test("engco_suggest\\.py")) | not))
      end
    )
    | .hooks.SessionStart |= (
      if . == null then null
      else map(select(.hooks | any(.command | test("engco_status\\.py")) | not))
      end
    )
  ' "$SETTINGS" > "${SETTINGS}.tmp" && mv "${SETTINGS}.tmp" "$SETTINGS"
  echo "✓ settings.json unwired (backup: ${SETTINGS}.bak.${TS})"
fi

echo
echo "✅ engco uninstalled."
echo "   History preserved at ~/.claude/state/engco-log.md"
echo "   Remove with: rm -rf ~/.claude/state/engco-*"
