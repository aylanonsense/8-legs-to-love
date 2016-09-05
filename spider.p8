pico-8 cartridge // http://www.pico-8.com
version 8
__lua__

-- todo
-- flies shouldn't be able to be caught by sticky things that are anchored on tiles (no way to shake free)
-- title screen / game over screen
-- fix not always being able to attach web to web
-- fix unbreakable traps by laying sticky web on top of structural web

-- game vars
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
		["map"]={
			"qttr        z21r",
			" 34      zx2 ssr",
			" 34  1wy   z2str",
			" 341wy      os4r",
			" opp        q34 ",
			"kufn         34 ",
			"gfffl        34 ",
			"gffvh        34 ",
			"ifffh        op ",
			"gfufh       mufl",
			"gfffh      kfffh",
			"gffvj      guffj",
			"iuffl      iffvl",
			"ceeedbbbbbbceeed",
			"aaaaaaaaaaaaaaaa"
		}
	}
}

tile_types={
	["0"]={
		["sprite"]=0,
		["is_flipped"]=false,
		-- {upper_half,lower_half}
		["solid_bits"]={255,255}
	},
	["a"]={["sprite"]=48,["is_flipped"]=false,["solid_bits"]={255,255}},
	["b"]={["sprite"]=49,["is_flipped"]=false,["solid_bits"]={240,255}},
	["c"]={["sprite"]=50,["is_flipped"]=false,["solid_bits"]={254,255}},
	["d"]={["sprite"]=50,["is_flipped"]=true,["solid_bits"]={247,255}},
	["e"]={["sprite"]=51,["is_flipped"]=false,["solid_bits"]={255,255}},
	["f"]={["sprite"]=52,["is_flipped"]=false,["solid_bits"]={255,255}},
	["g"]={["sprite"]=53,["is_flipped"]=false,["solid_bits"]={204,204}},
	["h"]={["sprite"]=53,["is_flipped"]=true,["solid_bits"]={51,51}},
	["i"]={["sprite"]=54,["is_flipped"]=false,["solid_bits"]={204,136}},
	["j"]={["sprite"]=54,["is_flipped"]=true,["solid_bits"]={51,17}},
	["k"]={["sprite"]=55,["is_flipped"]=false,["solid_bits"]={200,204}},
	["l"]={["sprite"]=55,["is_flipped"]=true,["solid_bits"]={49,51}},
	["m"]={["sprite"]=56,["is_flipped"]=false,["solid_bits"]={236,255}},
	["n"]={["sprite"]=56,["is_flipped"]=true,["solid_bits"]={115,255}},
	["o"]={["sprite"]=57,["is_flipped"]=false,["solid_bits"]={255,239}},
	["p"]={["sprite"]=57,["is_flipped"]=true,["solid_bits"]={255,127}},
	["q"]={["sprite"]=58,["is_flipped"]=false,["solid_bits"]={204,204}},
	["r"]={["sprite"]=58,["is_flipped"]=true,["solid_bits"]={51,51}},
	["s"]={["sprite"]=59,["is_flipped"]=false,["solid_bits"]={255,255}},
	["t"]={["sprite"]=59,["is_flipped"]=true,["solid_bits"]={255,255}},
	["u"]={["sprite"]=41,["is_flipped"]=false,["solid_bits"]={255,255}},
	["v"]={["sprite"]=41,["is_flipped"]=true,["solid_bits"]={255,255}},
	["w"]={["sprite"]=61,["is_flipped"]=false,["solid_bits"]={255,63}},
	["x"]={["sprite"]=61,["is_flipped"]=true,["solid_bits"]={255,207}},
	["y"]={["sprite"]=62,["is_flipped"]=false,["solid_bits"]={127,1}},
	["z"]={["sprite"]=62,["is_flipped"]=true,["solid_bits"]={239,8}},
	["1"]={["sprite"]=63,["is_flipped"]=false,["solid_bits"]={232,254}},
	["2"]={["sprite"]=63,["is_flipped"]=true,["solid_bits"]={113,247}},
	["3"]={["sprite"]=60,["is_flipped"]=false,["solid_bits"]={255,255}},
	["4"]={["sprite"]=60,["is_flipped"]=true,["solid_bits"]={255,255}},
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
	load_tiles(levels[level_num].map)
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

function load_tiles(map)
	local c
	for c=1,16 do
		local r
		for r=1,15 do
			local s=sub(map[r],c,c)
			if s==" " then
				tiles[c][r]=false
			else
				tiles[c][r]=create_tile(s,c,r)
			end
		end
	end
end

function create_tile(symbol,col,row)
	return {
		["sprite"]=tile_types[symbol].sprite,
		["is_flipped"]=tile_types[symbol].is_flipped,
		["solid_bits"]=tile_types[symbol].solid_bits
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
	-- local x2
	-- for x2=0,3 do
	-- 	local y2
	-- 	for y2=0,3 do
	-- 		local bit=1+x2+4*y2
	-- 		local should_draw
	-- 		if bit>8 then
	-- 			should_draw=band(2^(bit-9),tile.solid_bits[2])>0
	-- 		else
	-- 			should_draw=band(2^(bit-1),tile.solid_bits[1])>0
	-- 		end
	-- 		if should_draw then
	-- 			rectfill(x+2*x2,y+2*y2,x+2*x2+1,y+2*y2+1,7)
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

	if spider.stationary_frames>0 then
		spider.stationary_frames-=1
	end

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

__gfx__
0000700000007000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000dddd000000000000000000
00077700000777000007770007770700077700700777070000700070000707000070007077500550055005500000000000200000000dd00000dd000000000000
0707770700077707070777000777770007777707077777000007070000070700000707007777005007000050000002000222000000d22d000d22d0d000000000
007777700777777000777777077777770777777007777777077771700777717007777170777777000007000000020000002000000d2222d00d222dd000000000
000777000007770000077700007771700077717000777170777777007777770077777700007777770000070000202000000002000d7777d00d7777d000000000
0071717007717170007171770777170707771707007717070777717007777170077771700500777705000057000200000000000000dd7d000d2270d200000000
070707070007070707070700000770000007700007077000000707000007070000070700055005770550055000000000000000000007000000d7000200000000
00000000000000000000000000070700000707000070070000700070007000700007070000000000000000000000000000000000007777000077770000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000000000000000
000000000000000000000000066006600000000000000000000000000006600000060000000dd00000000000000000000000000000bbb0000030000000000000
000000000060060000000000066cc660006cc600066ccc66000ccc00000cc000006cc00000022000000000000000000000000000088b8f000333200000000000
00000000000cc000006cc60000cccc0006cccc6006ccccc600ccccc000cccc0000cccc00002222000000000000000000000000000f8888000032220000000000
0000c000000cc000000cc00000cccc0000cccc0000ccccc006ccccc600cccc6006cccc00002222d0000000000000000000000000087777000077770000000000
000000000000000000000000000cc000000cc00000ccccc006ccccc6000cc600006cc00000022d00000000000000000000000000008870000022700000000000
0000000000000000000000000000000000000000000ccc00006ccc6000000000000000000000000000000000000000000000000000f780000027000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777000077770000000000
00000000000000000000000000000000000000000000000000000000000000000000000099999999000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000999999990000000000000000000000000fff00000ff0000000000000
000000000000000000000000000000000000000000000000000000000000000000000000999944990000000000000000000000009ffff0009f00000000000000
000000000000000000000000000000000000000000000000000000000000000000000000994999990000000000000000000000003bbbb0003b00000000000000
00000000000000000000000000000000000000000000000000000000000000000000000099944449000000000000000000000000247777002477770000000000
0000000000000000000000000000000000000000000000000000000000000000000000009999999900000000000000000000000099ff700099f0700000000000
00000000000000000000000000000000000000000000000000000000000000000000000099999999000000000000000000000000000700000007000000000000
00000000000000000000000000000000000000000000000000000000000000000000000099999999000000000000000000000000007777000077770000000000
4444444400000000000222229999999999999999000044990000449900040004000004493bb3bbbb000033bb33bbb3bb33b3bb3333b333bb333b33b300000003
4442444400000000002224242222222299999999000044990000494400004049000044443bbbbbbb000033b3333bb33b33b33b3b3bbbbbbbbbbbbb300000033b
4444444444444444222242424242424299999999000049440000449900040449004444993b3bbb3b00003bb33b3bbb333bb3bb33bbbbbbbbb33b3300000333bb
4244424444444244424244442444242499999999000044990000444900000444044494993b3b3b3b00003bbb3b3bbbb33bb33b3bbbbb33b33b3330000003bb3b
44442444444444442444242444444244999999990000449900440494000044994449994933bb33bb00003bbb3333bbb333b33b3bbbb3bb33333000000033b3bb
444244424244444444224442242442449999999900004449040000490000444944449999333bb3bb000033b33b33bbb33bb33b333b33333330000000033b33bb
2422242444444424444444244244242499999999000049440000004400000944499444990333333b000033bb33b33b3b33b3bb3333333000000000003333bbbb
2222222244444444444444444444444499999999000044990000000400004499449999990033b3330000033b33bbb33b33b33b3b33300000000000003b3bbbbb
777777770000000000000000000000000000000000000000000aa000000000000000000000000000000000000000000000022000000900000000000000000000
77777777000000000000000000000000000000000000000000aaaa00000000000000200002022020070000700700007005222250049994000022220000222000
7777777700000000000000000800800000008008000222000a8aa8a0000777000001110000222200000770000070070050222205009990000222222002222200
7777777700080800000020000028880808088820000828000aaaaaa0007007700021812020222202707777077700007705244250409990400222222022222220
77777777000080000002220008228228082282280008880000899800000777000001110002222220007777000000000050444405049f94002228822202c4c200
7777777700080800000020000828882808288828000282000099990000700770000020002222222270777707770000775040040544fff4400088880020444020
77777777000000000000000000288808080888200002220000799700007007700000000000222200007777000070070000400400040f04002008800204000400
77777777000000000000000008008000000080080000000000000000000777000000000002000020070000700700007000000000400000400800008000000000
dddddddd00000000000000000000000000000000000000000000000000000000000000000cc00cc0000000000000000000000000000000000000000000000000
d555555d0000000000000000000000000000000000000000000000000000000000000000000cc000000707000000000000220000000000000007770000202020
d555555d00202020000202200000222000202020002323200000200000202020002020200cccccc007070707000020000022d00000d020d00070007002022200
d555555d0002220000022220002222200002220000111130000111000002220000022200c00cc00c0777777700d222d0000d8d00000222000070007000222222
d555555d000222000228820000288220000222000011813000221120002222200022222000c00c0000077700000d2d0000d0d0d0000d2d000007770002222800
d555555d00022200001281100022820000022200001111300001210000022200000222000c0000c00778787700dd8dd000000000000d8d000070007000228222
d555555d002020200011100000222200002020200023232000002000002020200020202000000000070707070000d0000000000000d0d0d00070007002020200
dddddddd000000000000100000000000000000000000000000000000000000000000000000000000000707000000000000000000000000000007770000020200
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000007000700000000000dd000000dd000000dd0000000000000000000000000000000000000000000000000000000000000000000000020200
0700700000007007000707000002022000ddd00000ddd00000ddd000000022000007070000007070000707000000d00000d0d0d0000055000220000002022202
00070707070707000777877700022220000ddd00000ddd00000d8d000002882000777770000777000077717000dd8dd0000d8d00005555002221220002222222
0700700707007007000888000228820000d0d0d0000d0d0000d0d0d000288820000777000077717000077700000d2d00000d2d00005550000222220000022200
070707070707070707787877001281100000000000000000000000000022820000717170000717000077717000d222d00002220000555000d0d0d0d002282822
00070707070707000007070000111000000000000000000000000000000220000007070000707000000707000000200000d020d0000000000000000002020202
07007000000070070070007000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020200
00000000000000000000b0000003000000000000000000000000449900040004000004493bb3bbbb000033bb33bbb3bb33b3bb3333b333bb333b33b300000003
00dddd0000dd0000000bbb0000333000000fff00000ff0000000494400004049000044443bbbbbbb000033b3333bb33b33b33b3b3bbbbbbbbbbbbb300000033b
000dd0000d22d0d00088b88000023200009ffff0009f00000000449900040449004444993b3bbb3b00003bb33b3bbb333bb3bb33bbbbbbbbb33b3300000333bb
00d22d000d222dd000f8888000002220003bbbb0003b00000000444900000444044494993b3b3b3b00003bbb3b3bbbb33bb33b3bbbbb33b33b3330000003bb3b
0d2222d00d222dd000888f8000002200002444400024000000440494000044994449994933bb33bb00003bbb3333bbb333b33b3bbbb3bb33333000000033b3bb
0d2222d00d22d0d200088800000220000099fff00099f000040000490000444944449999333bb3bb000033b33b33bbb33bb33b333b33333330000000033b33bb
00dddd0000dd0002000f88000000200000000000000000000000004400000944499444990333333b000033bb33b33b3b33b3bb3333333000000000003333bbbb
0000000000000000000000000000000000000000000000000000000400004499449999990033b3330000033b33bbb33b33b33b3b33300000000000003b3bbbbb
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
011100002f0402f0452f0402f0452d0002d0002f0402f0402d0402d0452d0402d04500000000002d0402d0402b0402b0452b0402b04500000000002b0402b0402a0402a0402a0402a040300402f0402d0402b040
011f00002d07029070260702d0002d0002d07029070260702b0702807024070000002b0002b07028070240702900024000280000000000000000000000000000000000000000000000000000000000000002d000
011400002f0702b0702b0002b0702d070280002d0702f070300702f0702d0702b070290702807000000000000000000000000000000000000000000000000000000000000000000000000000000000000002f000
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

