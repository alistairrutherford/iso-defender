# Voxel Defender — Voxatron Game Plan

An isometric, voxel-art reimagining of the arcade classic **Defender**, built in
**Voxatron** (Lexaloffle's voxel fantasy console). Ten hand-crafted levels, big
colourful particle effects, and fast pick-up-and-play arcade action.

---

## 1. Concept

- **Genre:** Isometric arcade shooter (Defender-style rescue/shoot-'em-up).
- **Pitch:** You pilot the *Vox Ranger*, a nimble hover-ship defending voxel
  colonists on a floating island world. Alien Landers descend to abduct
  colonists; if a Lander carries a colonist off the top of the map it mutates
  into a fast, aggressive Mutant. Rescue colonists mid-air by catching them and
  ferrying them back to safe pads. Clear all alien waves to finish a level.
- **Perspective:** Voxatron's native 3/4 isometric voxel view. Instead of
  Defender's horizontal wrap-around strip, each level is a looping isometric
  arena (the playfield wraps east–west, giving the classic "patrol loop" feel).
- **Tone:** Bright, saturated, toy-like. Chunky voxels, juicy explosions,
  confetti particles, cheerful chiptune audio. Fun over grit.

## 2. Core Gameplay Loop

1. Level starts: colonists are placed on the terrain, a wave of aliens spawns.
2. Player patrols the looping arena, shooting aliens and watching the
   mini-radar for abduction attempts.
3. Landers grab colonists and rise; shoot the Lander and catch the falling
   colonist for bonus points, then drop them on a safe pad.
4. Wave cleared → short breather + bonus tally → next wave.
5. All waves cleared → **level cleared** jingle, score screen, next level.
6. Lose all colonists → the level "goes hostile": remaining aliens all become
   Mutants (classic Defender rule). Survive and clear to continue.
7. Lose all lives → game over, high-score entry.

### Player abilities
- 8-way hover movement with momentum/drift (isometric).
- Rapid-fire blaster (auto-repeat, screen-directional).
- **Smart Bomb** (limited stock): clears every enemy on screen in a huge
  particle burst.
- **Hyperspace / Warp Dash** (risky): teleport to a random arena spot with a
  sparkle trail; small chance of a "rough exit" that costs shield.
- Shield bar (3 hits) + lives (3 to start, extra life every 10,000 pts).

## 3. Enemies

| Enemy      | Behaviour                                                    | Points |
|------------|--------------------------------------------------------------|--------|
| Lander     | Descends, grabs colonists, rises slowly. Basic shots.        | 150    |
| Mutant     | Fast, erratic homing; created when a Lander escapes.         | 150    |
| Bomber     | Drifts diagonally, lays stationary mine voxels.              | 250    |
| Pod        | Slow floater; splits into 4 Swarmers when shot.              | 1000   |
| Swarmer    | Tiny, fast, darting attacker.                                | 150    |
| Baiter     | Spawned if the player dawdles; very fast, harasses player.   | 200    |
| Guardian   | **Boss variants** (levels 5 & 10): large multi-part voxel     | 5000   |
|            | ships with destructible segments and pattern attacks.        |        |

Colonist rescue: catch = 500, safe delivery = 500, colonist surviving a wave = 100.

## 4. The 10 Levels

Each level = one themed arena + a fixed wave script. Every level is clearable;
clearing unlocks the next (progress saved via cartdata).

| # | Name              | Theme / palette                       | New element introduced        | Waves |
|---|-------------------|---------------------------------------|-------------------------------|-------|
| 1 | Meadow Landing    | Green hills, flowers, blue sky        | Landers only (tutorial-ish)   | 2     |
| 2 | Sunset Dunes      | Orange/pink desert, cacti             | Bombers + mines               | 2     |
| 3 | Crystal Shore     | Teal beach, glowing crystals          | Pods & Swarmers               | 3     |
| 4 | Mushroom Vale     | Purple/lime giant mushrooms           | Baiters (anti-camping timer)  | 3     |
| 5 | Sky Fortress      | Floating brass islands, clouds        | **Boss: Guardian Prime**      | 3+boss|
| 6 | Frostbite Ridge   | White/cyan ice, aurora sky            | Ice = slippery player drift   | 3     |
| 7 | Magma Basin       | Black rock, lava glow, embers         | Lava geysers (hazard)         | 4     |
| 8 | Neon Ruins        | Dark city, neon magenta/cyan          | Faster Mutant AI, night radar | 4     |
| 9 | Storm Peaks       | Grey crags, lightning storms          | Random lightning strikes      | 4     |
|10 | The Mothership    | Alien hull interior, sickly greens    | **Final boss: Overmind** +    | 5+boss|
|   |                   |                                       | all enemy types combined      |       |

Difficulty curve: enemy count, speed, and shot frequency scale per level;
colonist count drops slightly in late levels to raise the stakes.

## 5. Particle Effects (a headline feature)

Use Voxatron's built-in emitters plus scripted Lua particles for:

- **Explosions:** radial voxel-shrapnel burst + expanding ring + slow-falling
  colour-cycling sparks. Bigger multi-stage version for Pods and bosses.
- **Engine trail:** constant soft particle wake behind the player ship, colour
  shifts with speed; dash leaves a rainbow streak.
- **Weapon fire:** muzzle flash voxels + tracer glow; impacts spark on terrain.
- **Smart bomb:** full-screen white flash → outward shockwave ring →
  confetti rain of destroyed-enemy voxels.
- **Rescue sparkle:** golden sparkle fountain when catching/delivering a
  colonist; small heart puff from the colonist.
- **Abduction beam:** rising green tractor-beam particle column under Landers.
- **Ambient per-theme particles:** pollen (L1), sand wisps (L2), crystal
  glints (L3), spores (L4), clouds (L5), snowfall (L6), embers (L7), neon
  rain (L8), rain + lightning flashes (L9), energy motes (L10).
- **Juice extras:** screen shake on explosions, hit-flash on enemies,
  score-popup voxel numbers that float up and fade.

Budget rule: cap simultaneous scripted particles (~200) and recycle a particle
pool to keep 60 fps.

## 6. Presentation

- **Palette:** lean on Voxatron/PICO-8's bright 16-colour-style palette; each
  level has a 3–4 colour identity (see table above) so levels feel distinct.
- **HUD:** score, lives, shield pips, smart-bomb count, wave indicator, and a
  Defender-style **radar strip** showing colonists/aliens around the loop.
- **Menus:** attract-mode title with drifting ship + particles, level-select
  showing cleared levels, results screen with rank (C→S) per level.
- **Audio:** upbeat chiptune per world (3 tracks reused across the 10 levels),
  distinct SFX for shoot/explode/rescue/warp/smart-bomb, rising alarm sting
  when a colonist is being abducted.

## 7. Technical Plan (Voxatron specifics)

- **Engine:** Voxatron 0.3.x designer + Lua scripting (PICO-8-flavoured API).
- **Structure:** one room per level (`room 1..10`) + title room + game-over
  room; shared script objects in the item library.
- **Actors:** player ship, colonist, each enemy type, pickups, and bosses as
  library actors with Lua behaviour scripts attached.
- **World wrap:** implement east–west wrap by teleporting actors crossing the
  arena edge; camera follows player with slight look-ahead in facing direction.
- **Wave system:** data-driven wave tables per level
  (`waves[level] = {{lander=6}, {lander=6, bomber=2}, ...}`), a spawner script
  reads the table so tuning needs no code changes.
- **Persistence:** `cartdata` slot storing highest cleared level, high score,
  and per-level best rank.
- **Performance:** particle pooling, cap active enemies (~24), reuse voxel
  models via the object library, profile with `stat()` on busiest level (10).

## 8. Milestones

1. **M1 – Core feel (prototype):** one arena, player movement + shooting,
   Landers with abduction loop, wrap + radar. *Goal: "is it fun to fly?"*
2. **M2 – Full loop:** colonist rescue/delivery, lives/shield, smart bomb,
   warp, wave system, level-clear flow on 1 level.
3. **M3 – Enemy roster:** Bomber, Pod/Swarmer, Baiter, Mutant escalation rule.
4. **M4 – Content:** build all 10 arenas + wave tables + per-level hazards.
5. **M5 – Bosses:** Guardian Prime (L5) and Overmind (L10).
6. **M6 – Juice pass:** all particle effects, screen shake, score popups, SFX,
   music, attract mode.
7. **M7 – Balance & polish:** difficulty curve tuning, rank thresholds,
   save/level-select, playtest each level start-to-finish.

## 9. Definition of Done

- All 10 levels clearable start to finish without bugs at 60 fps.
- Every enemy type, both bosses, and all listed particle effects implemented.
- Progress persists between sessions; high score table works.
- A new player can clear level 1 first try; level 10 challenges a skilled one.
