# Installing engco

Two paths.

## Option A — As a Claude Code plugin (recommended once published)

```bash
# inside Claude Code:
/plugin install engco@<marketplace-name>
```

The plugin auto-registers `UserPromptSubmit` and `SessionStart` hooks. Slash commands are namespaced under the plugin: `/engco:engco`, `/engco:engco-on`, etc.

## Option B — Standalone (manual install from this repo)

Use this if the plugin marketplace listing is not yet available, or you want unprefixed slash commands like `/engco-on`.

```bash
git clone https://github.com/seilk/engco.git
cd engco
bash install.sh
```

The script:

- Copies `hooks/engco_*.py` to `~/.claude/hooks/`
- Copies `commands/engco*.md` to `~/.claude/commands/`
- Copies `skills/english-check/` to `~/.claude/skills/english-check/`
- Patches `~/.claude/settings.json` to register the hooks (idempotent; backs up first)

Restart your Claude Code session.

### Uninstall

```bash
bash uninstall.sh
```

Removes files and unwires hooks. Preserves `~/.claude/state/engco-log.md` so your history survives. Wipe completely with `rm -rf ~/.claude/state/engco-*`.

## Configuration

engco needs an Anthropic credential to call the coach worker. It reads, in order:

1. `ANTHROPIC_AUTH_TOKEN` env var (gateway-style bearer token)
2. `ANTHROPIC_API_KEY` env var (direct Anthropic key)
3. `env` block of `~/.claude/settings.json` (same names)

Optional: set `ANTHROPIC_BASE_URL` if you route through a gateway. Default is `https://api.anthropic.com`.

## Verify it works

Send any English prompt longer than 10 words. After Claude finishes its response, you should see a fenced `diff` block with corrections appended at the end. If nothing appears:

```bash
# Inspect the latest engco state
ls -la ~/.claude/state/engco-*

# Read the latest critique
cat ~/.claude/state/engco-last.md

# Tail history
tail -50 ~/.claude/state/engco-log.md
```

Use `/engco-show` to pull the last critique into chat at any time. Use `/engco-off` to silence the auto coach without uninstalling.
