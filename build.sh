#!/bin/sh
# concatenate the src modules (in load order) into one paste-ready script
cd "$(dirname "$0")"
mkdir -p build
cat src/01_config.lua src/02_util.lua src/03_particles.lua \
    src/04_entities.lua src/05_enemies.lua src/06_player.lua \
    src/07_world.lua src/08_hud.lua src/09_main.lua \
    > build/voxel_defender.lua
echo "built build/voxel_defender.lua ($(wc -l < build/voxel_defender.lua | tr -d ' ') lines)"
