# Friendly Freya Playtest Note Guide

[Documentation hub](../README.md) · [Game completion plan](GAME_COMPLETION_PLAN.md) ·
[Run guide](../RUN_FRIENDLY_FREYA.md)

**Status:** Ready for informal player feedback. The current review build passed an
exported Windows EXE start-to-credits route, and local graphical measurements
are recorded. Five unfamiliar-player tests, a measured minimum-Windows-PC
performance floor, focused accessibility, and graphical Windows
start-to-credits QA remain open.

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

For the HP, download the [review-o Windows artifact](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38794653756/artifacts/12001498322).
Extract its wrapper first. Inside, verify `Friendly-Freya-manual-15-Windows-x86_64.zip`
against the adjacent `.sha256` file (expected SHA-256
`2e6d1f4d9402694f1b82635a4be392a54a8905c782b0bd1f077fd1b12f79a5c0`),
then extract that game ZIP. The Actions artifact expires October 29, 2026.

Local alternative: `dist/Friendly-Freya-review-20261015o-Windows-x86_64.zip`
(SHA-256 `225d39a0aba03362b8436a03ab15e3742b708eabb411a799f73c1197685e1fd4`).
Verify it against its own adjacent `.sha256` file before testing. The
[review-o Windows run](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38794653756)
passed export validation, EXE startup, the short headless performance entry,
the keyboard Watch Intro opening, and an exported start-to-credits campaign.
Its [campaign log](https://github.com/OlegYazvin/Friendly-Freya/actions/runs/38794653756/artifacts/12003200905)
records three chapters, six lodge rescues, two allies, 18 claimed sites,
credits, and Keep Exploring without game errors or warnings. The local
extracted PCK also passed the press-once keyboard route.
The review evidence is tracked in
[draft PR #1](https://github.com/OlegYazvin/Friendly-Freya/pull/1).
Graphical HP checks remain open.

Use a freshly extracted Windows review ZIP with `FriendlyFreya.exe` beside its
`.pck`. Record the exact build label and SHA-256 manifest. Aim for five people
who have not played before. Let them start a new game without project documents
or control coaching; they can simply play and tell the owner what they think.
No player needs to fill out a form. If someone observes a session, the prompts
below can help them jot down useful moments; otherwise, record the comments the
players volunteer and any issue they can reproduce. Send those comments back
in whatever format is easiest; a game moment or screenshot helps locate an
issue but is optional. Note the PC's Windows version, CPU, GPU, RAM, display
size, and input device once. Test at 1280×720 or native 1920×1080, using one
size for each uninterrupted session. Run the instrumented two-resolution
performance check separately. After a blind session,
check readability briefly at 960×540 if the player is willing. Keep the game
save or a screen recording only with the player's agreement.

If several players use the same Windows account, New Game can replace its
single campaign save. Use separate Windows accounts or archive both the save
and its `.bak` before the next session when an unfinished run should be kept.

Optional observer prompts (not a player questionnaire):

| Field | Observation |
| --- | --- |
| Player ID and prior game familiarity | |
| Build, machine, display, and input device | |
| 960×540 readability and smallest acceptable window | |
| Start route: New Game: Watch Intro / New Game: Skip Intro | |
| If watching: could the player read each UFO and family line, use Next, and continue after Freya's first-exit thought? | |
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
| Did a threat or action warning remain readable with goals pinned? | |
| Could the player use keyboard `-`/`=` to zoom the camera? | |
| Could the player read the chapter guide at the tested window size? | |
| Missed prompt, wrong input, unclear marker, or stuck route | |
| Chosen protection and stronghold tactics; why | |
| Save/resume attempt; New Game, Restart, and Replay cancel/confirm clarity | |
| One moment that was fun; one that felt repetitive or unfair | |

Let the player try to recover from confusion before giving a hint. If a hint is
needed, note the point, what they tried, and the hint. Do not count a hinted
step as independently understood. Ask only natural follow-up questions if the
player is comfortable, such as what they would do next and whether they would
play another route.

## Focused Windows release checks

On the user-selected HP Victus minimum Windows PC, record Windows build, actual
hardware configuration, graphics driver, power mode, and active GPU. With the
laptop plugged in and the dedicated RTX 4060 active, run the unprofiled
full-pack stress scenario for at least 135 seconds by double-clicking `RunPerformanceQA.cmd`
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
Try the default held Space/C controls and the optional "Press once for long
actions (Space/C)" checkbox in Pause > Controls. Check that repeated actions
remain physically manageable and that pressing again, moving, losing the target,
pausing, and switching windows stop an active action. Check that text and
subtitles stay on screen
long enough to read, critical
markers and status text remain legible at both supported window sizes, including
while goals are pinned, and
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
