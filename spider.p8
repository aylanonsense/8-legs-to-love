pico-8 cartridge // http://www.pico-8.com
version 8
__lua__

-- todo
-- flies shouldn't be able to be caught by sticky things that are anchored on tiles (no way to shake free)
-- title screen / game over screen
-- fix not always being able to attach web to web
-- fix unbreakable traps by laying sticky web on top of structural web
-- one bug per web point
-- envenom animation

-- todo sounds
--   jump
--   envenom
--   walk

-- game vars
tile_symbols='abcdefghijklmnopqrstuvwxyz0123456789'
tile_flip_matrix={8,4,2,1,128,64,32,16}
game_frame=0
bg_color=0
spider=nil
bugs={}
web_points={}
web_strands={}
tiles={}


-- main functions
function _init()
	load_level(1)
end

function _update()
	game_frame+=1

	if game_frame%10==0 and rnd(1)<0.1 then
		create_fly()
	end

	-- update the web
	foreach(web_strands,update_web_strand)
	foreach(web_points,update_web_point)

	-- update the bugs
	foreach(bugs,update_bug)

	-- update the player spider
	update_spider()

	-- get rid of anything that isn't alive anymore
	web_strands=filter_list(web_strands,check_for_web_strand_death)
	web_points=filter_list(web_points,check_for_web_point_death)
	bugs=filter_list(bugs,is_alive)
end

function _draw()
	-- clear the canvas
	camera()
	rectfill(0,0,127,127,bg_color)
	camera(0,-8)

	-- draw bugs in the background
	foreach(bugs,function(bug)
		if bug.z<0 then
			draw_bug(bug)
		end
	end)

	-- draw tiles
	draw_tiles()

	-- draw the web
	foreach(web_strands,draw_web_strand)

	-- draw bugs in the foreground
	foreach(bugs,function(bug)
		if bug.z==0 then
			draw_bug(bug)
		end
	end)

	-- draw the playable spider
	draw_spider()

	-- draw bugs in the far foreground
	foreach(bugs,function(bug)
		if bug.z>0 then
			draw_bug(bug)
		end
	end)

	-- draw the ui
	camera()
	draw_ui()
end


-- constants
levels={
	{
		["spawn_point"]={63,17},
		["bg_color"]=0,
		["tileset"]="carrot",
		["map"]={
			"m77n        vrqn",
			" 45      vtr 66n",
			" 45  qsu   vr67n",
			" 45qsu      o65n",
			" opp        m45 ",
			"i20l         45 ",
			"e000j        45 ",
			"e003f        45 ",
			"g000f        op ",
			"e020f       k20j",
			"e000f      i000f",
			"e003h      e200h",
			"g200j      g003j",
			"cyyydaaaaaacyyyd",
			"wwwwwwwwwwwwwwww"
		}
	}
}

tilesets={
	["carrot"]={128,{240,255, 254,255, 204,204, 204,136, 200,204, 236,255, 204,204, 255,239, 232,254, 255,63, 127,1}}
}

web_types={
	{
		["physics"]={
			["initial_speed"]=1,
			["initial_tautness"]=0.00,
			["dist_between_points"]=5,
			["gravity"]=0.02,
			["friction"]=0.1,
			["elasticity"]=1.65,
			["break_ratio"]=5.00,
			["detatch_from_tile_ratio"]=10.00, -- won't happen
			["spring_force"]=0.25,
			["is_sticky"]=false,
		},
		["render"]={
			["icon_sprite"]=9,
			["is_dashed"]=false
		}
	},
	{
		["physics"]={
			["initial_speed"]=1,
			["initial_tautness"]=0.00,
			["dist_between_points"]=5,
			["gravity"]=0.02,
			["friction"]=0.05,
			["elasticity"]=0.60,
			["break_ratio"]=4.00,
			["detatch_from_tile_ratio"]=2.00,
			["spring_force"]=0.2,
			["is_sticky"]=true,
		},
		["render"]={
			["icon_sprite"]=10,
			["is_dashed"]=true
		}
	}
}


-- all them functions
function load_level(level_num)
	game_frame=0
	bg_color=levels[level_num].bg_color
	reset_tiles()
	load_tiles(levels[level_num].map,tilesets[levels[level_num].tileset])
	web_points={}
	web_strands={}
	spider=create_spider(levels[level_num].spawn_point[1],levels[level_num].spawn_point[2])
end

function reset_tiles()
	tiles={}
	local c
	for c=1,16 do
		local r
		tiles[c]={}
		for r=1,15 do
			tiles[c][r]=false
		end
	end
end

function load_tiles(map,tileset)
	local c
	for c=1,16 do
		local r
		for r=1,15 do
			local s=sub(map[r],c,c)
			if s==" " then
				tiles[c][r]=false
			else
				tiles[c][r]=create_tile(s,tileset,c,r)
			end
		end
	end
