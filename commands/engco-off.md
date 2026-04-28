# /engco-off — Disable the auto English coach

Run this Bash command exactly once, then report the result in one short line:

```bash
mkdir -p ~/.claude/state && touch ~/.claude/state/engco.off && echo "🔕 engco auto-coach is OFF. Type /engco-on to re-enable async English critique on every prompt. Manual /engco still works."
```

That's it. No preamble, no closing remarks, no extra explanation.
