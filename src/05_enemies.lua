-- voxel defender : 05_enemies
-- landers, mutants, bombers, pods, swarmers, baiters + 2 bosses

enemies={}

function enemies_init() enemies={} end

function enemies_count()
 local n=0
 for e in all(enemies) do
  if e.kind~="guardian" and e.kind~="overmind" then n=n+1 end
 end
 return n
end

function boss_alive()
 for e in all(enemies) do
  if e.kind=="guardian" or e.kind=="overmind" then return true end
 end
 return false
end

function espawn(kind,x,y,alt)
 local e={kind=kind,x=wrapx(x),y=y,alt=alt,t=0,flash=0,
          life=E_LIFE[kind] or 1,state="descend",
          seed=rnd(1),shot_cd=60+flr(rnd(60))}
 if kind=="bomber" then
  e.dx=(rnd(1)<0.5 and -1 or 1)*E_SPD.bomber*level.spd
  e.mine_cd=50
 elseif kind=="guardian" then
  e.life=30
  e.parts={}
  for i=1,4 do add(e.parts,{ang=i/4,life=8,flash=0}) end
 elseif kind=="overmind" then
  e.life=50
  e.parts={}
  for i=1,6 do add(e.parts,{ang=i/6,life=6,flash=0}) end
  e.spawn_cd=150
 end
 add(enemies,e)
 fx_warp(e.x,e.y,e.alt)
 return e
end

-- spawn a wave from a table like {lander=5,bomber=2} ------------------
function spawn_wave(w)
 for kind,n in pairs(w) do
  if kind=="boss" then
   espawn(n,player and wrapx(player.x+WRAP/2) or 64,64,26)
  else
   for i=1,n do
    espawn(kind, wrapx(player.x+80+rnd(WRAP-160)),
           Y_MIN+10+rnd(Y_MAX-Y_MIN-20),
           (kind=="lander" or kind=="bomber") and 30+rnd(8) or 16+rnd(14))
   end
  end
 end
end

-- helpers ---------------------------------------------------------------
local function home(e,tx,ty,talt,spd)
 local d=max(1,sqrt(dist2(wdelta(e.x,tx),ty-e.y)))
 e.x=wrapx(e.x+wdelta(e.x,tx)/d*spd)
 e.y=clamp(e.y+(ty-e.y)/d*spd*0.7,Y_MIN,Y_MAX)
 if talt then e.alt=e.alt+clamp(talt-e.alt,-spd*0.5,spd*0.5) end
end

local function try_shoot(e,spd,col,cd)
 e.shot_cd=e.shot_cd-1
 if e.shot_cd<=0 and player_targetable() then
  e.shot_cd=cd+flr(rnd(cd))
  if abs(wdelta(e.x,player.x))<80 then
   espawn_shot(e.x,e.y,e.alt,player.x,player.y,player.alt,spd,col)
   sfx_safe("eshoot")
  end
 end
end

-- find an unclaimed grounded colonist near the lander
local function pick_victim(e)
 local best,bd=nil,32000
 for c in all(colonists) do
  if c.state=="ground" and not c.claimed then
   local d=abs(wdelta(e.x,c.x))
   if d<bd then bd=d best=c end
  end
 end
 return best
end

-- per-kind updates -------------------------------------------------------
local upd={}

upd.lander=function(e)
 local sp=E_SPD.lander*level.spd
 if e.state=="descend" then
  if not e.victim or e.victim.state~="ground" then
   if e.victim then e.victim.claimed=nil end
   e.victim=pick_victim(e)
   if e.victim then e.victim.claimed=true end
  end
  if e.victim then
   home(e,e.victim.x,e.victim.y,6,sp)
   if abs(wdelta(e.x,e.victim.x))<2 and abs(e.y-e.victim.y)<2
      and e.alt<8 then
    e.state="rise"
    e.victim.state="abducted"
    sfx_safe("alarm")
   end
  else
   -- no colonists left: hunt the player
   home(e,player.x,player.y,player.alt,sp*0.8)
  end
  try_shoot(e,1.2*level.spd,C_RED,110)
 elseif e.state=="rise" then
  e.alt=e.alt+sp*0.55
  e.victim.x=e.x e.victim.y=e.y e.victim.alt=e.alt-4
  if frame%3==0 then fx_beam(e.x,e.y,e.alt-4) end
  if e.alt>=ALT_MAX then
   -- escaped: colonist lost, lander mutates
   e.victim.state="dead" e.victim=nil
   e.kind="mutant" e.state="hunt"
   fx_explosion(e.x,e.y,e.alt,10,{C_GRN,C_PNK,C_WHT},false)
   sfx_safe("mutate")
   check_hostile()
  end
 end
