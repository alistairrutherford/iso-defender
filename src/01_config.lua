-- voxel defender : 01_config
-- constants, palette, level + wave data
-- numbers stay < 32767 (pico-8 style 16.16 fixed point)

-- world -------------------------------------------------------
WRAP     = 512          -- looping arena width (world x wraps)
GROUND_Z = 50           -- voxel z of the ground surface (z=0 is TOP)
Y_MIN    = 14           -- playfield depth band (screen y)
Y_MAX    = 118
ALT_MAX  = 40           -- max flying altitude above ground
HOVER    = 12           -- player hover altitude
SCR_W    = 128

-- buttons (voxatron: 0..5 = left right up down x o) -----------
B_L=0 B_R=1 B_U=2 B_D=3 B_FIRE=4 B_BOMB=5

-- pico-8 palette indices --------------------------------------
C_BLK=0 C_DBLU=1 C_PUR=2 C_DGRN=3 C_BRN=4 C_DGRY=5 C_GRY=6 C_WHT=7
C_RED=8 C_ORG=9 C_YEL=10 C_GRN=11 C_BLU=12 C_IND=13 C_PNK=14 C_PCH=15

-- scoring (units of 10 points: 15 == 150 pts) -----------------
PTS={lander=15,mutant=15,bomber=25,pod=100,swarmer=15,baiter=20,
     mine=5,guardian=500,overmind=1000,
     catch=50,deliver=50,survive=10}
EXTRA_LIFE_EVERY=1000   -- score units (== 10,000 points)

-- player tuning ------------------------------------------------
P_ACC=0.22 P_FRIC=0.88 P_ICE_FRIC=0.965 P_MAXSPD=2.6
P_FIRE_CD=5             -- frames between shots
P_SHOT_SPD=6 P_SHOT_LIFE=26
START_LIVES=3 START_BOMBS=3 SHIELD_MAX=3
RESPAWN_T=60 INVULN_T=75
CARRY_MAX=3

-- enemy base speeds (scaled by level.spd) ----------------------
E_SPD={lander=0.55,mutant=1.5,bomber=0.7,pod=0.35,swarmer=1.9,baiter=2.3}
E_LIFE={lander=1,mutant=1,bomber=2,pod=2,swarmer=1,baiter=2}
E_RAD={lander=4,mutant=4,bomber=5,pod=5,swarmer=2,baiter=4}

BAITER_AFTER=45*30      -- frames of wave time before baiters appear
BAITER_EVERY=15*30

PMAX=220                -- particle pool size
EMAX=24                 -- max live enemies

-- level table ---------------------------------------------------
-- cols = {ground, ground2, feat1, feat2, glow}
-- amb  = ambient particle style, haz = level hazard
LEVELS={
 {name="meadow landing", cols={C_GRN,C_DGRN,C_PNK,C_YEL,C_WHT},
  amb="pollen", haz="none", colonists=8, spd=1,
  waves={{lander=4},{lander=6}}},

 {name="sunset dunes", cols={C_ORG,C_BRN,C_PCH,C_DGRN,C_YEL},
  amb="sand", haz="none", colonists=8, spd=1.05,
  waves={{lander=4,bomber=1},{lander=5,bomber=2}}},

 {name="crystal shore", cols={C_BLU,C_DBLU,C_WHT,C_PNK,C_GRY},
  amb="glint", haz="none", colonists=7, spd=1.1,
  waves={{lander=4,pod=1},{lander=5,bomber=1,pod=1},{lander=6,pod=2}}},

 {name="mushroom vale", cols={C_PUR,C_DBLU,C_PNK,C_GRN,C_YEL},
  amb="spore", haz="none", colonists=7, spd=1.15,
  waves={{lander=5,pod=1},{lander=5,bomber=2,pod=1},
         {lander=6,pod=2,bomber=1}}},

 {name="sky fortress", cols={C_ORG,C_BRN,C_YEL,C_GRY,C_WHT},
  amb="cloud", haz="none", colonists=6, spd=1.2, boss="guardian",
  waves={{lander=5,bomber=2},{lander=6,pod=2},
         {lander=6,bomber=2,pod=2}}},

 {name="frostbite ridge", cols={C_WHT,C_GRY,C_BLU,C_PNK,C_YEL},
  amb="snow", haz="ice", colonists=6, spd=1.25,
  waves={{lander=6,pod=1},{lander=6,bomber=2,pod=1},
         {lander=7,pod=2,bomber=2}}},

 {name="magma basin", cols={C_DGRY,C_BLK,C_RED,C_ORG,C_YEL},
  amb="ember", haz="geyser", colonists=6, spd=1.3,
  waves={{lander=5,bomber=2},{lander=6,pod=1,bomber=2},
         {lander=6,pod=2,swarmer=2},{lander=7,pod=2,bomber=2}}},

 {name="neon ruins", cols={C_DBLU,C_BLK,C_PNK,C_BLU,C_GRN},
  amb="neon", haz="dark", colonists=5, spd=1.4,
  waves={{lander=5,mutant=1},{lander=6,mutant=2,bomber=2},
         {lander=6,pod=2,mutant=2},{lander=7,pod=2,bomber=2,mutant=3}}},

 {name="storm peaks", cols={C_GRY,C_DGRY,C_DBLU,C_YEL,C_WHT},
  amb="rain", haz="lightning", colonists=5, spd=1.5,
  waves={{lander=6,bomber=2},{lander=6,pod=2,mutant=2},
         {lander=7,bomber=3,pod=1},{lander=7,pod=2,mutant=3,bomber=2}}},

 {name="the mothership", cols={C_DGRN,C_BLK,C_GRN,C_PUR,C_YEL},
  amb="mote", haz="none", colonists=4, spd=1.6, boss="overmind",
  waves={{lander=6,mutant=2},{lander=6,bomber=3,pod=1},
         {lander=7,pod=2,swarmer=4,mutant=2},{lander=7,bomber=3,pod=2,mutant=3},
         {lander=8,pod=3,bomber=2,mutant=4}}},
}
