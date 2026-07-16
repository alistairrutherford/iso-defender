#!/usr/bin/env python3
"""Headless test harness for voxel defender.

Stubs the Voxatron 0.3.5b Lua API (with PICO-8 math semantics) and runs
real gameplay simulations against build/voxel_defender.lua.
"""
import os, sys
from lupa import LuaRuntime

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SHIM = r"""
-- ---- voxatron / pico-8 API shim (test only) ----
local m = math
local TAU = m.pi*2
draw_calls = 0
sounds = {}
music_played = {}

function cos(x) return m.cos((x or 0)*TAU) end
function sin(x) return -m.sin((x or 0)*TAU) end
function atan2(dx,dy) return (m.atan(-(dy or 0),(dx or 0))/TAU)%1 end
flr=m.floor ceil=m.ceil sqrt=m.sqrt abs=m.abs
function max(a,b) if a>b then return a end return b end
function min(a,b) if a<b then return a end return b end
function mid(a,b,c) local t={a,b,c} table.sort(t) return t[2] end
function rnd(x) return m.random()*(x or 1) end
function srand(x) m.randomseed(x) end
function add(t,v) t[#t+1]=v return v end
function del(t,v)
 for i=1,#t do if t[i]==v then table.remove(t,i) return v end end
end
function all(t)
 local i=0
 return function() i=i+1 return t[i] end
end
tostr=tostring

-- drawing stubs: validate arg count-ish, count calls
local function d(...) draw_calls=draw_calls+1 end
clv=function() end
vset=d vget=function() return 0 end
box=d boxfill=d line3d=d sphere=d draw_voxmap=d blit_voxmap=d
set_draw_slice=function(...) end
line=d circ=d circfill=d pset=d pget=function() return 0 end
print=d  -- pico-8 style draw print (shadow lua print)

play_sound=function(n) sounds[#sounds+1]=n end
stop_sound=function() end
play_music=function(n) music_played[#music_played+1]=n end
stop_music=function() end

btn_state={[0]=0,0,0,0,0,0}
function button(n) return btn_state[n] or 0 end
"""

DRIVER = r"""
-- ---- test driver ----
function press(n) btn_state[n]=1 end
function release_all() for i=0,5 do btn_state[i]=0 end end

function step(n)
 for i=1,(n or 1) do
  draw_calls=0
  _update()
  _draw()
  if draw_calls>peak_draw then peak_draw=draw_calls end
  release_all()
 end
end

function step_held(n, keys)
 for i=1,n do
  for _,k in ipairs(keys) do press(k) end
  draw_calls=0
  _update()
  _draw()
  if draw_calls>peak_draw then peak_draw=draw_calls end
  release_all()
 end
end

function tap(n)
 step(1)          -- ensure button released for one polled frame
 press(n)
 step(1)
end

peak_draw=0
"""


def make_runtime():
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(SHIM)
    with open(os.path.join(ROOT, "build", "voxel_defender.lua")) as f:
        lua.execute(f.read())
    lua.execute(DRIVER)
    lua.execute("srand(7) _init()")
    return lua


def check(lua, cond, msg):
    ok = lua.eval(cond)
    tag = "PASS" if ok else "FAIL"
    print(f"  {tag}  {msg}   [{cond}]")
    return bool(ok)


failures = 0
def must(lua, cond, msg):
    global failures
    if not check(lua, cond, msg):
        failures += 1


# ------------------------------------------------------------------
print("scenario A: menu flow + full 10-level autopilot clear")
lua = make_runtime()
must(lua, 'mode=="title"', "boots to title")
lua.execute("tap(4)")
must(lua, 'mode=="select"', "title -> select on x")
lua.execute("tap(4)")
must(lua, 'mode=="play" and level_no==1', "select -> level 1")
must(lua, "#colonists==8", "8 colonists on level 1")

# autopilot: fly right + fire; every few frames deal direct damage so the
# wave director, boss flow, clear tally and level chain all execute.
lua.execute(r"""
function autopilot_level()
 local safety=0
 while mode=="play" and safety<9000 do
  safety=safety+1
  press(1) press(4)
  if #enemies>0 and frame%8==0 then
   local e=enemies[1]
   for hb in all(enemy_hitboxes(e)) do
    enemy_damage(e, hb.part)
    break
   end
  end
  step(1)
  player.shield=3 player.lives=3  -- invulnerable test pilot
 end
 return safety
end
""")
for lv in range(1, 11):
    lua.execute("autopilot_level()")
    if lv < 10:
        must(lua, f'mode=="clear" and level_no=={lv}', f"level {lv} reaches clear tally")
        lua.execute("step(70) tap(4)")
        must(lua, f'mode=="play" and level_no=={lv+1}', f"advances to level {lv+1}")
    else:
        must(lua, 'mode=="clear" and level_no==10', "level 10 (overmind) cleared")
        lua.execute("step(70) tap(4)")
        must(lua, 'mode=="win"', "level 10 clear -> victory screen")
must(lua, "score>0", "score accumulated")
must(lua, "unlocked==10", "all levels unlocked")
must(lua, "#music_played>0 and #sounds>0", "audio hooks invoked")
print("  peak draw calls/frame:", lua.eval("peak_draw"))

# ------------------------------------------------------------------
print("scenario B: 4000-frame honest combat soak on level 3 (no cheats)")
lua = make_runtime()
lua.execute("unlocked=10 mode='select' sel=3 tap(4)")
must(lua, 'mode=="play" and level_no==3', "level select honours cursor")
lua.execute(r"""
soak_err=nil
for i=1,4000 do
 press(1) press(4)
 if i%97==0 then press(5) end            -- smart bombs
 if i%450==0 then press(3) press(5) end  -- warp dashes
 local ok,err=pcall(step,1)
 if not ok then soak_err=err break end
end
""")
must(lua, "soak_err==nil", "no runtime errors over 4000 frames")
must(lua, 'mode=="play" or mode=="over" or mode=="clear"', "ended in a sane state")
must(lua, "#parts==220", "particle pool intact")

# ------------------------------------------------------------------
print("scenario C: hostile mode + player death -> game over -> title")
lua = make_runtime()
lua.execute("tap(4) tap(4) step(60)")  # into level 1 fight
lua.execute("for c in all(colonists) do c.state='dead' end check_hostile()")
must(lua, 'mode=="play" and #enemies>0', "in level 1 fight with live enemies")
must(lua, "hostile==true", "hostile flips when colonists gone")
must(lua, """(function()
  for e in all(enemies) do if e.kind=='lander' then return false end end
  return true end)()""", "all landers mutated")
lua.execute(r"""
local safety=0
while mode=="play" and safety<3000 do
 safety=safety+1
 if player_targetable() then player.invuln=0 player_hit(1) end
 step(1)
end
""")
must(lua, 'mode=="over"', "losing all lives reaches game over")
lua.execute("step(5) tap(4)")
must(lua, 'mode=="title"', "game over -> title")

print()
print("FAILURES:", failures)
sys.exit(1 if failures else 0)
