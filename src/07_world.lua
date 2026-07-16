-- voxel defender : 07_world
-- terrain, per-level scenery, ambient particles, level hazards

features={} skydots={} geysers={} bolt=nil bolt_cd=0

function world_init()
 features={} skydots={} geysers={} bolt=nil bolt_cd=140
 -- scatter decorative scenery around the loop
 for i=1,26 do
  add(features,{
   x=wrapx(i*(WRAP/26)+rnd(14)),
   y=Y_MIN+6+rnd(Y_MAX-Y_MIN-12),
   h=3+flr(rnd(5)), w=1+flr(rnd(2)), v=rnd(1)})
 end
 -- parallax sky dots (stars / far clouds)
 for i=1,14 do
  add(skydots,{x=rnd(WRAP),z=3+flr(rnd(9)),y=4+flr(rnd(10))})
 end
 if level.haz=="geyser" then
  for i=1,4 do
   add(geysers,{x=wrapx(i*(WRAP/4)+rnd(30)),y=40+rnd(48),t=flr(rnd(240))})
  end
 end
end

local function draw_ground()
 local c=level.cols
 boxfill(0,0,GROUND_Z,127,127,63,c[2])
 boxfill(0,0,GROUND_Z,127,127,GROUND_Z,c[1])
 -- scrolling surface stripes so motion reads clearly
 local k=flr(cam_x/32)*32
 for i=-1,5 do
  local wx=k+i*32
  local sx=wdelta(cam_x,wrapx(wx))
  local x0=clamp(sx,0,127) local x1=clamp(sx+15,0,127)
  if x1>x0 then
   boxfill(x0,0,GROUND_Z,x1,127,GROUND_Z,c[2])
  end
 end
end

-- one scenery item, styled by level number
local function draw_feature(f,sx)
 local c=level.cols
 local z=GROUND_Z-1
 local lv=level_no
 if lv==1 then      -- flowers + bushes
  sphere(sx,f.y,z-f.h+1,f.w+1,C_DGRN)
  vset(sx,f.y,z-f.h,f.v<0.5 and C_PNK or C_YEL)
 elseif lv==2 then  -- cacti
  boxfill(sx,f.y,z-f.h,sx,f.y,z,C_DGRN)
  vset(sx-1,f.y,z-f.h+1,C_DGRN) vset(sx+1,f.y,z-f.h+2,C_DGRN)
  vset(sx,f.y,z-f.h-1,C_PNK)
 elseif lv==3 then  -- glowing crystals
  boxfill(sx,f.y,z-f.h,sx+f.w,f.y+1,z,c[3])
  vset(sx,f.y,z-f.h-1,(frame%30<15) and C_WHT or c[4])
 elseif lv==4 then  -- giant mushrooms
  boxfill(sx,f.y,z-f.h,sx,f.y,z,C_GRY)
  sphere(sx,f.y,z-f.h,f.w+2,c[3])
  vset(sx,f.y,z-f.h-f.w-2,C_WHT)
 elseif lv==5 then  -- brass pylons
  boxfill(sx,f.y,z-f.h-2,sx+1,f.y+1,z,C_ORG)
  vset(sx,f.y,z-f.h-3,(frame%20<10) and C_YEL or C_WHT)
 elseif lv==6 then  -- ice spikes
  boxfill(sx,f.y,z-f.h,sx+f.w,f.y+f.w,z,C_WHT)
  vset(sx,f.y,z-f.h-1,C_BLU)
 elseif lv==7 then  -- volcanic rocks
  sphere(sx,f.y,z,f.w+1,C_DGRY)
  vset(sx,f.y,z-f.w-1,(frame%24<12) and C_RED or C_ORG)
 elseif lv==8 then  -- neon ruins
  boxfill(sx,f.y,z-f.h-2,sx+2,f.y+1,z,C_DGRY)
  local nc=(f.v<0.5) and C_PNK or C_BLU
  if frame%40<32 then line3d(sx,f.y,z-f.h-2,sx+2,f.y,z-f.h-2,nc) end
 elseif lv==9 then  -- crags
  boxfill(sx,f.y,z-f.h,sx+f.w+1,f.y+f.w,z,C_DGRY)
  vset(sx,f.y,z-f.h-1,C_GRY)
 else               -- alien growths
  boxfill(sx,f.y,z-f.h,sx,f.y,z,C_DGRN)
  sphere(sx,f.y,z-f.h,1,(frame%16<8) and C_GRN or C_PUR)
 end
end

local function draw_sky()
 for d in all(skydots) do
  -- half-speed parallax
  local sx=wdelta(cam_x*0.5,d.x)
  if sx>=0 and sx<=127 then
   local col=C_WHT
   if level_no==5 then col=C_GRY
   elseif level_no==9 then col=C_DGRY
   elseif level_no==8 then col=C_DBLU end
   vset(sx,d.y,d.z,col)
  end
 end
end

