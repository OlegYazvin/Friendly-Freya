Friendly Freya for Windows (64-bit)
===================================

Friendly Freya is a game about a wonderful three-legged Portuguese Water Dog
protecting Ryah Diane from a covert alien invasion.

How to play
-----------
1. Extract the entire ZIP file. Do not run the game from inside the ZIP.
2. Keep FriendlyFreya.exe and FriendlyFreya.pck together in the same folder.
3. Double-click FriendlyFreya.exe.

"New Game: Watch Intro" and "New Game: Skip Intro" start a fresh campaign. If a
valid save exists, the game asks before replacing it. Resume Game continues the
saved campaign. The pause menu's Restart Story and the ending's Replay Story
actions also ask before leaving the current session. Cancel keeps the current
screen and saved progress.

Godot is not required. The included executable contains the Godot runtime.

Windows may display a SmartScreen warning because this early build is not code
signed. For a review build, obtain the ZIP and its SHA-256 checksum from the
project team and verify them before running it. For a public build, use the
official Friendly Freya GitHub Release and its published checksum.

Basic controls
--------------
WASD / Arrow keys  Move Freya
Shift              Run
Q / E              Rotate camera
- / =              Zoom out / in with the keyboard
Mouse wheel        Zoom out / in
F                  Eat, collect/give supplies, pick up a stick, train, or open safe lodge cages
V                  Drop a carried stick
C (hold)           Socialize with a nearby dog
R (hold)           Bark at a suspicious dog
Space (hold)       Claim objects/buildings or weaken an occupied building
1 / 2 / 3          Pack follows, guards a spot or nearby clean dog, or assists a named site
X                  Vomit when the meter is full; spray can interrupt imps
H                  Show or hide chapter tips
Tab (hold)         Show objectives temporarily
G                  Pin or unpin objectives
Page Up/Down       Scroll objectives and pause help
N                  Continue the story after a chapter result
Esc                Pause menu (skip during cinematics)
Space in intro     Complete the current line, then advance

The pause menu contains the current full controls and How To Play guide.

Skipping the intro starts Freya hungry near her home bowl with eat-first
guidance. Hold Tab or press G to see the highlighted sites, lodge rescue, ally,
and alien goals for the current chapter. The three-chapter campaign ends with
Gene and Zoe's return and credits. The pause menu saves the game. Resume Game
appears on the title screen when a valid save exists. Owning every building is an
optional neighborhood challenge.

Graphical performance QA
------------------------
On the nominated Windows test PC, plug in the laptop, select the dedicated GPU,
close other games, and double-click RunPerformanceQA.cmd in this folder. The
runner opens the exported game at 1280x720 windowed and 1920x1080 fullscreen.
It checks that the actual game image matches each requested size. Each run has a
15-second warm-up and at least 135 seconds of live stress, finishing the last
complete five-second FPS window. Do not minimize the
game during the sample. The runner writes a summary and both full logs to a
dated performance-qa folder beside the EXE. It reports the worst five-second
FPS window against the 30 FPS target and samples Windows process memory. The
diagnostic does not change the campaign save. Confirm the active GPU in Windows
and record power mode, graphics driver, and any visual or input problems during
a separate natural playthrough. A passing stress sample alone is not a full
gameplay or lower-hardware guarantee.
