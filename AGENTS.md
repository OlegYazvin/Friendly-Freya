# Friendly Freya Agent Instructions

These instructions apply to the entire repository. Start with the
[documentation hub](README.md), then use the [codebase map](docs/CODEBASE_MAP.md)
and [run guide](RUN_FRIENDLY_FREYA.md) instead of rediscovering entry points.

## Source of Truth

- Runtime code, scenes, assets, and executable checks define current behavior.
- Only the top-level `godot/` directory is editable project source. Artifact
  payloads below `Logs and Monitoring/`, plus packaged `.exe`, `.pck`, and
  archive files, are historical unless an explicit packaging task says
  otherwise; that directory's current `README.md` and scoped `AGENTS.md` are the
  guardrails for those payloads.
- [GAMEPLAY_AUDIT.md](GAMEPLAY_AUDIT.md) mixes implemented behavior with future
  design; honor its status labels and do not present future items as shipped.
- Preserve unrelated work in the dirty worktree. Do not revert or overwrite
  changes merely because they are outside the current task.

## Required Workflow

- Run `./scripts/predeploy_size_checks.sh` after gameplay, scene, timeline,
  startup, or validation changes.
- For visual changes, regenerate the affected deterministic PNGs with the
  capture command in [visual_regressions/README.md](visual_regressions/README.md)
  and inspect the rendered result.
- Capture scripts require the running Godot instance to be closed first.
- Keep current documentation synchronized with behavior. Add durable Markdown
  to the table in [README.md](README.md) and use relative links.

## Audio Policy (Non-Negotiable)

- Never synthesize, procedurally generate, or substitute fallback audio for any
  gameplay sound.
- If a requested sound file or stream is missing or fails to load or play, do
  not play any replacement.
- Missing sound must result in silence, not fallback audio.
- Preserve source and license details in
  [godot/assets/audio/ATTRIBUTION.md](godot/assets/audio/ATTRIBUTION.md) whenever
  audio assets or mappings change.

## Focused References

- Intro work: [INTRO_CUTSCENE.md](INTRO_CUTSCENE.md)
- Dog/breed work: [godot/BREEDS.md](godot/BREEDS.md)
- Models: [godot/assets/models/README_MODELS.md](godot/assets/models/README_MODELS.md)
- Visual baselines: [visual_regressions/README.md](visual_regressions/README.md)

This root-plus-nested instruction layout follows
[OpenAI's AGENTS.md guidance](https://learn.chatgpt.com/docs/agent-configuration/agents-md).
