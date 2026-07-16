# Assembling the cartridge in Voxatron

The game is a **pure-Lua Voxatron cartridge** — everything (world, enemies,
HUD, menus) is drawn by script, so no actors, rooms full of props, or emitters
need to be built in the designer. You need Voxatron **0.3.5b or later**.

## 1. Build the combined script

```sh
sh build.sh
```

This produces `build/voxel_defender.lua` (~1,900 lines): the nine `src/`
modules concatenated in load order. You can paste modules individually
instead — the numeric filename prefixes are the required resource-tree order.

## 2. Create the cartridge

1. Open Voxatron → **Designer** → new cartridge.
2. In the resource tree, add a **script** object.
3. Open the script and paste the contents of `build/voxel_defender.lua`.
   (Or: add nine script objects named `01_config` … `09_main`, pasting each
   `src/` file — scripts run in tree order, so keep them sorted.)
4. Leave room 1 empty — the game clears and draws the whole display volume
   itself (`_init`/`_update`/`_draw` drive everything).
5. Run the cart. You should see the title screen with the drifting ship;
   press ❎ to reach level select.

## 3. Optional: audio resources

All audio is looked up **by name** and every call is `pcall`-wrapped, so the
game runs silently until you add resources with these names:

- **Sounds:** `shoot`, `eshoot`, `boom`, `bigboom`, `rescue`, `deliver`,
  `warp`, `bomb`, `mine`, `alarm`, `hurt`, `mutate`, `clear`, `ui`, `1up`
- **Music:** `title`, `music1` (levels 1–4), `music2` (5–7), `music3` (8–10),
  `jingle` (level clear), `gameover`, `victory`

Names are case-sensitive. Add them in the designer's sound/music editors and
they are picked up with no code changes.

## 4. Tuning without touching code logic

Everything designed to be tweaked lives in `src/01_config.lua`:

- `LEVELS` — names, palettes, colonist counts, hazards, and per-level wave
  tables (e.g. `{lander=6,pod=2}`); add or reorder waves freely.
- `PTS` — scoring (in units of 10 points; keep values as multiples).
- `P_*` — player feel: acceleration, friction, fire rate, shield, lives.
- `E_SPD` / `E_LIFE` / `E_RAD` — enemy speed, hit points, hitbox radius.
- `PMAX` — particle budget (220 keeps well under ~350 draw calls/frame).

After editing, re-run `sh build.sh` and `python3 test/headless.py`, then
re-paste the combined script into the cart.

## Engine notes

- The display volume is treated as 128×128×64 with **z = 0 at the top**;
  the ground surface sits at z = 50 (`GROUND_Z`).
- The scrolling world is 512 voxels around (`WRAP`) and wraps east–west,
  Defender-style; the camera leads the player's facing direction.
- The HUD, radar and menu text are drawn on the back wall using
  `set_draw_slice(y, true)` + `print`/`pset` at depths 0–1.
- `sphere()` draw behaviour changes slightly in 0.3.5c per the API notes —
  if particle sizes look off there, check `fx_*` recipes in
  `src/03_particles.lua`.
