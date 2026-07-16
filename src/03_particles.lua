-- voxel defender : 03_particles
-- pooled voxel particle system + effect recipes

parts={}      -- fixed pool, recycled
p_head=1

function particles_init()
 parts={}
 for i=1,PMAX do
  parts[i]={live=false}
 end
 p_head=1
end

-- x,y in world coords, alt above ground. cols = {c1,c2,..} cycled over life
function pspawn(x,y,alt,dx,dy,dalt,life,cols,size,grav)
 local p=parts[p_head]
 p_head=p_head+1 if p_head>PMAX then p_head=1 end
 p.live=true
 p.x=wrapx(x) p.y=y p.alt=alt
 p.dx=dx p.dy=dy p.dalt=dalt
 p.t=0 p.life=life p.cols=cols
 p.size=size or 1
 p.grav=grav or 0
end

function particles_update()
 for i=1,PMAX do
  local p=parts[i]
  if p.live then
   p.t=p.t+1
   if p.t>=p.life then
    p.live=false
   else
    p.x=wrapx(p.x+p.dx)
    p.y=p.y+p.dy
    p.dalt=p.dalt-p.grav
    p.alt=p.alt+p.dalt
    if p.alt<0 then p.alt=0 p.dalt=-p.dalt*0.4 end
    if p.alt>60 then p.live=false end
   end
  end
 end
end

function particles_draw()
 for i=1,PMAX do
  local p=parts[i]
  if p.live then
   local sx=to_screen(p.x)
   if sx then
    local col=p.cols[1+flr(p.t/p.life*#p.cols)] or p.cols[#p.cols]
    local z=GROUND_Z-p.alt
    if p.y>=0 and p.y<=127 and z>=0 and z<=63 then
     if p.size<=1 then
      vset(sx,p.y,z,col)
     else
      sphere(sx,p.y,z,p.size,col)
     end
    end
   end
  end
 end
end

-- effect recipes ------------------------------------------------

function fx_explosion(x,y,alt,n,cols,big)
 for i=1,n do
  local a=rnd(1)
  local sp=0.5+rnd(big and 2.2 or 1.4)
  pspawn(x,y,alt, cos(a)*sp, sin(a)*sp*0.6, rnd(1.6)-0.4,
         14+flr(rnd(14)), cols, 1, 0.05)
 end
 if big then
  -- expanding shockwave ring
  for i=1,24 do
   local a=i/24
   pspawn(x,y,alt, cos(a)*2.8, sin(a)*1.6, 0, 10, {C_WHT,C_YEL}, 1, 0)
  end
  -- slow colour-cycling sparks
  for i=1,10 do
   pspawn(x,y,alt+2, rnd(1)-0.5, rnd(1)-0.5, 0.8+rnd(0.8),
          30+flr(rnd(20)), {C_WHT,C_YEL,C_ORG,C_RED}, 1, 0.03)
  end
 end
 shake=max(shake, big and 6 or 3)
end

function fx_sparkle(x,y,alt)
 for i=1,12 do
  local a=rnd(1)
  pspawn(x,y,alt, cos(a)*0.6, sin(a)*0.4, 0.6+rnd(1),
         20+flr(rnd(12)), {C_YEL,C_WHT,C_YEL}, 1, 0.04)
 end
end

function fx_heart(x,y,alt)
 pspawn(x,y,alt+4, 0,0, 0.5, 26, {C_PNK,C_RED,C_PNK}, 2, 0)
end

function fx_trail(x,y,alt,boost)
 local cols=boost and {C_PNK,C_YEL,C_GRN,C_BLU} or {C_BLU,C_GRY,C_DGRY}
 pspawn(x,y,alt+rnd(2)-1, rnd(0.4)-0.2, rnd(0.4)-0.2, rnd(0.2)-0.1,
        10+flr(rnd(8)), cols, 1, 0)
end

function fx_muzzle(x,y,alt,ang)
 pspawn(x,y,alt, cos(ang)*1.5, sin(ang)*1.0, 0, 4, {C_WHT,C_YEL}, 1, 0)
end

function fx_impact(x,y,alt)
 for i=1,4 do
  pspawn(x,y,alt, rnd(1.2)-0.6, rnd(0.8)-0.4, rnd(0.8),
         8+flr(rnd(6)), {C_YEL,C_ORG}, 1, 0.06)
 end
end

function fx_beam(x,y,alt_top)
 -- rising green tractor beam column under a lander
 pspawn(x+rnd(4)-2, y+rnd(3)-1.5, rnd(alt_top),
        0,0, 0.7, 16, {C_GRN,C_WHT,C_GRN}, 1, 0)
end

function fx_confetti(x,y,alt)
 local cc={{C_RED},{C_ORG},{C_YEL},{C_GRN},{C_BLU},{C_PNK}}
 for i=1,8 do
  pspawn(x,y,alt, rnd(2)-1, rnd(1.4)-0.7, 1+rnd(1.2),
         30+flr(rnd(20)), cc[1+flr(rnd(6))], 1, 0.06)
 end
end

function fx_warp(x,y,alt)
 for i=1,20 do
  local a=i/20
  pspawn(x,y,alt, cos(a)*1.8, sin(a)*1.1, rnd(1)-0.5,
         16, {C_PNK,C_BLU,C_WHT,C_GRN}, 1, 0)
 end
end

function fx_smartbomb(x,y,alt)
 for i=1,40 do
  local a=i/40
  local sp=1.5+rnd(2)
  pspawn(x,y,alt, cos(a)*sp, sin(a)*sp*0.6, rnd(1)-0.3,
         18+flr(rnd(10)), {C_WHT,C_YEL,C_ORG}, 1, 0)
 end
 flash_t=3
 shake=8
end
