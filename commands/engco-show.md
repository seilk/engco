---
description: Display the latest engco critique from ~/.claude/state/engco-last.md.
---

# /engco-show — Show the latest async English-coach critique

Read `~/.claude/state/engco-last.md` and display its contents in chat as a single short message.

- Read the file with the Read tool.
- Output **only** the file contents, exactly as written, in a `markdown` code block (so the `📝` line and field labels render clean).
- If the file does not exist or is empty, reply with one line: `No engco output yet.` Then stop.
- No preamble, no closing remarks.

For older critiques, the user can browse `~/.claude/state/engco-log.md`.