end

upd.mutant=function(e)
 local sp=E_SPD.mutant*level.spd*(level.haz=="dark" and 1.2 or 1)
 local jx=cos(e.seed+e.t/40)*14
 local jy=sin(e.seed+e.t/34)*10
 home(e,player.x+jx,player.y+jy,player.alt+cos(e.t/50)*6,sp)
 try_shoot(e,1.6*level.spd,C_PNK,70)
end

upd.bomber=function(e)
 e.x=wrapx(e.x+e.dx)
 e.y=clamp(64+sin(e.seed+e.t/90)*36,Y_MIN,Y_MAX)
 e.alt=22+sin(e.seed+e.t/60)*6
 e.mine_cd=e.mine_cd-1
 if e.mine_cd<=0 then
  e.mine_cd=45+flr(rnd(30))
  lay_mine(e.x,e.y,e.alt)
  sfx_safe("mine")
 end
end

upd.pod=function(e)
 e.x=wrapx(e.x+cos(e.seed)*E_SPD.pod*level.spd)
 e.y=clamp(e.y+sin(e.seed+e.t/120)*0.3,Y_MIN,Y_MAX)
 e.alt=20+sin(e.t/80)*8
end

upd.swarmer=function(e)
 local sp=E_SPD.swarmer*level.spd
 home(e,player.x,player.y,player.alt,sp)
 e.x=wrapx(e.x+cos(e.seed+e.t/16)*1.2)
 e.y=clamp(e.y+sin(e.seed+e.t/13)*0.9,Y_MIN,Y_MAX)
end

upd.baiter=function(e)
 home(e,player.x,player.y,player.alt,E_SPD.baiter*level.spd)
 try_shoot(e,2*level.spd,C_GRN,45)
end

-- bosses -----------------------------------------------------------------
local function boss_part_pos(e,p,r)
 return wrapx(e.x+cos(p.ang+e.t/300)*r),
        e.y+sin(p.ang+e.t/300)*r*0.5,
        e.alt+cos(p.ang*2+e.t/200)*4
end

local function parts_alive(e)
 local n=0
 for p in all(e.parts) do if p.life>0 then n=n+1 end end
 return n
end

upd.guardian=function(e)
 e.x=wrapx(e.x+cos(e.t/400)*0.5)
 e.y=64+sin(e.t/300)*20
 e.alt=24+sin(e.t/180)*4
 local pa=parts_alive(e)
 for p in all(e.parts) do
  p.flash=max(0,p.flash-1)
  if p.life>0 and e.t%120==flr(p.ang*100) and player_targetable() then
   local px,py,palt=boss_part_pos(e,p,14)
   espawn_shot(px,py,palt,player.x,player.y,player.alt,1.5*level.spd,C_ORG)
  end
 end
 if pa==0 and e.t%90==0 then
  -- radial burst from exposed core
  for i=1,10 do
   local a=i/10
   espawn_shot(e.x,e.y,e.alt,
     wrapx(e.x+cos(a)*40),e.y+sin(a)*24,e.alt-6,1.6*level.spd,C_RED)
  end
  sfx_safe("eshoot")
 end
end

