-- voxel defender : 08_hud
-- hud bar, radar strip, banners, title / select / end screens

banner_txt=nil banner_t=0 banner_col=C_WHT

function set_banner(txt,frames,col)
 banner_txt=txt banner_t=frames banner_col=col or C_WHT
end

function banner_update()
 if banner_t>0 then banner_t=banner_t-1 end
end

local function draw_banner()
 if banner_t>0 and banner_txt then
  local c=(banner_t%12<6) and banner_col or C_WHT
  set_draw_slice(64,true)
  print(banner_txt,64-#banner_txt*2,18,c)
 end
end

-- radar ------------------------------------------------------------------
local RX0=14 RX1=114 RZ=8

local function radar_x(wx)
 return 64+flr(wdelta(player.x,wx)*(RX1-RX0)/WRAP)
end

local function radar_blip(wx,z,col)
 local x=radar_x(wx)
 if x>=RX0 and x<=RX1 then hud_pset(x,z,col) end
end

local function draw_radar()
 hud_line(RX0-1,RZ-3,RX0-1,RZ+3,C_DGRY)
 hud_line(RX1+1,RZ-3,RX1+1,RZ+3,C_DGRY)
 hud_line(RX0,RZ+3,RX1,RZ+3,C_DGRY)
 -- night radar flickers on the neon level
 if level.haz=="dark" and frame%40>34 then return end
 for c in all(colonists) do
  if c.state~="dead" then
   radar_blip(c.x,RZ+2,(c.state=="abducted") and ((frame%8<4) and C_WHT or C_GRN) or C_GRN)
  end
 end
 for p in all(pads) do radar_blip(p.x,RZ+2,C_YEL) end
 for e in all(enemies) do
  local col=C_RED
  if e.kind=="mutant" then col=C_PNK end
  if e.kind=="baiter" then col=C_BLU end
  if e.kind=="guardian" or e.kind=="overmind" then col=(frame%8<4) and C_ORG or C_WHT end
  radar_blip(e.x,RZ-flr(e.alt/16),col)
 end
 hud_pset(64,RZ,C_WHT) -- you
end

-- main hud ------------------------------------------------------------------
function hud_draw()
 hud_print("score "..score_str(score),2,1,C_WHT)
 hud_print("hi "..score_str(hiscore),90,1,C_GRY)
 -- lives
 for i=1,player.lives do hud_pset(RX0-12+i*2,RZ,C_BLU) end
 -- bombs
 for i=1,player.bombs do hud_pset(RX1+4+i*2,RZ,C_YEL) end
 -- shield pips
 for i=1,SHIELD_MAX do
  hud_pset(RX0-12+i*2,RZ+2,(i<=player.shield) and C_GRN or C_DGRY)
 end
 hud_print("l"..nstr(level_no).." w"..nstr(min(wave_no,#level.waves)),2,54,level.cols[5])
 draw_radar()
 draw_banner()
 popups_draw()
end

-- little ship glyph used on menus --------------------------------------------
local function menu_ship(x,y,z)
 boxfill(x-2,y-1,z,x+2,y+1,z,C_BLU)
 boxfill(x-1,y,z-1,x+1,y,z-1,C_WHT)
 vset(x+3,y,z,C_YEL)
 vset(x,y,z-2,(frame%20<10) and C_GRN or C_BLU)
end

-- title screen -----------------------------------------------------------------
function title_draw()
 -- starfield
 for d in all(skydots) do
  vset((d.x+flr(frame/4))%128,d.y,d.z,C_WHT)
 end
 boxfill(0,0,58,127,127,63,C_DGRN)
 boxfill(0,0,58,127,127,58,C_GRN)
 hud_print("v o x e l",44,10,C_GRY)
 hud_print("d e f e n d e r",32,18,(frame%30<15) and C_YEL or C_ORG)
 -- drifting ship with rainbow trail
 local mx=20+(frame%176)
 if mx<128 then
  menu_ship(mx,70,34)
  fx_trail(wrapx(cam_x+mx-4),70,GROUND_Z-34,true)
 end
 if frame%40<28 then hud_print("press x to start",34,36,C_WHT) end
 hud_print("hi "..score_str(hiscore),50,46,C_GRY)
end

-- level select --------------------------------------------------------------------
sel=1
function select_draw()
 boxfill(0,0,58,127,127,63,C_DBLU)
 hud_print("select level",40,2,C_YEL)
 for i=1,10 do
  local col=(i>unlocked) and C_DGRY or C_WHT
  if i==sel then col=(frame%16<8) and C_YEL or C_ORG end
  local x=(i<=5) and 8 or 68
  local z=8+((i-1)%5)*8
  local nm=(i>unlocked) and "locked" or LEVELS[i].name
  hud_print(nstr(i).." "..nm,x,z,col)
 end
 hud_print("x-go  hold o+x-title",24,52,C_GRY)
end

function select_update()
 if btnp8(B_U) and sel>1 then sel=sel-1 sfx_safe("ui") end
 if btnp8(B_D) and sel<10 then sel=sel+1 sfx_safe("ui") end
 if btnp8(B_L) and sel>5 then sel=sel-5 sfx_safe("ui") end
 if btnp8(B_R) and sel<=5 then sel=min(sel+5,10) sfx_safe("ui") end
 if btnp8(B_FIRE) then
  if btnh(B_BOMB) then
   mode="title"
  elseif sel<=unlocked then
   start_run(sel) sfx_safe("ui")
  else
   sfx_safe("hurt")
  end
 end
end

-- level clear tally ------------------------------------------------------------------
function clear_draw()
 world_draw()
 particles_draw()
 boxfill(20,0,14,108,2,40,C_BLK)
 hud_line(20,14,108,14,C_YEL)
 hud_print("level "..nstr(level_no).." clear!",34,18,(frame%20<10) and C_YEL or C_GRN)
 local surv=colonists_alive()
 hud_print("colonists x"..nstr(surv).."  +"..nstr(surv*PTS.survive).."0",28,26,C_GRN)
 hud_print("rank "..clear_rank,54,32,C_PNK)
 if clear_t>60 and frame%30<20 then
  hud_print(level_no<10 and "press x" or "press x !",50,38,C_WHT)
 end
end

-- game over / victory -------------------------------------------------------------------
function over_draw()
 world_draw()
 particles_draw()
 boxfill(20,0,14,108,2,40,C_BLK)
 hud_print("game over",46,20,(frame%20<10) and C_RED or C_ORG)
 hud_print("score "..score_str(score),40,28,C_WHT)
 if score>=hiscore and score>0 then hud_print("new best!",46,34,C_YEL) end
 if frame%30<20 then hud_print("press x",50,40,C_GRY) end
end

function win_draw()
 for d in all(skydots) do
  vset((d.x+flr(frame/3))%128,d.y,d.z,C_WHT)
 end
 boxfill(0,0,58,127,127,63,C_DGRN)
 if frame%4==0 then
  fx_confetti(wrapx(cam_x+rnd(128)),20+rnd(80),20+rnd(20))
 end
 particles_draw()
 hud_print("the overmind falls!",26,10,(frame%16<8) and C_GRN or C_YEL)
 hud_print("colony saved",40,18,C_WHT)
 hud_print("score "..score_str(score),40,28,C_YEL)
 hud_print("thank you, ranger",32,38,C_PNK)
 if frame%30<20 then hud_print("press x",50,50,C_GRY) end
end
