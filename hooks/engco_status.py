#!/usr/bin/env python3
"""
SessionStart hook — engco status banner.

Shows whether the auto English coach is currently ON or OFF when a new
Claude Code session starts. Output goes into the session as additionalContext,
which the harness renders as a system-reminder in the conversation.

Reads ~/.claude/state/engco.off as the toggle marker.
"""
import json
import os
import sys

OFF_MARKER = os.path.expanduser("~/.claude/state/engco.off")

if os.path.exists(OFF_MARKER):
    msg = (
        "🔕 engco auto-coach is OFF. "
        "Type /engco-on to re-enable async English critique on every prompt. "
        "Manual /engco still works."
    )
else:
    msg = (
        "🔔 engco auto-coach is ON. "
        "English prompts (≥10 words, no /, no Korean, no code blocks) trigger an async critique in the background. "
        "/engco-show pulls the latest. /engco-off silences it."
    )

output = {
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": msg,
    }
}
print(json.dumps(output))
sys.exit(0)