upd.overmind=function(e)
 local ph2=e.life<25
 e.x=wrapx(e.x+cos(e.t/(ph2 and 220 or 340))*(ph2 and 0.8 or 0.5))
 e.y=64+sin(e.t/260)*16
 e.alt=26+sin(e.t/150)*5
 for p in all(e.parts) do p.flash=max(0,p.flash-1) end
 e.spawn_cd=e.spawn_cd-1
 if e.spawn_cd<=0 and enemies_count()<EMAX-4 then
  e.spawn_cd=ph2 and 100 or 160
  espawn("swarmer",wrapx(e.x+rnd(40)-20),e.y,e.alt)
 end
 local cd=ph2 and 60 or 100
 if e.t%cd==0 then
  if parts_alive(e)>0 and player_targetable() then
   espawn_shot(e.x,e.y,e.alt,player.x,player.y,player.alt,1.8*level.spd,C_GRN)
  else
   for i=1,12 do
    local a=i/12+e.t/1000
    espawn_shot(e.x,e.y,e.alt,
      wrapx(e.x+cos(a)*40),e.y+sin(a)*24,e.alt-8,1.7*level.spd,C_GRN)
   end
  end
  sfx_safe("eshoot")
 end
end

-- hitboxes: list of {x,y,alt,rad,part} ------------------------------------
function enemy_hitboxes(e)
 if e.kind=="guardian" or e.kind=="overmind" then
  local hbs={}
  local r=(e.kind=="guardian") and 14 or 12
  for p in all(e.parts) do
   if p.life>0 then
    local px,py,palt=boss_part_pos(e,p,r)
    add(hbs,{x=px,y=py,alt=palt,rad=4,part=p})
   end
  end
  add(hbs,{x=e.x,y=e.y,alt=e.alt,rad=6,part=nil}) -- core
  return hbs
 end
 return {{x=e.x,y=e.y,alt=e.alt,rad=E_RAD[e.kind] or 4,part=nil}}
end

-- damage / death -----------------------------------------------------------
function enemy_kill(e,quiet)
 local cols={C_WHT,C_YEL,C_ORG,C_RED}
 if e.kind=="pod" then cols={C_WHT,C_PNK,C_PUR} end
 fx_explosion(e.x,e.y,e.alt,e.kind=="pod" and 20 or 14,cols,
              e.kind=="pod" or e.kind=="bomber")
 fx_confetti(e.x,e.y,e.alt)
 sfx_safe(e.kind=="pod" and "bigboom" or "boom")
 award(PTS[e.kind] or 10,e.x,e.y,e.alt)
 -- lander drops its victim
 if e.victim and e.victim.state=="abducted" then
  e.victim.state="falling" e.victim.dalt=0
  e.victim.fall_from=e.victim.alt e.victim.claimed=nil
 end
 del(enemies,e)
 -- pods burst into swarmers
 if e.kind=="pod" and not quiet then
  for i=1,4 do
   espawn("swarmer",wrapx(e.x+rnd(10)-5),clamp(e.y+rnd(10)-5,Y_MIN,Y_MAX),e.alt)
  end
 end
end

function enemy_damage(e,part)
 if part then
  part.life=part.life-1 part.flash=4
  if part.life<=0 then
   local r=(e.kind=="guardian") and 14 or 12
   local px,py,palt=boss_part_pos(e,part,r)
   fx_explosion(px,py,palt,16,{C_WHT,C_YEL,C_ORG,C_RED},true)
   sfx_safe("boom")
   award(25,px,py,palt)
  end
  return
 end
 if (e.kind=="guardian" or e.kind=="overmind") and parts_alive(e)>0 then
  fx_impact(e.x,e.y,e.alt) -- core shielded while parts remain
  return
 end
 e.life=e.life-1 e.flash=4
 if e.life<=0 then
  if e.kind=="guardian" or e.kind=="overmind" then
   boss_dying=e.kind boss_die_t=0
   boss_die_x=e.x boss_die_y=e.y boss_die_alt=e.alt
   fx_explosion(e.x,e.y,e.alt,30,{C_WHT,C_YEL,C_ORG,C_RED},true)
   award(PTS[e.kind],e.x,e.y,e.alt)
   sfx_safe("bigboom")
   del(enemies,e)
  else
   enemy_kill(e)
  end
 else
  fx_impact(e.x,e.y,e.alt)
 end
