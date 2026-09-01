# Windows Artifacts and Snapshots

[Back to the project documentation hub](../README.md)

This directory contains packaged Windows builds and an extracted copy of an
older package. It is retained for artifact inspection and comparison only.

- `FriendlyFreya_Windows/` is a packaged snapshot, not the source tree.
- `FriendlyFreya_Windows_Godot.zip` and
  `FriendlyFreya_Windows_Standalone.zip` are build artifacts.
- Markdown inside the packaged snapshot records the package as it existed when
  exported and is intentionally not part of the current documentation set.

Make source, documentation, and asset changes in the repository root and
`godot/`. A reproducible export workflow is not currently checked in; establish
and document one before replacing these artifacts. Do not copy stale packaged
scripts or Markdown back into the source project or distribute these bundles as
current builds.
