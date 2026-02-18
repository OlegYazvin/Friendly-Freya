# Friendly Freya (Native GPU Build)

This project is native desktop only (`SDL2 + OpenGL`, GPU accelerated). The old browser build has been removed.

Godot 4 migration is also available in `godot/` (see `godot/README_GODOT.md`).

## Build (Linux)

```bash
cmake -S . -B build
cmake --build build -j
./build/friendly_freya
```

## Build (Windows 10/11)

Use CMake with an SDL2 package (for example via vcpkg):

```powershell
cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=C:/path/to/vcpkg/scripts/buildsystems/vcpkg.cmake
cmake --build build --config Release
.\build\Release\friendly_freya.exe
```

## Controls

- `WASD` / `Arrow Keys`: Move Freya (Up moves up on screen)
- `Shift`: Run
- `E`: Eat nearby poop
- `Space`: Vomit (only when vomit meter is full)

## Gameplay

- Eating poop lowers hunger and increases vomit.
- Social meter rises when Freya gets near other dogs and they bark at each other.
- Minimap is shown in the upper-right.
