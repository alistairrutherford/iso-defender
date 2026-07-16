-- voxel defender : 09_main
-- game states, wave director, scoring, collisions, _init/_update/_draw

frame=0 cam_x=0 shake=0 flash_t=0
score=0 hiscore=0 unlocked=1
mode="title"
level_no=1 level=LEVELS[1]
wave_no=1 ws="intro" ws_t=0 wave_t=0
hostile=false boss_done=false
boss_dying=nil boss_die_t=0 boss_die_x=64 boss_die_y=64 boss_die_alt=24
clear_t=0 clear_rank="c" lives_start=START_LIVES

-- scoring ---------------------------------------------------------------
function award(units,x,y,alt)
 local prev=score
 score=min(score+units,32000)
 if x then popup(x,y,alt,nstr(units).."0",C_YEL) end
 if flr(score/EXTRA_LIFE_EVERY)>flr(prev/EXTRA_LIFE_EVERY) then
  player.lives=player.lives+1
  popup(player.x,player.y,player.alt+6,"1up!",C_GRN)
  sfx_safe("1up")
 end
end

-- hostility: all colonists lost -> every lander mutates ------------------
function check_hostile()
 if hostile then return end
 if colonists_alive()>0 then return end
 hostile=true
 for e in all(enemies) do
  if e.kind=="lander" then
   e.kind="mutant" e.state="hunt"
   if e.victim then e.victim.claimed=nil e.victim=nil end
   fx_explosion(e.x,e.y,e.alt,8,{C_GRN,C_PNK},false)
  end
 end
 set_banner("!! hostile !!",90,C_RED)
 sfx_safe("alarm")
end

-- level flow ---------------------------------------------------------------
local function level_music()
 local n=1
 if level_no>4 then n=2 end
 if level_no>7 then n=3 end
 music_safe("music"..nstr(n),1)
end

function start_level(n)
 level_no=n level=LEVELS[n]
 particles_init() entities_init() enemies_init()
 pads_init(3)
 colonists_init(level.colonists)
 player.x=64 player.y=64 player.dx=0 player.dy=0
 player.shield=SHIELD_MAX player.dead_t=0 player.invuln=INVULN_T
 lives_start=player.lives
 world_init()
 cam_x=0 shake=0 flash_t=0
 wave_no=1 ws="intro" ws_t=0 wave_t=0
 hostile=false boss_done=false boss_dying=nil
 mode="play"
 set_banner(level.name,90,level.cols[5])
 level_music()
end

function start_run(n)
 score=0
 player_init()
 start_level(n)
end

local function next_level()
 player.bombs=min(player.bombs+1,6) -- small refill between levels
 start_level(level_no+1)
end

local function level_clear()
 local surv=colonists_alive()
 score=min(score+surv*PTS.survive,32000)
 local ratio=surv/level.colonists
 local deaths=max(0,lives_start-player.lives)
 if ratio>=0.99 and deaths==0 then clear_rank="s"
 elseif ratio>=0.75 then clear_rank="a"
 elseif ratio>=0.5 then clear_rank="b"
 else clear_rank="c" end
 unlocked=max(unlocked,min(level_no+1,10))
 if score>hiscore then hiscore=score end
 mode="clear" clear_t=0
 sfx_safe("clear")
 music_safe("jingle")
end

