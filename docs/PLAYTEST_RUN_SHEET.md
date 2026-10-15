# Friendly Freya Playtest Run Sheet

[Documentation hub](../README.md) · [Game completion plan](GAME_COMPLETION_PLAN.md) ·
[Run guide](../RUN_FRIENDLY_FREYA.md)

**Status:** Ready for external observation. Automated checks pass and local
graphical measurements are recorded. Five unfamiliar-player tests, a measured
minimum-Windows-PC performance floor, and Windows start-to-credits QA remain
open.

The minimum supported Windows OS, CPU, GPU, RAM, and smallest supported window
size still need to be specified before release QA. The automated 800×450
panel-bound check verifies containment; it does not establish readability or
make 800×450 a supported release size.

## Setup

Current local review package: `dist/Friendly-Freya-review-20261015f-Windows-x86_64.zip`
(SHA-256 `dd53f2f1b01df61ba2e9b3ca2c8900fcc3488133a300633a7c7b6d5a5650ad32`).
Verify it against the adjacent `.sha256` file before testing.
The extracted PCK passed a local Linux headless start-to-credits input route;
the Windows EXE has not yet passed the checks below.

Use a freshly extracted Windows review ZIP with `FriendlyFreya.exe` beside its
`.pck`. Record the exact build label and SHA-256 manifest. Each of five players
should start a new game without reading project documentation or receiving
control coaching. Ask them to think aloud. Record the PC's Windows version,
CPU, GPU, RAM, display size, and input device. Test at 1280×720 and repeat a
short UI check at 960×540. Keep the game save and a screen recording if the
player agrees.

Use the same observation sheet for every player:

| Field | Observation |
| --- | --- |
| Player ID and prior game familiarity | |
| Build, machine, display, and input device | |
| Start route: Watch Intro or Skip To Game | |
| Time to eat and leave home | |
| Time to first independent dog decision and cleanse | |
| Time to first recruited ally and pack order | |
| Time to first building claim and cleared stronghold | |
| Time to lodge rescue and chapter 1 result | |
| Time to chapters 2 and 3, credits, and return to exploration | |
| Did the H next-step guide help with ally protection and the final signal? | |
| Could the player read the G-pinned goals, scroll them, and return to play? | |
| Could the player read the chapter guide at the tested window size? | |
| Missed prompt, wrong input, unclear marker, or stuck route | |
| Chosen protection and stronghold tactics; why | |
| Save/resume attempt and result | |
| One moment that was fun; one that felt repetitive or unfair | |

Let the player try to recover from confusion before giving a hint. If a hint is
needed, note the exact point, what the player tried, and the hint. Do not count
the hinted step as independently understood. After the run, ask whether the
player could name the next useful action at each chapter transition and whether
they would want to play another route.

## Focused Windows release checks

On the proposed minimum supported Windows PC, complete a natural run from
startup through credits using keyboard controls. Test Resume Game after a
building claim, after a lodge cleanse, during chapter 2 ally protection, and
after the final result. Check that the restored dog, imp, claim, supply, and
chapter states match what the player just saw. Try both ending choices. Keep
one occupied storefront and a full active pack in view long enough to note
frame rate, input delay, memory growth, and any sound that fails to play. Open
pause with Escape, resume with Escape and the focused Enter button, then use
Page Down and Page Up in both help panels with the keyboard alone.

## Decision record

After all five observations, list the three most common friction points and
the seed or save that reproduces each technical issue. Record which routes
players chose, whether the first chapter's proposed 30–45 minute duration was
useful, and which claim/food/imp interactions felt repetitive or surprising.
Tune the required site count, travel, warning time, rewards, or wording based
on those observations. A release candidate needs a clean Windows
start-to-credits run, no known objective softlock, readable UI at the supported
sizes, and a measured floor of at least 30 FPS on the stated minimum machine.
