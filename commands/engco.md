# /engco — English coach (alias for /english-check)

Invoke the `english-check` skill via the Skill tool.

- If the user passed text after `/engco`, treat that text as the input.
- If no text was passed, use the user's previous prompt in this conversation.
- The skill itself decides between **critique mode** (English input) and **translation mode** (non-English input).
- Output **only** the footer block defined by the skill — no preamble, no closing remarks.
