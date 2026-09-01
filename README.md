# Friendly Freya

Friendly Freya is a Godot 4 neighborhood game about a Portuguese Water Dog
protecting Ryah Diane from a covert alien invasion. The current project includes
the startup menu, two-part intro, procedural neighborhood, dog socialization and
possession systems, scent claims, occupied buildings, and deterministic visual
regression views.

## Start Here

1. Read [AGENTS.md](AGENTS.md) before changing the project. It contains the
   repository-wide working rules and non-negotiable audio policy.
2. Use [RUN_FRIENDLY_FREYA.md](RUN_FRIENDLY_FREYA.md) to launch, stop, validate,
   or capture the game in the current environment.
3. Use [the codebase map](docs/CODEBASE_MAP.md) to find the owning scene, script,
   data file, validation hook, or regression view for a system.
4. Read [the Godot overview](godot/README_GODOT.md) for controls and a concise
   description of implemented gameplay.

## Documentation Map

| Document | Use it for | Status |
| --- | --- | --- |
| [Agent instructions](AGENTS.md) | Mandatory repository rules, source-of-truth order, and required checks | Active instructions |
| [Run and validation guide](RUN_FRIENDLY_FREYA.md) | Launching Godot, checking the process, testing, captures, and troubleshooting | Current operations |
| [Codebase map](docs/CODEBASE_MAP.md) | Runtime flow, file ownership, subsystem entry points, and test environment variables | Current architecture |
| [Godot overview](godot/README_GODOT.md) | Controls and implemented gameplay at a glance | Current product reference |
| [Gameplay audit and direction](GAMEPLAY_AUDIT.md) | Canonical gameplay rules, implementation status, and explicitly future work | Living design document |
| [Intro cut-scene guide](INTRO_CUTSCENE.md) | Exact UFO/family timelines, edit surfaces, handoff rules, and intro checks | Current subsystem reference |
| [Dog breed definitions](godot/BREEDS.md) | Breed schema, shared-rig policy, and army-collar rules | Current subsystem reference |
| [Visual implementation record](VISUAL_RECOMMENDATIONS.md) | Completed visual audit recommendations and their validation expectations | Completed implementation record |
| [Visual regression catalog](visual_regressions/README.md) | What each deterministic PNG documents and how to regenerate it | Current capture reference |
| [Model inventory and policy](godot/assets/models/README_MODELS.md) | Active/inactive model status, shared-dog rules, and provenance gaps | Current asset/release record |
| [Audio attribution](godot/assets/audio/ATTRIBUTION.md) | Audio provenance, licenses, derived files, and exact intro mappings | Current legal/source record |
| [Original visual change request](New%20changes.md) | The historical request that led to the home/storefront/suburban visual pass | Historical record |
| [Windows artifacts](Logs%20and%20Monitoring/README.md) | Why packaged copies exist and why they are not source documentation | Artifact note |

## Source-of-Truth Order

When two references appear to disagree, use this order:

1. [AGENTS.md](AGENTS.md) for mandatory working constraints.
2. Runtime code, scene files, assets, and executable validation for current
   behavior.
3. Current subsystem references such as the intro, breed, asset, and regression
   documents.
4. [GAMEPLAY_AUDIT.md](GAMEPLAY_AUDIT.md) for intended design, using its
   `Implemented` and `Future` labels literally.
5. Completed audits, historical requests, and packaged Windows copies for
   context only.

If code and a current reference diverge, verify the behavior and update the
reference in the same change.

## Quick Commands

From the repository root:

```sh
# Launch in this Codex/Linux environment.
host-spawn flatpak run org.godotengine.Godot --path "$PWD/godot"

# Run startup, intro, smoke, targeted gameplay, and family-intro checks.
./scripts/predeploy_size_checks.sh

# Regenerate deterministic gameplay/world captures.
./scripts/capture_visual_regressions.sh

# Regenerate startup and intro captures.
./scripts/capture_intro_regressions.sh
```

Capture scripts require the host X11 tools described in the
[run guide](RUN_FRIENDLY_FREYA.md#visual-regression-captures), and no Godot
process may already be running.

## Repository Layout

```text
godot/                  Godot project, scenes, scripts, and runtime assets
scripts/                Validation and deterministic capture entry points
visual_regressions/     Checked-in reference PNGs and their catalog
docs/                   Cross-system architecture documentation
Logs and Monitoring/    Packaged Windows snapshots; not authoritative source
```

## Release Readiness

No reproducible release/export command is currently checked in. Existing
Windows bundles are historical, and distributed model provenance/licenses are
not yet documented. See the [run guide](RUN_FRIENDLY_FREYA.md#release-and-export-status)
and [model inventory](godot/assets/models/README_MODELS.md#provenance-and-release-blocker)
before packaging or distributing the project.

## Documentation Maintenance

- Keep this page as the central index; link new durable Markdown from the table.
- Put mandatory agent behavior in `AGENTS.md`, not in an ordinary reference.
- Label statements as current, planned, or historical when a file contains more
  than one kind of information.
- Prefer relative Markdown links and stable symbol/file names over fragile line
  numbers.
- Update the relevant reference and regression catalog whenever behavior or a
  deterministic capture changes.
- Do not treat Markdown inside packaged artifacts as current project guidance.