end

function create_tile(symbol,tileset,col,row)
	local tile_index=1
	local i
	for i=1,#tile_symbols do
		if symbol==sub(tile_symbols,i,i) then
			tile_index=i
			break
		end
	end
	local is_flipped=(tile_index%2==0)
	local solid_bits={255,255}
	if #tileset[2]>=2*ceil(tile_index/2) then
		solid_bits={tileset[2][2*ceil(tile_index/2)-1],tileset[2][2*ceil(tile_index/2)]}
	end
	if is_flipped then
		for i=1,2 do
			local new_bits=0
			local j
			for j=1,#tile_flip_matrix do
				if band(solid_bits[i],2^(j-1))>0 then
					new_bits+=tile_flip_matrix[j]
				end
			end
			solid_bits[i]=new_bits
		end
	end
	return {
		["sprite"]=tileset[1]+ceil(tile_index/2)-1,
		["is_flipped"]=is_flipped,
		["solid_bits"]=solid_bits
	}
end

function draw_tiles()
	local c
	for c=1,16 do
		local r
		for r=1,15 do
			if tiles[c][r] then
				draw_tile(tiles[c][r],c,r)
			end
		end
	end
end

function draw_tile(tile,col,row)
	local x=8*col-8
	local y=8*row-8
	spr(tile.sprite,x,y,1,1,tile.is_flipped)
	-- uncomment to see terrain "hitboxes"
	-- if game_frame%16<8 then
	-- 	local x2
	-- 	for x2=0,3 do
	-- 		local y2
	-- 		for y2=0,3 do
	-- 			local bit=1+x2+4*y2
	-- 			local should_draw
	-- 			if bit>8 then
	-- 				should_draw=band(2^(bit-9),tile.solid_bits[2])>0
	-- 			else
	-- 				should_draw=band(2^(bit-1),tile.solid_bits[1])>0
	-- 			end
	-- 			if should_draw then
	-- 				rectfill(x+2*x2,y+2*y2,x+2*x2+1,y+2*y2+1,7)
	-- 			end
	-- 		end
	-- 	end
	-- end
end

function create_spider(x,y)
	return {
		["x"]=x,
		["y"]=y,
		["vx"]=0,
		["vy"]=0,
		["facing_x"]=0,
		["facing_y"]=1,
		["is_on_tile"]=false,
		["was_on_tile"]=false,
		["is_on_web"]=false,
		["was_on_web"]=false,
		["is_alive"]=true,
		["web_type"]=1,
		["spun_web_start_point"]=nil,
		["attached_web_strand"]=nil,
		["frames_to_web_spin"]=0,
		["is_spinning_web"]=false,
		["is_web"]=false,
		["webbing"]=45,
		["max_webbing"]=45,
		["stationary_frames"]=0,
		["bug_interact_dist"]=12,
		["nearest_interactive_bug"]=nil,
		["frames_since_walk_sound"]=99,
		-- constants
		["gravity"]=0.05,
		["web_attract_dist"]=3,
		["web_attach_dist"]=10,
		["mass"]=4,
		["move_speed"]=1,
		["max_speed"]=2
	}
end

