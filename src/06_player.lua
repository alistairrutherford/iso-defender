-- voxel defender : 06_player
-- the vox ranger: movement, firing, smart bomb, warp, damage, carrying

player={}

function player_init()
 player={
  x=64,y=64,alt=HOVER,dx=0,dy=0,
  facing=0, -- angle 0..1, 0=east
  fire_cd=0, shield=SHIELD_MAX, lives=START_LIVES, bombs=START_BOMBS,
  dead_t=0, invuln=0, bob=rnd(1), boost=0,
 }
end

function player_targetable()
 return player.dead_t<=0 and player.invuln<=0
end

function player_alive() return player.dead_t<=0 end

function carried_count()
 local n=0
 for c in all(colonists) do
  if c.state=="carried" then n=n+1 end
 end
 return n
end

local function drop_carried_at_pad()
 for c in all(colonists) do
  if c.state=="carried" then
   c.state="ground" c.alt=0 c.carry_slot=nil
   fx_sparkle(c.x,c.y,2) fx_heart(c.x,c.y,4)
   award(PTS.deliver,c.x,c.y,10)
   sfx_safe("deliver")
  end
 end
end

local function scatter_carried()
 for c in all(colonists) do
  if c.state=="carried" then
   c.state="falling" c.dalt=0 c.fall_from=c.alt c.carry_slot=nil
  end
 end
end

function player_hit(dmg)
 if not player_targetable() then return end
 player.shield=player.shield-(dmg or 1)
 shake=max(shake,4)
 sfx_safe("hurt")
 if player.shield<=0 then
  -- ship destroyed
  fx_explosion(player.x,player.y,player.alt,26,{C_WHT,C_YEL,C_ORG,C_RED},true)
  fx_confetti(player.x,player.y,player.alt)
  sfx_safe("bigboom")
  scatter_carried()
  player.lives=player.lives-1
  player.dead_t=RESPAWN_T
 else
  player.invuln=30
  fx_explosion(player.x,player.y,player.alt,8,{C_WHT,C_BLU},false)
 end
end

local function do_smartbomb()
 if player.bombs<=0 then return end
 player.bombs=player.bombs-1
 fx_smartbomb(player.x,player.y,player.alt)
 sfx_safe("bomb")
 -- destroy every on-screen enemy, mine and shot
 for i=#enemies,1,-1 do
  local e=enemies[i]
  local sx=to_screen(e.x)
  if sx then
   if e.kind=="guardian" or e.kind=="overmind" then
    enemy_damage(e,nil) -- bosses just take a tick of core damage
   else
    enemy_kill(e,true)  -- quiet: pods don't split under a smart bomb
   end
  end
 end
 for i=#mines,1,-1 do
  local m=mines[i]
  if to_screen(m.x) then
   fx_explosion(m.x,m.y,m.alt,6,{C_YEL,C_ORG},false)
   del(mines,m)
  end
 end
 for i=#eshots,1,-1 do
  if to_screen(eshots[i].x) then del(eshots,eshots[i]) end
 end
end

local function do_warp()
 fx_warp(player.x,player.y,player.alt)
 player.x=wrapx(rnd(WRAP))
 player.y=Y_MIN+10+rnd(Y_MAX-Y_MIN-20)
 player.dx=0 player.dy=0
 fx_warp(player.x,player.y,player.alt)
 sfx_safe("warp")
 if rnd(1)<0.15 then
  player.invuln=0
  player_hit(1) -- rough exit!
 else
  player.invuln=20
 end
end

