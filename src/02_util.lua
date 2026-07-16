-- voxel defender : 02_util
-- helpers: wrap math, safe audio, hud text, misc

function wrapx(x)
 while x<0 do x=x+WRAP end
 while x>=WRAP do x=x-WRAP end
 return x
end

-- shortest signed delta from a to b on the looping x axis
function wdelta(a,b)
 local d=b-a
 if d>WRAP/2 then d=d-WRAP end
 if d<-WRAP/2 then d=d+WRAP end
 return d
end

function dist2(dx,dy) return dx*dx+dy*dy end

function clamp(v,a,b) if v<a then return a end if v>b then return b end return v end

function nstr(n) return ""..flr(n) end

-- score is stored in units of 10 points -> append a zero to display
function score_str(units) return nstr(units).."0" end

-- audio: never crash if a sound/music resource isn't in the cart yet
function sfx_safe(name)
 local ok=pcall(play_sound,name)
 return ok
end

function music_safe(name,fade)
 pcall(play_music,name,fade)
end

-- world x -> screen x relative to camera (nil if off screen)
function to_screen(wx)
 local sx=wdelta(cam_x,wx)
 if sx<-20 or sx>SCR_W+20 then return nil end
 return sx
end

-- hud text drawn on the back wall (vertical slices y=0,1 for thickness)
function hud_print(s,x,z,col)
 set_draw_slice(0,true) print(s,x,z,col)
 set_draw_slice(1,true) print(s,x,z,col)
end

function hud_pset(x,z,col)
 set_draw_slice(0,true) pset(x,z,col)
 set_draw_slice(1,true) pset(x,z,col)
end

function hud_line(x0,z0,x1,z1,col)
 set_draw_slice(0,true) line(x0,z0,x1,z1,col)
 set_draw_slice(1,true) line(x0,z0,x1,z1,col)
end

-- floating world-space text (score popups, "rescued!")
function world_print(s,sx,sy,sz,col)
 sy=flr(clamp(sy,0,127))
 set_draw_slice(sy,true)
 print(s,sx-#s*2,sz,col)
end

-- 8-way facing from input vector -> angle 0..1 (0 = east/right)
function dir_to_ang(dx,dy)
 if dx==0 and dy==0 then return nil end
 return atan2(dx,dy)
end

-- edge-detected buttons (voxatron button() has no btnp)
prev_btn={} cur_btn={}
function poll_buttons()
 for i=0,5 do
  prev_btn[i]=cur_btn[i]
  cur_btn[i]=button(i)>0
 end
end
function btnh(i) return cur_btn[i] end                 -- held
function btnp8(i) return cur_btn[i] and not prev_btn[i] end -- pressed
