# /engco-on — Re-enable the auto English coach

Run this Bash command exactly once, then report the result in one short line:

```bash
mkdir -p ~/.claude/state && rm -f ~/.claude/state/engco.off && echo "🔔 engco auto-coach is ON. English prompts (≥10 words, no /, no Korean, no code blocks) trigger an async critique in the background. /engco-show pulls the latest. /engco-off silences it."
```

That's it. No preamble, no closing remarks, no extra explanation.
