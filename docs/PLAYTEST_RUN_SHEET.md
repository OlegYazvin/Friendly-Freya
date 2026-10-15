# Friendly Freya Playtest Run Sheet

[Documentation hub](../README.md) · [Game completion plan](GAME_COMPLETION_PLAN.md) ·
[Run guide](../RUN_FRIENDLY_FREYA.md)

**Status:** Ready for external observation. An earlier exported Windows EXE
start-to-credits route passed, and local graphical measurements are recorded.
The current review build still needs a passing Windows route. Five
unfamiliar-player tests, a measured minimum-Windows-PC performance floor, and
graphical Windows start-to-credits QA remain open.

The user-selected minimum Windows test PC is the HP Victus 16-r0073cl (HP
product 7N4X6UA#ABA). Its factory configuration is Windows 11 Home,
Core i7-13700HX, GeForce RTX 4060 Laptop GPU with 8 GB video memory, 32 GB
RAM, and a 16.1-inch 1920×1080 display. These are the
[HP model listing](https://support.hp.com/us-en/product/details/victus-by-hp-16.1-inch-gaming-laptop-pc-16-r0000/model/2101566991?sku=7N4X6UA)
and [HP-authored specification sheet](https://cdn.cs.1worldsync.com/syndication/mediaserverredirect/57144c439c7c79835145a69032b43a53/original.pdf)
for the factory SKU; confirm the actual PC's installed OS, CPU, GPU, RAM, and
display before recording a result. This is the stated test target, not a
performance result or evidence for lower-spec PCs. Use 1280×720 as the
candidate smallest supported window and test native 1920×1080 as well. Check
960×540 for readability before deciding whether to support it. The automated
800×450 panel-bound check verifies containment only.

## Setup

Current local review package: `dist/Friendly-Freya-review-20261015k-Windows-x86_64.zip`
(SHA-256 `dbc9068cbf4bcf482edd8f0d0a8c3487136d375b3e1e448c0113ae8d6b20b798`).
Verify it against the adjacent `.sha256` file before testing.
The extracted review-k PCK passed a short headless performance-entry check
and a warmed graphical 1280×720 sample on Linux. A source live-input route
at the same controller commit reached chapter 2 with two protected allies and
five claimed sites. The earlier review-f PCK passed a local Linux input route
through credits; the earlier
[Windows review run](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38752479431)
passed its automated headless campaign route. Check the
[review-k Windows Actions run](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38771032897)
on [draft PR #1](https://github.com/OlegYazvin/Friendly-Freya/pull/1)
before using this package for player tests. Graphical manual checks remain open.

Use a freshly extracted Windows review ZIP with `FriendlyFreya.exe` beside its
`.pck`. Record the exact build label and SHA-256 manifest. Each of five players
should start a new game without reading project documentation or receiving
control coaching. Ask them to think aloud. Record the PC's Windows version,
CPU, GPU, RAM, display size, and input device. Test the target PC at 1280×720
or its native 1920×1080, using one recorded size for each uninterrupted blind
session. Do the instrumented two-resolution performance run separately. After
the blind session, repeat a short UI readability check at 960×540. Keep the
game save and a screen recording if the player agrees.

Use the same observation sheet for every player:

| Field | Observation |
| --- | --- |
| Player ID and prior game familiarity | |
| Build, machine, display, and input device | |
| 960×540 readability and smallest acceptable window | |
| Start route: New Game: Watch Intro / New Game: Skip Intro | |
| Time to eat and leave home | |
| Time to first independent dog decision and cleanse | |
| Time to first recruited ally and pack order | |
| Did key 3 name a useful nearby Pack Assist target? | |
| Could key 2 guard a nearby independent clean dog? | |
| Time to first building claim and cleared stronghold | |
| Time to lodge rescue and chapter 1 result | |
| Time to chapters 2 and 3, credits, and return to exploration | |
| Did the H next-step guide help with ally protection and the final signal? | |
| If encountered: after owning the final site, could the player find and guard its clean signal with an ally? | |
| Could the player read the G-pinned goals, scroll them, and return to play? | |
| Could the player read the chapter guide at the tested window size? | |
| Missed prompt, wrong input, unclear marker, or stuck route | |
| Chosen protection and stronghold tactics; why | |
| Save/resume attempt; New Game, Restart, and Replay cancel/confirm clarity | |
| One moment that was fun; one that felt repetitive or unfair | |

Let the player try to recover from confusion before giving a hint. If a hint is
needed, note the exact point, what the player tried, and the hint. Do not count
the hinted step as independently understood. After the run, ask whether the
player could name the next useful action at each chapter transition and whether
they would want to play another route.

## Focused Windows release checks

On the user-selected HP Victus minimum Windows PC, record Windows build, actual
hardware configuration, graphics driver, power mode, and active GPU. With the
laptop plugged in and the dedicated RTX 4060 active, run the unprofiled
135-second full-pack stress scenario by double-clicking `RunPerformanceQA.cmd`
from the extracted review ZIP, as described in the
[run guide](../RUN_FRIENDLY_FREYA.md#sustained-graphical-stress-sample). Keep
the dated summary and full logs. The runner measures each size separately and
samples process memory; confirm the dedicated GPU is active and record any
visible or input issue during a separate natural playthrough:

| Window | Average FPS | Worst five-second FPS | p95 / p99 frame time | Peak memory | Notes |
| --- | --- | --- | --- | --- | --- |
| 1280×720 | | | | | |
| 1920×1080 | | | | | |

Separately, complete a graphical, natural run of the exported EXE from startup
through credits using keyboard controls. Record the game window size. Test
Resume Game after a building claim, after a lodge cleanse, during chapter 2
ally protection, and after the final result. Check that the restored dog, imp,
claim, supply, and chapter states match what the player just saw. Try both
ending choices. Keep one occupied storefront and a full active pack in view
long enough to note frame rate, input delay, memory growth, and any sound that
fails to play. Open pause with Escape, resume with Escape and the focused Enter
button, then use Page Down and Page Up in both help panels with the keyboard
alone.

On a separate QA save copy, verify that New Game, pause Restart Story, and
ending Replay Story leave the existing save intact when canceled. Inject a
future-version primary save and, separately, a future-version backup only in
that disposable QA copy; each must show its archive notice and block a route
that cannot save. Never use a playtester’s sole campaign save for this check.

In a focused accessibility pass, finish a chapter using the keyboard alone.
Check that sustained scent holds and repeated actions remain physically
manageable, text and subtitles stay on screen long enough to read, critical
markers and status text remain legible at both supported window sizes, and
every audio cue needed for progress also has a visible or textual cue. Record
each barrier, the setting or design change needed, and a repeat result. In a
separate prepared chapter-3 save, own the final signal site before assigning a
guard, then verify the guide names the clean signal and guarding it completes
the chapter.

## Decision record

After all five observations, list the three most common friction points and
the seed or save that reproduces each technical issue. Record which routes
players chose, whether the first chapter's proposed 30–45 minute duration was
useful, and which claim/food/imp interactions felt repetitive or surprising.
Tune the required site count, travel, warning time, rewards, or wording based
on those observations. A release candidate needs a clean Windows
start-to-credits run, no known objective softlock, a completed accessibility
pass, readable UI at the supported sizes, a measured floor of at least 30 FPS
on the stated minimum machine, and resolved severe or common playtest friction.
