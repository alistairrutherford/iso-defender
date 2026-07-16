-- voxel defender : 04_entities
-- player shots, enemy shots, mines, colonists, pads, score popups

shots={} eshots={} mines={} colonists={} pads={} popups={}

function entities_init()
 shots={} eshots={} mines={} colonists={} pads={} popups={}
end

-- score popups ---------------------------------------------------
function popup(x,y,alt,txt,col)
 add(popups,{x=x,y=y,alt=alt,txt=txt,col=col or C_WHT,t=0})
end

function popups_update()
 for i=#popups,1,-1 do
  local p=popups[i]
  p.t=p.t+1 p.alt=p.alt+0.4
  if p.t>36 then del(popups,p) end
 end
end

function popups_draw()
 for p in all(popups) do
  local sx=to_screen(p.x)
  if sx then
   local z=clamp(GROUND_Z-p.alt,2,60)
   world_print(p.txt,sx,p.y,z,p.col)
  end
 end
end

-- player shots ----------------------------------------------------
function fire_shot(x,y,alt,ang)
 add(shots,{x=x,y=y,alt=alt,ang=ang,
            dx=cos(ang)*P_SHOT_SPD, dy=sin(ang)*P_SHOT_SPD*0.7, t=0})
 fx_muzzle(x,y,alt,ang)
 sfx_safe("shoot")
end

function shots_update()
 for i=#shots,1,-1 do
  local s=shots[i]
  s.t=s.t+1
  s.x=wrapx(s.x+s.dx)
  s.y=clamp(s.y+s.dy,Y_MIN-6,Y_MAX+6)
  if s.t>P_SHOT_LIFE then del(shots,s) end
 end
end

function shots_draw()
 for s in all(shots) do
  local sx=to_screen(s.x)
  if sx then
   local z=GROUND_Z-s.alt
   local bx=clamp(sx-s.dx,0,127)
   line3d(bx,clamp(s.y-s.dy,0,127),z, clamp(sx,0,127),s.y,z, C_YEL)
   vset(clamp(sx,0,127),s.y,z,C_WHT)
  end
 end
end

-- enemy shots -------------------------------------------------------
function espawn_shot(x,y,alt,tx,ty,talt,spd,col)
 local d=max(1,sqrt(dist2(wdelta(x,tx),ty-y)))
 add(eshots,{x=x,y=y,alt=alt,
   dx=wdelta(x,tx)/d*spd, dy=(ty-y)/d*spd, dalt=(talt-alt)/d*spd,
   t=0,col=col or C_RED})
end

function eshots_update()
 for i=#eshots,1,-1 do
  local s=eshots[i]
  s.t=s.t+1
  s.x=wrapx(s.x+s.dx) s.y=s.y+s.dy s.alt=s.alt+s.dalt
  if s.t>90 or s.alt<0 or s.alt>50 or s.y<Y_MIN-8 or s.y>Y_MAX+8 then
   del(eshots,s)
  end
 end
end

function eshots_draw()
 for s in all(eshots) do
  local sx=to_screen(s.x)
  if sx then
   local z=GROUND_Z-s.alt
   if s.y>=0 and s.y<=127 and z>=1 and z<=62 then
    vset(clamp(sx,0,127),s.y,z,s.col)
    if s.t%2==0 then vset(clamp(sx,0,127),s.y,z-1,C_WHT) end
   end
  end
 end
end

-- mines (laid by bombers) -------------------------------------------
function lay_mine(x,y,alt)
 add(mines,{x=x,y=y,alt=alt,t=0})
end

function mines_update()
 for i=#mines,1,-1 do
  local m=mines[i]
  m.t=m.t+1
  if m.t>20*30 then
   fx_explosion(m.x,m.y,m.alt,6,{C_RED,C_ORG,C_DGRY},false)
   del(mines,m)
  end
 end
end

function mines_draw()
 for m in all(mines) do
  local sx=to_screen(m.x)
  if sx and sx>=1 and sx<=126 then
   local z=GROUND_Z-m.alt
   local c=(m.t%20<10) and C_RED or C_ORG
   sphere(sx,m.y,z,1,c)
   if m.t%20<10 then vset(sx,m.y,z-2,C_WHT) end
  end
 end
end

-- landing pads --------------------------------------------------------
function pads_init(n)
 pads={}
 for i=1,n do
  add(pads,{x=wrapx(i*(WRAP/n)+rnd(20)-10),y=64})
 end
end

function nearest_pad(x)
 local best,bd=nil,32000
 for p in all(pads) do
  local d=abs(wdelta(x,p.x))
  if d<bd then bd=d best=p end
 end
 return best,bd
end

function pads_draw()
 for p in all(pads) do
  local sx=to_screen(p.x)
  if sx and sx>=6 and sx<=121 then
   boxfill(sx-5,p.y-4,GROUND_Z-1,sx+5,p.y+4,GROUND_Z-1,C_GRY)
   box(sx-5,p.y-4,GROUND_Z-1,sx+5,p.y+4,GROUND_Z-1,C_YEL)
   if frame%30<15 then
    vset(sx-5,p.y-4,GROUND_Z-2,C_GRN)
    vset(sx+5,p.y+4,GROUND_Z-2,C_GRN)
   end
  end
 end
end

-- colonists ------------------------------------------------------------
-- state: ground / abducted / falling / carried / dead
function colonists_init(n)
 colonists={}
 for i=1,n do
  add(colonists,{
   x=wrapx(i*(WRAP/n)+rnd(30)),
   y=Y_MIN+16+rnd(Y_MAX-Y_MIN-32),
   alt=0, state="ground", wt=flr(rnd(90)), wd=rnd(1), fall_from=0})
 end
end

function colonists_alive()
 local n=0
 for c in all(colonists) do
  if c.state~="dead" then n=n+1 end
 end
 return n
end

function colonists_update()
 for c in all(colonists) do
  if c.state=="ground" then
   -- gentle wander
   c.wt=c.wt-1
   if c.wt<=0 then c.wt=60+flr(rnd(90)) c.wd=rnd(1) end
   if c.wt>30 then
    c.x=wrapx(c.x+cos(c.wd)*0.15)
    c.y=clamp(c.y+sin(c.wd)*0.1,Y_MIN+8,Y_MAX-8)
   end
  elseif c.state=="falling" then
   c.dalt=(c.dalt or 0)-0.08
   c.alt=c.alt+c.dalt
   if c.alt<=0 then
    c.alt=0
    if c.fall_from>22 then
     c.state="dead"
     fx_explosion(c.x,c.y,1,8,{C_RED,C_PUR,C_DGRY},false)
     sfx_safe("hurt")
     check_hostile()
    else
     c.state="ground"
     fx_sparkle(c.x,c.y,1)
    end
   end
  elseif c.state=="carried" then
   -- follows player, stacked
   local slot=c.carry_slot or 1
   c.x=player.x c.y=player.y
   c.alt=player.alt-3-slot*3
  end
  -- "abducted" position is driven by the lander that holds it
 end
end

function colonist_draw_one(c,sx)
 local z=GROUND_Z-c.alt
 if z<2 or z>62 then return end
 -- tiny voxel person: body + head
 boxfill(sx,c.y,z-2,sx,c.y,z-1,C_BLU)
 vset(sx,c.y,z-3,C_PCH)
 if c.state=="ground" and frame%60<8 then
  vset(sx,c.y,z-4,C_WHT) -- waving
 end
end

function colonists_draw()
 for c in all(colonists) do
  if c.state~="dead" then
   local sx=to_screen(c.x)
   if sx and sx>=1 and sx<=126 then colonist_draw_one(c,sx) end
  end
 end
end