function player_update()
 -- dead: wait then respawn
 if player.dead_t>0 then
  player.dead_t=player.dead_t-1
  if player.dead_t==0 then
   if player.lives<0 then return end
   player.shield=SHIELD_MAX
   player.invuln=INVULN_T
   player.x=wrapx(cam_x+64) player.y=64
   player.dx=0 player.dy=0
   fx_warp(player.x,player.y,player.alt)
   sfx_safe("warp")
  end
  return
 end
 player.invuln=max(0,player.invuln-1)
 player.bob=(player.bob+0.01)%1
 player.boost=max(0,player.boost-1)

 -- steering
 local ax,ay=0,0
 if btnh(B_L) then ax=ax-1 end
 if btnh(B_R) then ax=ax+1 end
 if btnh(B_U) then ay=ay-1 end
 if btnh(B_D) then ay=ay+1 end
 local fric=(level.haz=="ice") and P_ICE_FRIC or P_FRIC
 player.dx=(player.dx+ax*P_ACC)*fric
 player.dy=(player.dy+ay*P_ACC)*fric
 player.dx=clamp(player.dx,-P_MAXSPD,P_MAXSPD)
 player.dy=clamp(player.dy,-P_MAXSPD,P_MAXSPD)
 player.x=wrapx(player.x+player.dx)
 player.y=clamp(player.y+player.dy,Y_MIN,Y_MAX)
 local a=dir_to_ang(ax,ay)
 if a then player.facing=a player.boost=4 end
 player.alt=HOVER+sin(player.bob)*1.5

 -- engine trail
 if frame%2==0 then
  fx_trail(wrapx(player.x-cos(player.facing)*4),
           player.y-sin(player.facing)*2, player.alt, player.boost>2)
 end

 -- fire
 player.fire_cd=max(0,player.fire_cd-1)
 if btnh(B_FIRE) and player.fire_cd==0 then
  player.fire_cd=P_FIRE_CD
  fire_shot(wrapx(player.x+cos(player.facing)*4),
            player.y+sin(player.facing)*2, player.alt, player.facing)
 end

 -- smart bomb (o) / warp dash (hold down + o)
 if btnp8(B_BOMB) then
  if btnh(B_D) then do_warp() else do_smartbomb() end
 end

 -- catch falling colonists
 for c in all(colonists) do
  if c.state=="falling" and carried_count()<CARRY_MAX then
   if abs(wdelta(player.x,c.x))<5 and abs(player.y-c.y)<5
      and c.alt<=player.alt+4 and c.alt>=player.alt-6 then
    c.state="carried" c.carry_slot=carried_count()+1
    award(PTS.catch,c.x,c.y,c.alt)
    fx_sparkle(c.x,c.y,c.alt)
    sfx_safe("rescue")
   end
  end
 end

 -- deliver at a pad
 if carried_count()>0 then
  local p,d=nearest_pad(player.x)
  if p and d<8 and abs(player.y-p.y)<8 then
   drop_carried_at_pad()
  end
 end

 -- collisions: enemies, shots, mines
 if player_targetable() then
  for e in all(enemies) do
   for hb in all(enemy_hitboxes(e)) do
    if abs(wdelta(player.x,hb.x))<hb.rad+3
       and abs(player.y-hb.y)<hb.rad+3
       and abs(player.alt-hb.alt)<6 then
     player_hit(1)
     if e.kind=="swarmer" then enemy_kill(e) end
     break
    end
   end
  end
 end
 if player_targetable() then
  for s in all(eshots) do
   if abs(wdelta(player.x,s.x))<3 and abs(player.y-s.y)<3
      and abs(player.alt-s.alt)<4 then
    del(eshots,s) player_hit(1) break
   end
  end
  for m in all(mines) do
   if abs(wdelta(player.x,m.x))<4 and abs(player.y-m.y)<4
      and abs(player.alt-m.alt)<5 then
    fx_explosion(m.x,m.y,m.alt,10,{C_RED,C_ORG,C_YEL},false)
    del(mines,m) player_hit(1) break
   end
  end
 end
end

function player_draw()
 if not player_alive() then return end
 if player.invuln>0 and frame%4<2 then return end -- blink
 local sx=to_screen(player.x)
 if not sx then return end
 local z=GROUND_Z-player.alt
 local fx0=cos(player.facing) local fy0=sin(player.facing)
 -- hull
 boxfill(sx-2,player.y-1,z,sx+2,player.y+1,z,C_BLU)
 boxfill(sx-1,player.y,z-1,sx+1,player.y,z-1,C_WHT)
 -- nose in facing direction
 vset(clamp(sx+fx0*3,0,127),clamp(player.y+fy0*2,0,127),z,C_YEL)
 -- canopy glow
 vset(sx,player.y,z-2,(frame%20<10) and C_GRN or C_BLU)
 -- carried colonists dangle below
 for c in all(colonists) do
  if c.state=="carried" then
   local cz=GROUND_Z-c.alt
   if cz>=0 and cz<=62 then
    vset(sx,player.y,cz,C_BLU) vset(sx,player.y,cz-1,C_PCH)
   end
  end
 end
end
