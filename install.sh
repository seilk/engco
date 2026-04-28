#!/usr/bin/env bash
# engco — manual standalone installer
# Copies hooks, commands, and the english-check skill into ~/.claude/, and
# patches ~/.claude/settings.json to register the hooks. Idempotent.
#
# For plugin-based install, use: /plugin install engco@<marketplace>
# from inside Claude Code instead. This script is the no-marketplace fallback.

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DST="${HOME}/.claude"
SETTINGS="${DST}/settings.json"
TS="$(date +%Y%m%d-%H%M%S)"

echo "→ engco installer (standalone mode)"
echo "  source: $SRC"
echo "  target: $DST"
echo

mkdir -p "$DST/hooks" "$DST/commands" "$DST/skills/english-check" "$DST/state"

cp "$SRC/hooks/engco_suggest.py" "$DST/hooks/"
cp "$SRC/hooks/engco_worker.py"  "$DST/hooks/"
cp "$SRC/hooks/engco_status.py"  "$DST/hooks/"
chmod +x "$DST/hooks/engco_"*.py

cp "$SRC/commands/"engco*.md "$DST/commands/"

cp "$SRC/skills/english-check/SKILL.md" "$DST/skills/english-check/"

echo "✓ files copied"

if ! command -v jq >/dev/null 2>&1; then
  cat <<EOF
⚠️  'jq' not found. Skipping settings.json auto-merge.
   Add the hook blocks from settings.template.json into ~/.claude/settings.json manually.
EOF
  exit 0
fi

if [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "${SETTINGS}.bak.${TS}"
  echo "✓ backed up existing settings: ${SETTINGS}.bak.${TS}"
else
  echo '{}' > "$SETTINGS"
fi

# Build the hook entries we need to ensure exist.
SUGGEST_CMD="python3 ${DST}/hooks/engco_suggest.py"
STATUS_CMD="python3 ${DST}/hooks/engco_status.py"

# Idempotently add UserPromptSubmit and SessionStart engco entries.
jq --arg sc "$SUGGEST_CMD" --arg st "$STATUS_CMD" '
  .hooks //= {}
  | .hooks.UserPromptSubmit //= []
  | .hooks.SessionStart //= []
  | (
      if [.hooks.UserPromptSubmit[]? | .hooks[]? | select(.command == $sc)] | length == 0
      then .hooks.UserPromptSubmit += [
        {"matcher": "", "hooks": [{"type": "command", "command": $sc}]}
      ]
      else . end
    )
  | (
      if [.hooks.SessionStart[]? | .hooks[]? | select(.command == $st)] | length == 0
      then .hooks.SessionStart += [
        {"matcher": "*", "hooks": [{"type": "command", "command": $st}]}
      ]
      else . end
    )
' "$SETTINGS" > "${SETTINGS}.tmp" && mv "${SETTINGS}.tmp" "$SETTINGS"

echo "✓ settings.json patched"
echo

# Sanity checks
if ! command -v python3 >/dev/null 2>&1; then
  echo "⚠️  'python3' not on PATH — engco hooks won't run until you install it."
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "⚠️  'claude' CLI not on PATH — install Claude Code first."
fi

if [ -z "${ANTHROPIC_AUTH_TOKEN:-}" ] && [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  if ! grep -q -E 'ANTHROPIC_(AUTH_TOKEN|API_KEY)' "$SETTINGS" 2>/dev/null; then
    echo "⚠️  No ANTHROPIC_AUTH_TOKEN or ANTHROPIC_API_KEY found in env or settings.json."
    echo "    engco needs one to call the coach API."
  fi
fi

echo
echo "✅ engco installed (standalone)."
echo "   Start a new Claude Code session to activate."
echo "   Toggle anytime with /engco-on  /engco-off"
