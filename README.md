# Voxel Defender

An isometric, voxel-art reimagining of the arcade classic **Defender** for
**Voxatron** (Lexaloffle, 0.3.5b+), implemented entirely in Lua — no designer
actors required. Ten themed, individually clearable levels, six enemy types,
two multi-part bosses, and a pooled particle system doing a lot of confetti.

See [VOXATRON_DEFENDER_PLAN.md](VOXATRON_DEFENDER_PLAN.md) for the full design
and [ASSEMBLY.md](ASSEMBLY.md) for how to get it into a Voxatron cartridge.

## How to play

Defend the colonists. **Landers** descend, grab them, and haul them skyward —
if one escapes off the top, the colonist is gone and the lander becomes a fast,
angry **Mutant**. Lose every colonist and the whole level turns hostile.
Shoot a rising lander and its colonist falls: catch them mid-air, then drop
them on a yellow landing pad for bonus points. Clear every wave (and the boss,
on levels 5 and 10) to finish a level.

### Controls

| Input            | Action                                    |
|------------------|-------------------------------------------|
| d-pad            | fly (8-way, with drift)                   |
| X                | fire (in your facing direction)           |
| O                | smart bomb (clears the screen; limited)   |
| hold DOWN + O    | warp dash (random teleport — 15% rough exit) |
| menus            | arrows to move, X to confirm              |

### Scoring

Lander/Mutant/Swarmer 150 · Baiter 200 · Bomber 250 · Pod 1000 (splits into
4 swarmers!) · mine 50 · boss part 250 · Guardian 5000 · Overmind 10000 ·
colonist catch 500 · pad delivery 500 · each survivor at level clear 100.
Extra life every 10,000 points. Ranks C→S per level (S = all colonists saved,
no deaths).

## Repository layout

```
src/01_config.lua     constants, palette, all 10 level + wave tables
src/02_util.lua       wrap math, safe audio, hud text helpers, input edges
src/03_particles.lua  pooled particle system + effect recipes
src/04_entities.lua   shots, mines, colonists, pads, score popups
src/05_enemies.lua    6 enemy AIs + Guardian Prime & Overmind bosses
src/06_player.lua     the Vox Ranger: movement, weapons, damage, carrying
src/07_world.lua      terrain, per-level scenery, ambient fx, hazards
src/08_hud.lua        hud, radar strip, banners, menus & end screens
src/09_main.lua       state machine, wave director, scoring, _update/_draw
build.sh              concatenates src/ into build/voxel_defender.lua
test/headless.py      headless gameplay simulation (python3 + lupa)
```

## Developing

```sh
sh build.sh                 # produce build/voxel_defender.lua
python3 -m pip install --user lupa
python3 test/headless.py    # simulated full-campaign + soak tests
```

The headless tests stub the Voxatron API with PICO-8 math semantics and
actually play the game: menu flow, all 10 levels through to the victory
screen, hostile mode, and the game-over path.

## Known limitations

- The Voxatron 0.3.5b scripting API has no persistent-storage call, so level
  unlocks and the high score last for the play session only.
- Sounds and music are referenced by name and are optional — the game plays
  silently until you add resources with those names (list in ASSEMBLY.md).
# voxel-defender
A voxel defender clone for the Voxatron platform. See Assembly.md to load it and run it.