-- ambient particles near the camera ------------------------------------
local function ambient()
 local a=level.amb
 local wx=wrapx(cam_x+rnd(128))
 local wy=Y_MIN+rnd(Y_MAX-Y_MIN)
 if a=="pollen" then
  if frame%4==0 then
   pspawn(wx,wy,2+rnd(20),0.1,0,0.1,40,{C_YEL,C_WHT},1,0)
  end
 elseif a=="sand" then
  if frame%3==0 then
   pspawn(wx,wy,1+rnd(6),0.8+rnd(0.6),0,0,30,{C_PCH,C_ORG},1,0)
  end
 elseif a=="glint" then
  if frame%6==0 then
   pspawn(wx,wy,1+rnd(10),0,0,0.2,16,{C_WHT,C_BLU,C_WHT},1,0)
  end
 elseif a=="spore" then
  if frame%4==0 then
   pspawn(wx,wy,rnd(25),0.15,cos(frame/60)*0.2,0.12,50,{C_PNK,C_GRN},1,0)
  end
 elseif a=="cloud" then
  if frame%10==0 then
   pspawn(wx,wy,26+rnd(12),0.4,0,0,60,{C_WHT,C_GRY},2,0)
  end
 elseif a=="snow" then
  if frame%2==0 then
   pspawn(wx,wy,30+rnd(10),0.2,0.1,-0.35,90,{C_WHT},1,0)
  end
 elseif a=="ember" then
  if frame%3==0 then
   pspawn(wx,wy,rnd(4),0.1,0,0.5+rnd(0.4),35,{C_YEL,C_ORG,C_RED,C_DGRY},1,0)
  end
 elseif a=="neon" then
  if frame%3==0 then
   pspawn(wx,wy,34,0,0,-1.6,26,{C_PNK,C_BLU},1,0)
  end
 elseif a=="rain" then
  pspawn(wx,wy,36,0.3,0,-2.2,18,{C_BLU,C_GRY},1,0)
 elseif a=="mote" then
  if frame%5==0 then
   pspawn(wx,wy,rnd(30),cos(frame/90)*0.3,0,0.1,45,{C_GRN,C_PUR},1,0)
  end
 end
end

-- hazards ----------------------------------------------------------------
local function geysers_update()
 for g in all(geysers) do
  g.t=g.t+1
  if g.t>240 then g.t=0 end
  if g.t>=180 then
   -- erupting
   if frame%2==0 then
    pspawn(g.x+rnd(4)-2,g.y+rnd(3)-1.5,1,0,0,1.8+rnd(0.8),
           22,{C_YEL,C_ORG,C_RED},1,0.05)
   end
   if player_targetable()
      and abs(wdelta(player.x,g.x))<5 and abs(player.y-g.y)<5
      and player.alt<24 then
    player_hit(1)
   end
  end
 end
end

local function geysers_draw()
 for g in all(geysers) do
  local sx=to_screen(g.x)
  if sx and sx>=2 and sx<=125 then
   if g.t>=150 and g.t<180 then
    -- warning glow
    sphere(sx,g.y,GROUND_Z-1,1,(frame%8<4) and C_RED or C_ORG)
   elseif g.t>=180 then
    line3d(sx,g.y,GROUND_Z-24,sx,g.y,GROUND_Z-1,(frame%4<2) and C_YEL or C_ORG)
   end
  end
 end
end

local function lightning_update()
 if bolt then
  bolt.t=bolt.t+1
  if bolt.t==30 then
   -- strike!
   sfx_safe("boom")
   shake=max(shake,5)
   for i=1,14 do
    pspawn(bolt.x+rnd(6)-3,bolt.y+rnd(4)-2,1,rnd(2)-1,rnd(1)-0.5,rnd(1.5),
           18,{C_WHT,C_YEL},1,0.05)
   end
   if player_targetable()
      and abs(wdelta(player.x,bolt.x))<6 and abs(player.y-bolt.y)<6 then
    player_hit(1)
   end
  end
  if bolt.t>40 then bolt=nil end
 else
  bolt_cd=bolt_cd-1
  if bolt_cd<=0 then
   bolt_cd=100+flr(rnd(120))
   bolt={x=wrapx(cam_x+rnd(128)),y=Y_MIN+10+rnd(Y_MAX-Y_MIN-20),t=0}
  end
 end
end

local function lightning_draw()
 if not bolt then return end
 local sx=to_screen(bolt.x)
 if not sx or sx<2 or sx>125 then return end
 if bolt.t<30 then
  if frame%6<3 then sphere(sx,bolt.y,GROUND_Z-1,1,C_YEL) end
 else
  local jag=flr(rnd(5))-2
  line3d(clamp(sx+jag,0,127),bolt.y,2,sx,bolt.y,GROUND_Z-1,C_WHT)
  line3d(clamp(sx-jag,0,127),bolt.y,10,sx,bolt.y,GROUND_Z-1,C_YEL)
 end
end

function world_update()
 ambient()
 if level.haz=="geyser" then geysers_update() end
 if level.haz=="lightning" then lightning_update() end
end

function world_draw()
 draw_ground()
 draw_sky()
 for f in all(features) do
  local sx=to_screen(f.x)
  if sx and sx>=4 and sx<=122 then draw_feature(f,sx) end
 end
 pads_draw()
 if level.haz=="geyser" then geysers_draw() end
 if level.haz=="lightning" then lightning_draw() end
end