-- wave director --------------------------------------------------------------
local function wave_update()
 if ws=="intro" then
  ws_t=ws_t+1
  if ws_t==1 then
   set_banner("wave "..nstr(wave_no).."/"..nstr(#level.waves),60,C_YEL)
  end
  if ws_t>=45 then
   spawn_wave(level.waves[wave_no])
   ws="fight" wave_t=0
  end
 elseif ws=="boss_intro" then
  ws_t=ws_t+1
  if ws_t==1 then
   set_banner("!! warning !!",90,C_RED)
   sfx_safe("alarm")
  end
  if ws_t>=90 then
   espawn(level.boss,wrapx(player.x+WRAP/2),64,26)
   ws="fight" wave_t=0
  end
 elseif ws=="fight" then
  wave_t=wave_t+1
  -- anti-camping baiters from level 4 onward
  if level_no>=4 and wave_t>BAITER_AFTER
     and (wave_t-BAITER_AFTER)%BAITER_EVERY==0
     and enemies_count()<EMAX then
   espawn("baiter",wrapx(player.x+WRAP/2),player.y,20)
   sfx_safe("alarm")
  end
  -- boss death sequence: rolling multi-stage explosions
  if boss_dying then
   boss_die_t=boss_die_t+1
   if boss_die_t%6==0 then
    fx_explosion(wrapx(boss_die_x+rnd(24)-12),
                 boss_die_y+rnd(16)-8, boss_die_alt+rnd(10)-5,
                 12,{C_WHT,C_YEL,C_ORG,C_RED},true)
    sfx_safe("boom")
   end
   if boss_die_t>=70 then
    boss_dying=nil boss_done=true
    fx_smartbomb(boss_die_x,boss_die_y,boss_die_alt)
   end
  elseif #enemies==0 then
   if wave_no<#level.waves then
    wave_no=wave_no+1 ws="intro" ws_t=0
   elseif level.boss and not boss_done then
    ws="boss_intro" ws_t=0
   else
    level_clear()
   end
  end
 end
end

-- player shots vs enemies -------------------------------------------------------
local function shot_collisions()
 for i=#shots,1,-1 do
  local s=shots[i]
  local hit=false
  for e in all(enemies) do
   if hit then break end
   for hb in all(enemy_hitboxes(e)) do
    if abs(wdelta(s.x,hb.x))<hb.rad+1
       and abs(s.y-hb.y)<hb.rad+1
       and abs(s.alt-hb.alt)<hb.rad+2 then
     del(shots,s)
     enemy_damage(e,hb.part)
     hit=true
     break
    end
   end
  end
  if not hit then
   for m in all(mines) do
    if abs(wdelta(s.x,m.x))<3 and abs(s.y-m.y)<3
       and abs(s.alt-m.alt)<4 then
     del(shots,s)
     fx_explosion(m.x,m.y,m.alt,8,{C_YEL,C_ORG},false)
     award(PTS.mine,m.x,m.y,m.alt)
     del(mines,m)
     sfx_safe("boom")
     break
    end
   end
  end
 end
end

-- camera with look-ahead ------------------------------------------------------------
local function camera_update()
 local look=cos(player.facing)*26
 local target=wrapx(player.x-64+look)
 cam_x=wrapx(cam_x+wdelta(cam_x,target)*0.12)
end

-- callbacks -------------------------------------------------------------------------
function _init()
 particles_init()
 entities_init()
 enemies_init()
 player_init()
 world_init()
 music_safe("title")
end

function _update()
 frame=frame+1
 if frame>30000 then frame=0 end
 poll_buttons()
 banner_update()
 shake=max(0,shake-1)
 if flash_t>0 then flash_t=flash_t-1 end

 if mode=="title" then
  particles_update()
  if btnp8(B_FIRE) then mode="select" sfx_safe("ui") end

 elseif mode=="select" then
  select_update()

 elseif mode=="play" then
  player_update()
  enemies_update()
  shots_update() eshots_update() mines_update()
  colonists_update()
  world_update()
  particles_update() popups_update()
  shot_collisions()
  wave_update()
  camera_update()
  if player.lives<0 and player.dead_t<=0 then
   if score>hiscore then hiscore=score end
   mode="over"
   music_safe("gameover")
  end

 elseif mode=="clear" then
  clear_t=clear_t+1
  particles_update() popups_update()
  if clear_t>60 and btnp8(B_FIRE) then
   if level_no<10 then
    next_level()
   else
    mode="win"
    music_safe("victory")
   end
  end

 elseif mode=="over" then
  particles_update()
  if btnp8(B_FIRE) then
   mode="title"
   music_safe("title")
  end

 elseif mode=="win" then
  particles_update()
  if btnp8(B_FIRE) then
   mode="title"
   music_safe("title")
  end
 end
end

function _draw()
 clv()
 -- screen shake: jitter the camera for this frame only
 local realcam=cam_x
 if shake>0 then cam_x=wrapx(cam_x+rnd(shake)-shake/2) end

 if mode=="title" then
  title_draw()
  particles_draw()
 elseif mode=="select" then
  select_draw()
 elseif mode=="play" then
  world_draw()
  mines_draw()
  colonists_draw()
  enemies_draw()
  eshots_draw()
  shots_draw()
  player_draw()
  particles_draw()
  hud_draw()
  if flash_t>0 then
   boxfill(0,0,0,127,127,GROUND_Z+4,C_WHT)
  end
 elseif mode=="clear" then
  clear_draw()
 elseif mode=="over" then
  over_draw()
 elseif mode=="win" then
  win_draw()
 end

 cam_x=realcam
end
