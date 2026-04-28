#!/usr/bin/env python3
"""
UserPromptSubmit hook — engco (defer-bash design, bilingual).

Brilliant solution to the sync-vs-async dilemma:

  - Hook returns INSTANTLY (no API call here, just spawns worker).
  - Worker runs in parallel with the assistant's response (~1.2s API call).
  - Hook injects an instruction telling the assistant to, AFTER finishing
    its main answer, run a Bash one-liner that waits for the worker's
    result and prints it. The assistant renders that as the final block.

Net effect:
  - 0s perceived wait (hook is fire-and-forget).
  - Critique matches the CURRENT prompt (worker was given current input).
  - Block appears at the END of the response (preferred UX).
  - The Bash wait is usually free (worker finishes during model streaming).
  - Worst case: brief tool-call wait (~0–500ms) visible in TUI.

Skips silently when:
  - empty / starts with "/" / contains [noeng] / contains ``` (code-heavy)
  - too short (<6 words AND <20 chars)
  - toggled off via /engco-off
"""
import json
import os
import pathlib
import subprocess
import sys

MIN_WORDS = 6
MIN_CHARS = 20

# Sibling worker — resolves correctly under both standalone (~/.claude/hooks/)
# and plugin (${CLAUDE_PLUGIN_ROOT}/hooks/) installations.
WORKER = str(pathlib.Path(__file__).resolve().parent / "engco_worker.py")
OFF_MARKER = os.path.expanduser("~/.claude/state/engco.off")

# Bash one-liner the assistant runs at the END of its response.
# Polls for the pending flag (set when worker completes) up to 5s, then
# prints the critique and consumes the flag. If timed out, prints nothing.
BASH_RETRIEVE = (
    "for i in $(seq 1 50); do "
    "[ -f ~/.claude/state/engco-pending.flag ] && break; "
    "sleep 0.1; "
    "done; "
    "if [ -f ~/.claude/state/engco-pending.flag ]; then "
    "cat ~/.claude/state/engco-last.md; "
    "rm -f ~/.claude/state/engco-pending.flag; "
    "fi"
)


def is_off() -> bool:
    return os.path.exists(OFF_MARKER)


def should_critique(prompt: str) -> bool:
    if not prompt:
        return False
    if prompt.startswith("/"):
        return False
    if "[noeng]" in prompt:
        return False
    if "```" in prompt:
        return False
    if len(prompt.split()) < MIN_WORDS and len(prompt) < MIN_CHARS:
        return False
    return True


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        sys.exit(0)

    if is_off():
        sys.exit(0)

    prompt = (data.get("prompt") or "").strip()
    if not should_critique(prompt):
        sys.exit(0)

    # Fire the worker for the CURRENT prompt. It runs in parallel with the
    # model's response generation.
    try:
        subprocess.Popen(
            ["python3", WORKER, prompt],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL,
            start_new_session=True,
            env=os.environ.copy(),
        )
    except Exception:
        sys.exit(0)

    instruction = (
        "[engco] An async English-coach worker is running in parallel for the "
        "user's CURRENT prompt. After fully answering the user's question, append "
        "an English-coach footer:\n\n"
        "1. Finish your main answer normally and completely.\n"
        "2. Add a horizontal rule (---).\n"
        "3. Run this exact Bash command to retrieve the worker's result:\n\n"
        f"```bash\n{BASH_RETRIEVE}\n```\n\n"
        "4. Paste the bash output VERBATIM at the end of your response. "
        "DO NOT wrap it in another code fence — it is already formatted as rich "
        "markdown (with internal ```diff blocks, bold, and bullet lists) and must "
        "render as markdown, not as a code block. The output must be the very "
        "last content in your response.\n"
        "5. If the bash output is empty (worker timed out), silently skip step 4.\n\n"
        "The worker typically finishes during your response streaming (~1.2s), so "
        "the bash wait is usually instant. The footer matches the user's CURRENT "
        "prompt — no lag, no confusion."
    )
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": instruction,
        }
    }))


if __name__ == "__main__":
    main()