end

function enemies_update()
 for i=#enemies,1,-1 do
  local e=enemies[i]
  e.t=e.t+1
  e.flash=max(0,e.flash-1)
  local f=upd[e.kind]
  if f then f(e) end
 end
end

-- drawing --------------------------------------------------------------------
local function fc(e,col) return e.flash>0 and C_WHT or col end

local drw={}

drw.lander=function(e,sx)
 local z=GROUND_Z-e.alt
 boxfill(sx-2,e.y-1,z,sx+2,e.y+1,z,fc(e,C_GRN))
 boxfill(sx-1,e.y,z-1,sx+1,e.y,z-1,fc(e,C_DGRN))
 vset(sx,e.y,z-2,C_YEL)
 if e.state=="rise" then
  line3d(sx,e.y,z+1,sx,e.y,min(63,GROUND_Z),C_GRN)
 end
end

drw.mutant=function(e,sx)
 local z=GROUND_Z-e.alt
 local c=(frame%8<4) and C_PNK or C_RED
 boxfill(sx-2,e.y-1,z,sx+2,e.y+1,z,fc(e,c))
 vset(sx,e.y,z-1,C_WHT)
 vset(sx-2,e.y,z+1,c) vset(sx+2,e.y,z+1,c)
end

drw.bomber=function(e,sx)
 local z=GROUND_Z-e.alt
 boxfill(sx-3,e.y-1,z-1,sx+3,e.y+1,z,fc(e,C_BRN))
 boxfill(sx-1,e.y,z-2,sx+1,e.y,z-2,fc(e,C_ORG))
 vset(sx,e.y,z+1,(frame%16<8) and C_RED or C_ORG)
end

drw.pod=function(e,sx)
 local z=GROUND_Z-e.alt
 local r=2+((frame%40<20) and 1 or 0)
 sphere(sx,e.y,z,r,fc(e,C_PUR))
 vset(sx,e.y,z-r,C_PNK)
end

drw.swarmer=function(e,sx)
 local z=GROUND_Z-e.alt
 vset(sx,e.y,z,fc(e,(frame%6<3) and C_YEL or C_ORG))
 vset(sx,e.y,z-1,C_RED)
end

drw.baiter=function(e,sx)
 local z=GROUND_Z-e.alt
 local c=(frame%6<3) and C_BLU or C_GRN
 boxfill(sx-3,e.y-1,z,sx+3,e.y+1,z,fc(e,c))
 vset(sx-3,e.y,z-1,C_WHT) vset(sx+3,e.y,z-1,C_WHT)
end

local function draw_boss(e,sx,core_c,orb_c,r)
 local z=GROUND_Z-e.alt
 -- core
 sphere(sx,e.y,z,5,fc(e,core_c))
 sphere(sx,e.y,z-2,2,C_WHT)
 if parts_alive(e)>0 and frame%4<2 then
  sphere(sx,e.y,z,7,orb_c) -- shield shimmer
 end
 -- orbiting parts
 for p in all(e.parts) do
  if p.life>0 then
   local px,py,palt=boss_part_pos(e,p,r)
   local psx=to_screen(px)
   if psx and psx>=3 and psx<=124 then
    local pz=GROUND_Z-palt
    sphere(psx,py,pz,2,(p.flash>0) and C_WHT or orb_c)
    vset(psx,py,pz-2,C_YEL)
   end
  end
 end
end

drw.guardian=function(e,sx) draw_boss(e,sx,C_ORG,C_YEL,14) end
drw.overmind=function(e,sx) draw_boss(e,sx,C_DGRN,C_GRN,12) end

function enemies_draw()
 for e in all(enemies) do
  local sx=to_screen(e.x)
  if sx and sx>=4 and sx<=123 then
   local f=drw[e.kind]
   if f then f(e,sx) end
  end
 end
end