function update_spider()
	if not spider.is_alive then
		return
	end

	spider.frames_since_walk_sound+=1

	if spider.stationary_frames>0 then
		spider.stationary_frames-=1
	end

	spider.was_on_tile = spider.is_on_tile
	spider.was_on_web = spider.is_on_web

	-- figure out if the spider is walking on a tile
	spider.is_on_tile=is_solid_tile_at_spider()

	-- figure out if the spider is walking on web
	local web_x
	local web_y
	local web_square_dist
	web_x,web_y,web_square_dist=calc_closest_spot_on_web(spider.x,spider.y,false)
	spider.is_on_web=web_x!=nil and web_y!=nil and web_square_dist<=spider.web_attract_dist*spider.web_attract_dist

	-- spawn web points/strands while z is held
	if spider.is_spinning_web and spider.webbing>0 then
		spider.frames_to_web_spin-=1
		if spider.frames_to_web_spin<=0 then
			spider.webbing-=1
			spider.frames_to_web_spin=web_types[spider.web_type].physics.dist_between_points
			local mid_point=create_web_point_at_spider(false)
			create_web_strand(spider.attached_web_strand.end_obj,mid_point)
			spider.attached_web_strand.is_alive=false
			spider.attached_web_strand=create_web_strand(spider,mid_point)
		end
	end

	-- if the spider's web gets cut off at the base, it's no longer spinning web
	if spider.attached_web_strand and not spider.attached_web_strand.is_alive then
		spider.attached_web_strand=nil
		spider.spun_web_start_point=nil
		spider.is_spinning_web=false
		mark_all_points_as_not_being_spun()
	end

	-- poison/eat the nearest bug when z is pressed
	if spider.nearest_interactive_bug and (spider.is_on_tile or spider.is_on_web) and not spider.is_spinning_web and btnp(4) then
		if not spider.nearest_interactive_bug.is_poisoned then
			spider.stationary_frames=15
			spider.nearest_interactive_bug.is_poisoned=true
		else
			spider.nearest_interactive_bug.is_alive=false
			spider.webbing=min(spider.webbing+12,spider.max_webbing)
		end

	-- start spinning web when z is first pressed
	elseif not spider.attached_web_strand and btnp(4) and spider.webbing>0 then
		spider.webbing-=1
		spider.is_spinning_web=true
		spider.frames_to_web_spin=web_types[spider.web_type].physics.dist_between_points/2
		local start_point
		local square_dist
		start_point,square_dist=calc_closest_web_point(spider.x,spider.y,true,nil,false)
		-- if we can't find a point nearby to attach to, create a new one
		if not start_point or square_dist>=spider.web_attach_dist*spider.web_attach_dist or
			(spider.is_on_tile and not start_point.has_been_anchored) then
			start_point=create_web_point_at_spider(is_solid_tile_at_spider())
		end
		spider.attached_web_strand=create_web_strand(spider,start_point)
		spider.spun_web_start_point=start_point

	-- stop spinning web when z is released
	elseif spider.is_spinning_web and not btn(4) then
		spider.is_spinning_web=false

	-- cut/place the end of the strand when z is pressed again
	elseif spider.attached_web_strand and not spider.is_spinning_web and btnp(4) then
		local end_point
		local square_dist
		end_point,square_dist=calc_closest_web_point(spider.x,spider.y,true,spider.spun_web_start_point.id,false)
		-- if we can't find a point nearby to attach to, create a new one
		if not end_point or square_dist>=spider.web_attach_dist*spider.web_attach_dist or
			(spider.is_on_tile and not end_point.has_been_anchored) then
			end_point=create_web_point_at_spider(is_solid_tile_at_spider())
		end
		create_web_strand(spider.attached_web_strand.end_obj,end_point)
		spider.attached_web_strand.is_alive=false
		spider.attached_web_strand=nil
		spider.spun_web_start_point=nil
		mark_all_points_as_not_being_spun()
	end

	-- press x switch web types when not spinning
	if not spider.is_spinning_web and btnp(5) then
		spider.web_type=1+(spider.web_type)%#web_types
	end

	-- move the spider while on tile or web
	if spider.is_on_tile or spider.is_on_web then
		spider.vx=0
		spider.vy=0
		if spider.stationary_frames<=0 then
			-- arrow keys move the spider
			if btn(0) then
				spider.vx-=spider.move_speed
			end
			if btn(1) then
				spider.vx+=spider.move_speed
			end
			if btn(2) then
				spider.vy-=spider.move_speed
			end
			if btn(3) then
				spider.vy+=spider.move_speed
			end
			-- make sure you don't move faster when moving diagonally
			if spider.vx!=0 and vy!=0 then
				spider.vx*=sqrt(0.5)
				spider.vy*=sqrt(0.5)
			end
		end

		-- when on web, we are pulled towards it
		if spider.is_on_web and not spider.is_on_tile then
			local dx=web_x-spider.x
			local dy=web_y-spider.y
			spider.x+=dx/(2+spider.web_attract_dist)
			spider.y+=dy/(2+spider.web_attract_dist)
		end

	-- otherwise, fall!
	else
		spider.vy+=spider.gravity
	end

	-- limit velocity
	spider.vx=mid(-spider.max_speed,spider.vx,spider.max_speed)
	spider.vy=mid(-spider.max_speed,spider.vy,spider.max_speed)

	-- finally, apply that velocity
	spider.x+=spider.vx
	spider.y+=spider.vy

	-- find nearest bug
	spider.nearest_interactive_bug=nil
	local nearest_bug_square_dist=nil
	foreach(bugs,function(bug)
		local square_dist=calc_square_dist_between_points(spider.x,spider.y,bug.x,bug.y)
		if bug.is_alive and bug.caught_web_point and (not bug.is_poisoned or bug.has_succumbed_to_poison) and square_dist<=spider.bug_interact_dist*spider.bug_interact_dist then
			if not spider.nearest_interactive_bug or square_dist<nearest_bug_square_dist then
				spider.nearest_interactive_bug=bug
				nearest_bug_square_dist=square_dist
			end
		end
	end)

	-- spider.nearest_interactive_bug=nil
	-- local nearest_bug_square_dist=nil
	-- foreach(bugs,function(bug)
	-- 	-- local square_dist=calc_square_dist_between_points(spider.x,spider.y,bug.x,bug.y)
	-- 	-- if bug.is_alive and bug.caught_web_point and -- not bug.is_poisoned and
	-- 	-- 	-- square_dist<=spider.bug_interact_dist*spider.bug_interact_dist and
	-- 	-- 	not spider.nearest_interactive_bug or square_dist<nearest_bug_square_dist then
	-- 	-- 	-- spider.nearest_interactive_bug=bug
	-- 	-- 	-- nearest_bug_square_dist=square_dist
	-- 	-- end
	-- end)

	-- keep track of which direction the spider is facing
	if spider.vx!=0 or spider.vy!=0 then
		local speed=sqrt(spider.vx*spider.vx+spider.vy*spider.vy)
		spider.facing_x=spider.vx/speed
		spider.facing_y=spider.vy/speed
	end

	-- keep dat spider in bounds so long as she isn't freefalling
	if spider.is_on_tile then
		spider.x=mid(0,spider.x,127)
		spider.y=mid(0,spider.y,119)
	end

	-- if the spider does wind up out of bounds, she's dead :'(
	if spider.x<-8 or spider.x>135 or spider.y<-200 or spider.y>127 then
		spider.is_alive=false
	end
end

function draw_spider()
	if spider.is_alive then
		local sprite=3
		local dx=-4
		local dy=-4
		local flipped_x=false
		local flipped_y=false
		if spider.facing_x<-0.4 then
			flipped_x=true
			dx=-3
		elseif spider.facing_x<0.4 then
			sprite=0
		end
		if spider.facing_y<-0.4 then
			flipped_y=true
			dy=-3
		elseif spider.facing_y<0.4 then
			sprite=6
		end
		-- clip through the spider's walk cycle
		if (spider.is_on_tile or spider.is_on_web) and (spider.vx!=0 or spider.vy!=0) then
			if game_frame%10>=5 then
				sprite+=2
			else
				sprite+=1
			end
		end
		-- draw the spider's sprite
		spr(sprite,spider.x+dx,spider.y+dy,1,1,flipped_x,flipped_y)
	end
	-- play a walk sound too
	if (spider.is_on_tile or spider.is_on_web) and (spider.vx!=0 or spider.vy!=0) and spider.frames_since_walk_sound>6 then
		sfx(0,3)
		spider.frames_since_walk_sound=0
	end
	if (spider.was_on_tile or spider.was_on_web) and not spider.is_on_tile and not spider.is_on_web then
		sfx(1,3)
	end
end

next_web_point_id=0
function create_web_point_at_spider(is_attached_to_tile)
	local physics=web_types[spider.web_type].physics
	local web_point={
		["id"]=next_web_point_id,
		["x"]=spider.x,
		["y"]=spider.y,
		["vx"]=spider.vx-physics.initial_speed*spider.facing_x,
		["vy"]=-0+spider.vy-physics.initial_speed*spider.facing_y,
		["is_alive"]=true,
		["is_attached_to_tile"]=is_attached_to_tile,
		["is_being_spun"]=true,
		["has_been_anchored"]=is_attached_to_tile,

		["num_strands"]=1, -- so it is alive the first frame
		-- constants
		["is_web"]=true,
		["web_type"]=spider.web_type,
		["mass"]=1,
		["physics"]=physics,
		["render"]=web_types[spider.web_type].render
	}
	if is_attached_to_tile then
		web_point.vx=0
		web_point.vy=0
	end
	next_web_point_id+=1
	add(web_points,web_point)
	return web_point
end

function update_web_point(web_point)
	local physics=web_point.physics

	-- points not attached to any strands are dead
	if web_point.num_strands<=0 then
		web_point.is_alive=false
	end
	web_point.num_strands=0

	-- add some gravity
	web_point.vy+=physics.gravity

	if web_point.is_attached_to_tile then
		web_point.vx=0
		web_point.vy=0
	end

	-- apply velocity
	web_point.x+=web_point.vx
	web_point.y+=web_point.vy

	-- apply friction
	web_point.vx*=(1-physics.friction)
	web_point.vy*=(1-physics.friction)
end

function check_for_web_point_death(web_point)
	if web_point.x<-8 or web_point.x>136 or web_point.y<-8 or web_point.y>127 then
		web_point.is_alive=false
	end
	return web_point.is_alive
end

function create_web_strand(start_obj,end_obj)
	local physics=web_types[start_obj.web_type].physics
	local base_length=physics.dist_between_points/(1+physics.initial_tautness*physics.elasticity)
	local web_strand={
		["start_obj"]=start_obj,
		["end_obj"]=end_obj,
		["is_alive"]=true,
		["base_length"]=base_length,
		["stretched_length"]=base_length,
		["break_length"]=base_length*physics.break_ratio,
		["detatch_length"]=base_length*physics.detatch_from_tile_ratio,
		["percent_elasticity_remaining"]=1,
		-- constants
		["web_type"]=start_obj.web_type,
		["physics"]=physics,
		["render"]=web_types[start_obj.web_type].render
	}
	add(web_strands,web_strand)
	return web_strand
end

function update_web_strand(web_strand)
	local start_obj=web_strand.start_obj
	local end_obj=web_strand.end_obj

	-- keep track of the number of strands attached to each point
	if start_obj.is_web then
		start_obj.num_strands+=1
	end
	if end_obj.is_web then
		end_obj.num_strands+=1
	end

	-- find the current length of the strand
	local dx=end_obj.x-start_obj.x
	local dy=end_obj.y-start_obj.y
	local len=sqrt(dx*dx+dy*dy)

	-- if the strand stretches too far, it loses elasticity
	local min_len=web_strand.base_length*(1+web_strand.physics.elasticity)
	local max_len=web_strand.break_length -- not multiplied by elasticity b/c it is 0 at the break length
	if len>min_len then
		local percent_elasticity=mid(0,1-((len-min_len)/(max_len-min_len)),1)
		if percent_elasticity<=web_strand.percent_elasticity_remaining then
			web_strand.percent_elasticity_remaining=percent_elasticity
			web_strand.stretched_length=len/(1+web_strand.physics.elasticity*percent_elasticity)
		end
	end

	-- bring the two points close to each other
	if len>web_strand.stretched_length and web_strand.percent_elasticity_remaining>0 then
		local elastic_dist=len-web_strand.stretched_length
		local f=elastic_dist*web_strand.physics.spring_force
		local m1=start_obj.mass
		local m2=end_obj.mass
		start_obj.vx+=f*(m2/m1)*(dx/len)
		start_obj.vy+=f*(m2/m1)*(dy/len)
		end_obj.vx-=f*(m1/m2)*(dx/len)
		end_obj.vy-=f*(m1/m2)*(dy/len)
	end

	-- strands transfer has_been_anchored status
	if start_obj.is_web and end_obj.is_web then
		if start_obj.has_been_anchored then
			end_obj.has_been_anchored = true
		end
		if end_obj.has_been_anchored then
			start_obj.has_been_anchored = true
		end
	end

	-- strands may detatch from tile
	if len>web_strand.detatch_length then
		if start_obj.is_web then
			start_obj.is_attached_to_tile=false
		end
		if end_obj.is_web then
			end_obj.is_attached_to_tile=false
		end
	end
end

function draw_web_strand(web_strand)
	if web_strand.percent_elasticity_remaining>0.7 then
		color(7)
	elseif web_strand.percent_elasticity_remaining>0.5 then
		color(15)
	elseif web_strand.percent_elasticity_remaining>0.2 then
		color(9)
	else
		color(8)
	end
	local start_obj=web_strand.start_obj
	local end_obj=web_strand.end_obj
	if web_strand.render.is_dashed then
		local dx=end_obj.x-start_obj.x
		local dy=end_obj.y-start_obj.y
		local steps=flr(max(abs(dx),abs(dy))+0.9)
		local i
		for i=1,steps,2 do
			pset(start_obj.x+dx*i/steps,start_obj.y+dy*i/steps)
		end
	else
		line(start_obj.x,start_obj.y,end_obj.x,end_obj.y)
	end
end

function check_for_web_strand_death(web_strand)
	if not web_strand.start_obj.is_alive or not web_strand.end_obj.is_alive then
		web_strand.is_alive=false
	elseif web_strand.percent_elasticity_remaining<=0 then
		web_strand.is_alive=false
	end
	return web_strand.is_alive
end

function create_fly()
	local x
	local y
	x,y=find_random_blank_spot()
	local fly={
		["species"]="fly",
		["x"]=x,
		["y"]=y-9,
		["z"]=-80,
		["vx"]=0,
		["vy"]=0.1,
		["vz"]=1,
		["is_alive"]=true,
		["is_poisoned"]=false,
		["has_succumbed_to_poison"]=false,
		["frames_poisoned"]=0,
		["frames_caught"]=0,
		["caught_web_point"]=nil,
		-- constants
		["animation"]={
			["distant"]={16},
			["far"]={17,18},
			["mid"]={19,20},
			["close"]={21,22},
			["caught"]={23,24,23,23,20,24},
			["succumbed"]={25}
		},
		["strength"]=0.5,
		["max_strength"]=2.5,
		["web_catch_dist"]=5,
		["frame_rate"]=4
	}
	add(bugs,fly)
	return fly
end

function update_bug(bug)
	-- accelerate upwards at the end
	if bug.z>20 then
		bug.vy-=0.1
	end

	-- bugs grow stronger over time, or weaker over time when poisoned
	if bug.caught_web_point and bug.frames_caught%30==0 then
		if bug.is_poisoned then
			bug.strength=max(0,bug.strength-0.25)
			if bug.strength<0.5 then
				bug.frame_rate=45
			end
		else
			bug.strength=min(bug.strength+0.125,bug.max_strength)
		end
	end

	-- once the bug is fully drained, it will succumb to the poison
	if bug.is_poisoned and not bug.has_succumbed_to_poison then
		bug.frames_poisoned+=1
		if bug.frames_poisoned>120 and bug.strength<=0 then
			bug.has_succumbed_to_poison=true
		end
	end

	-- once the bug enters the foreground, it can be caught
	if 0<=bug.z and bug.z<20 then
		if bug.caught_web_point then
			-- the bug is still caught in the web
			if bug.caught_web_point.is_alive then
				bug.frames_caught+=1
				bug.x=bug.caught_web_point.x
				bug.y=bug.caught_web_point.y
				-- the bug struggles to get free
				if not bug.has_succumbed_to_poison and game_frame%4==0 and rnd(1)<0.4 then
					local dir=rnd(20)
					if dir>15 then -- extra change of moving up
						bug.caught_web_point.vy-=bug.strength
					elseif dir>10 then -- extra chance of moving up and to the left
						bug.caught_web_point.vx-=bug.strength*0.7
						bug.caught_web_point.vy-=bug.strength*0.7
					elseif dir>5 then -- extra chance of moving up and to the right
						bug.caught_web_point.vx+=bug.strength*0.7
						bug.caught_web_point.vy-=bug.strength*0.7
					elseif dir>4 then
						bug.caught_web_point.vx-=bug.strength*0.7
						bug.caught_web_point.vy+=bug.strength*0.7
					elseif dir>3 then
						bug.caught_web_point.vx+=bug.strength*0.7
						bug.caught_web_point.vy+=bug.strength*0.7
					elseif dir>2 then
						bug.caught_web_point.vx+=bug.strength
					elseif dir>1 then
						bug.caught_web_point.vx-=bug.strength
					else
						bug.caught_web_point.vy+=bug.strength
					end
				end
			-- the bug goes poof if it dies and the web it's on breaks
			elseif bug.has_succumbed_to_poison then
				bug.is_alive=false
			-- the bug got away
			else
				bug.caught_web_point=nil
				bug.vz=1
				bug.z=20
			end
		else
			local web_point
			local square_dist
			web_point,square_dist=calc_closest_web_point(bug.x,bug.y,true,nil,true)
			-- the bug got caught in the web
			if web_point and square_dist<=bug.web_catch_dist*bug.web_catch_dist then
				bug.caught_web_point=web_point
				bug.x=web_point.x
				bug.y=web_point.y
				bug.z=0
				bug.vx=0
				bug.vy=0
				bug.vz=0
			end
		end
	end

	-- apply velocity
	bug.x+=bug.vx
	bug.y+=bug.vy
	bug.z+=bug.vz
	
	-- if the bug goes out of bounds, it's dead
	if bug.x<-8 or bug.x>135 or bug.y<-16 or bug.y>127 then
		bug.is_alive=false
	end
end

function draw_bug(bug)
	local anim
	if bug.has_succumbed_to_poison then
		anim=bug.animation.succumbed
	elseif bug.caught_web_point then
		anim=bug.animation.caught
	elseif bug.z<-40 then
		anim=bug.animation.distant
	elseif bug.z<0 then
		anim=bug.animation.far
	elseif bug.z<40 then
		anim=bug.animation.mid
	else
		anim=bug.animation.close
	end
	spr(calc_sprite(anim,bug.frame_rate),bug.x-4,bug.y-4)
	-- draw poison bubbles above the bug
	if bug.is_poisoned and not bug.has_succumbed_to_poison then
		local poison_sprite=11
		if game_frame%30>15 then
			poison_sprite=12
		end
		spr(poison_sprite,bug.x-4,bug.y-8)
	end
end

function draw_ui()
	rectfill(0,0,127,7,0)
	if spider.is_spinning_web then
		color(7)
	else
		color(5)
	end
	rectfill(1,2,1+spider.webbing,5)
	rect(1,1,2+spider.max_webbing,6)
	spr(web_types[spider.web_type].render.icon_sprite,49,0)

	-- draw prompt over the nearest caught bug
	if spider.nearest_interactive_bug then
		local sprite
		if not spider.nearest_interactive_bug.is_poisoned then
			sprite=13
		else
			sprite=45
		end
		if game_frame%30>15 then
			sprite+=1
		end
		spr(sprite,spider.nearest_interactive_bug.x-4,spider.nearest_interactive_bug.y-4)
	end
end


-- helper functions
function find_random_blank_spot()
	local blank_tiles={}
	local c
	for c=2,15 do
		local r
		for r=2,14 do
			if not tiles[c][r] then
				add(blank_tiles,{c,r})
			end
		end
	end
	local random_tile=blank_tiles[flr(1+rnd(#blank_tiles))]
	return 8*random_tile[1]-2-rnd(4),8*random_tile[2]-2-rnd(4)
end

function mark_all_points_as_not_being_spun()
	foreach(web_points,function(web_point)
		web_point.is_being_spun=false
	end)
end

function is_solid_tile_at_spider()
	return is_solid_tile_at(spider.x,spider.y)
end

function is_solid_tile_at(x,y)
	local c=1+flr(x/8)
	local r=1+flr(y/8)
	if tiles[c] and tiles[c][r] then
		-- turn the position into a bit 1 to 16
		local bit=1+flr(x/2)%4+4*(flr(y/2)%4)
		-- check that against the tile's solid_bits
		if bit>8 then
			return band(2^(bit-9),tiles[c][r].solid_bits[2])>0
		else
			return band(2^(bit-1),tiles[c][r].solid_bits[1])>0
		end
	end
	return false
end

function filter_list(list,func)
	local l={}
	local i
	for i=1,#list do
		if func(list[i]) then
			add(l,list[i])
		end
	end
	return l
end

function is_alive(x)
	return x.is_alive
end

function calc_square_dist_between_points(x1,y1,x2,y2)
	local dx=x2-x1
	local dy=y2-y1
	return dx*dx+dy*dy
end

function calc_closest_point_on_line(x1,y1,x2,y2,cx,cy)
	local match_x
	local match_y
	local dx=x2-x1
	local dy=y2-y1
	-- if the line is nearly vertical, it's easy
	if 0.1>dx and dx>-0.1 then
		match_x=x1
		match_y=cy
	-- if the line is nearly horizontal, it's also easy
	elseif 0.1>dy and dy>-0.1 then
		match_x=cx
		match_y=y1
	--otherwise we have a bit of math to do...
	else
		-- find equation of the line y=mx+b
		local m=dy/dx
		local b=y1-m*x1 -- b=y-mx
		-- find reverse equation from circle
		local m2=-dx/dy
		local b2=cy-m2*cx -- b=y-mx
		-- figure out where their y-values are the same
		match_x=(b2-b)/(m-m2) -- mx+b=m2x+b2 --> x=(b2-b)/(m-m2)
		-- plug that into either formula to get the y-value at that x-value
		match_y=m*match_x+b -- y=mx+b
	end
	if mid(x1,match_x,x2)==match_x and mid(y1,match_y,y2)==match_y then
		return match_x,match_y
	else
		return nil,nil
	end
end

function calc_closest_web_point(x,y,allow_freefalling,exception_web_point_id,sticky_only)
	local i
	local square_dist
	local closest_web_point=nil
	local closest_square_dist=nil
	for i=1,#web_points do
		if not web_points[i].is_being_spun and
			(not exception_web_point_id or web_points[i].id!=exception_web_point_id) and
			(allow_freefalling or web_points[i].has_been_anchored) and
			(not sticky_only or web_points[i].physics.is_sticky) then
			square_dist=calc_square_dist_between_points(x,y,web_points[i].x,web_points[i].y)
			if closest_square_dist==nil or square_dist<closest_square_dist then
				closest_web_point=web_points[i]
				closest_square_dist=square_dist
			end
		end
	end
	return closest_web_point,closest_square_dist
end

function calc_closest_spot_on_web(x,y,allow_freefalling)
	local closest_web_point
	local closest_square_dist
	closest_web_point,closest_square_dist=calc_closest_web_point(x,y,allow_freefalling,nil,false)
	local closest_x=nil
	local closest_y=nil
	if closest_web_point then
		closest_x=closest_web_point.x
		closest_y=closest_web_point.y
	end
	local i
	for i=1,#web_strands do
		if not web_strands[i].start_obj.is_being_spun and
			not web_strands[i].end_obj.is_being_spun and
			(allow_freefalling or (web_strands[i].start_obj.has_been_anchored and web_strands[i].end_obj.has_been_anchored)) then
			local x2
			local y2
			x2,y2=calc_closest_point_on_line(
				web_strands[i].start_obj.x,web_strands[i].start_obj.y,
				web_strands[i].end_obj.x,web_strands[i].end_obj.y,
				x,y)
			if x2!=nil and y2!=nil then
				local square_dist=calc_square_dist_between_points(x,y,x2,y2)
				if closest_square_dist==nil or square_dist<closest_square_dist then
					closest_x=x2
					closest_y=y2
					closest_square_dist=square_dist
				end
			end
		end
	end
	return closest_x,closest_y,closest_square_dist
end

function calc_sprite(anim,frame_rate)
	return anim[1+flr(game_frame/frame_rate)%#anim]
end

function ceil(n)
	return -flr(-n)
end

__gfx__
0000700000007000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000dddd0000000000aa00aaaa
00077700000777000007770007770700077700700777070000700070000707000070007077500550055005500000000000200000000dd00000dd0000a0dd0a0a
0707770700077707070777000777770007777707077777000007070000070700000707007777005007000050000002000222000000d22d000d22d0d00d22d0d0
007777700777777000777777077777770777777007777777077771700777717007777170777777000007000000020000002000000d2222d00d222dd00d2727d0
000777000007770000077700007771700077717000777170777777007777770077777700007777770000070000202000000002000d7777d00d7777d00d2727d0
0071717007717170007171770777170707771707007717070777717007777170077771700500777705000057000200000000000000dd7d000d2270d20d2270d2
070707070007070707070700000770000007700007077000000707000007070000070700055005770550055000000000000000000007000000d70002a0d70702
000000000000000000000000000707000007070000700700007000700070007000070700000000000000000000000000000000000077770000777700aa07070a
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000066006600000000000000000000000000006600000060000000dd000000000000000000000000000000000000000000000000000
000000000060060000000000066cc660006cc600066ccc66000ccc00000cc000006cc00000022000000000000000000000000000000000000000000000000000
00000000000cc000006cc60000cccc0006cccc6006ccccc600ccccc000cccc0000cccc0000222200000000000000000000000000000000000000000000000000
0000c000000cc000000cc00000cccc0000cccc0000ccccc006ccccc600cccc6006cccc00002222d0000000000000000000000000000000000000000000000000
000000000000000000000000000cc000000cc00000ccccc006ccccc6000cc600006cc00000022d00000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000ccc00006ccc60000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fff00000ff0000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009ffff0009f00000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003bbbb0003b00000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000247777002477770000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099ff700099f0700000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000007000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777000077770000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000002222200004499000044990004000400000449000033bb3bb3bbbb0000000333b333bb333b33b34444444499999999999999999999999933b3bb33
000000000022242400004499000049440000404900004444000033b33bbbbbbb0000033b3bbbbbbbbbbbbb304442444422222222999999999999999933b33b3b
22222222222242420000494400004499000404490044449900003bb33b3bbb3b000333bbbbbbbbbbb33b3300444444444242424299999999999944993bb3bb33
44444244424244440000449900004449000004440444949900003bbb3b3b3b3b0003bb3bbbbb33b33b333000424442442444242499999999994999993bb33b3b
44444444244424240000449900440494000044994449994900003bbb33bb33bb0033b3bbbbb3bb33333000004444244444444244999999999994444933b33b3b
424444444422444200004449040000490000444944449999000033b3333bb3bb033b33bb3b33333330000000444244422424424499999999999999993bb33b33
444444244444442400004944000000440000094449944499000033bb0333333b3333bbbb33333000000000002422242442442424999999999999999933b3bb33
4444444444444444000044990000000400004499449999990000033b0033b3333b3bbbbb33300000000000002222222244444444999999999999999933b33b3b
33bbb3bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
333bb33b080008000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800
3b3bbb33008080000080800000808000008080000080800000808000008080000080800000808000008080000080800000808000008080000080800000808000
3b3bbbb3000800000008000000080000000800000008000000080000000800000008000000080000000800000008000000080000000800000008000000080000
3333bbb3008080000080800000808000008080000080800000808000008080000080800000808000008080000080800000808000008080000080800000808000
3b33bbb3080008000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800
33b33b3b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33bbb33b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800
00808000008080000080800000808000008080000080800000808000008080000080800000808000008080000080800000808000008080000080800000808000
00080000000800000008000000080000000800000008000000080000000800000008000000080000000800000008000000080000000800000008000000080000
00808000008080000080800000808000008080000080800000808000008080000080800000808000008080000080800000808000008080000080800000808000
08000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800
00808000008080000080800000808000008080000080800000808000008080000080800000808000008080000080800000808000008080000080800000808000
00080000000800000008000000080000000800000008000000080000000800000008000000080000000800000008000000080000000800000008000000080000
00808000008080000080800000808000008080000080800000808000008080000080800000808000008080000080800000808000008080000080800000808000
08000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800080008000800
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0106000021520215151d5201d5152d0002d0002f0002f0002d0002d0052d0002d00500000000002d0002d0002b0002b0052b0002b00500000000002b0002b0002a0002a0002a0002a000300002f0002d0002b000
01060000215302b5312b5312b5212b5110d5012900026000215002b5012b5012b5012b5012b50128000240002900024000280000000000000000000000000000000000000000000000000000000000000002d000
010d00001f0001d6002b0002b0002d000280002d0002f000300002f0002d0002b000290002800000000000000000000000000000000000000000000000000000000000000000000000000000000000000002f000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

