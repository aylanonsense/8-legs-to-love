pico-8 cartridge // http://www.pico-8.com
version 8
__lua__

-- game vars
tile_symbols="abcdefghijklmnopqrstuvwxyz0123456789"
tile_flip_matrix={8,4,2,1,128,64,32,16}
scene=nil
scene_frame=0
bg_color=0
score=0
visible_score=0
timer=0
level_num=0
bugs_eaten=0
visible_bugs_eaten=0
spider=nil
is_in_building_phase=false
bugs={}
effects={}
web_points={}
web_strands={}
tiles={}


-- main functions
function _init()
	init_title()
	-- init_game()
	-- init_game_over()
end

function _update()
	scene_frame+=1
	if scene_frame>240*60 then
		scene_frame=180*60
	end
	if scene=="title" then
		update_title()
	elseif scene=="game" then
		update_game()
		-- update_game()
	elseif scene=="tutorial" then
		update_tutorial()
	elseif scene=="game_over" then
		update_game_over()
	end
end

function _draw()
	-- clear the canvas
	camera()
	rectfill(0,0,127,127,bg_color)

	-- draw the scene
	if scene=="title" then
		draw_title()
	elseif scene=="game" then
		draw_game()
	elseif scene=="tutorial" then
		draw_tutorial()
	elseif scene=="game_over" then
		draw_game_over()
	end

	-- draw guidelines
	-- camera()
	-- line(0,0,0,127,8)
	-- line(62,0,62,127,8)
	-- line(65,0,65,127,8)
	-- line(127,0,127,127,8)
	-- line(0,0,127,0,8)
	-- line(0,62,127,62,8)
	-- line(0,65,127,65,8)
	-- line(0,127,127,127,8)
end


-- title functions
function init_title()
	scene="title"
	scene_frame=0
end

function update_title()
	if (btnp(4) or btnp(5)) and scene_frame>15 then
		init_tutorial()
	end
end

function draw_title()
	-- local r
	-- local c
	-- for c=0,26 do
	-- 	for r=0,26 do
	-- 		local x_offset=flr(scene_frame/3)%5-5
	-- 		rect(5*c+x_offset,5*r,5*c+4+x_offset,5*r+4,1)
	-- 	end
	-- end
	for c=0,5 do
		for r=0,3 do
			spr(16*r+c,8*c+40,8*r+32)
		end
	end
	line(73,64,73,80,7)
	spr(13,69,81)
	if scene_frame%30<20 then
		print("press z to play demo",24,106,7)
	end
	print("@bridgs_dev",4,122,13)
	print("www.brid.gs",81,122,13)
	-- spr(6,1,1)
	-- line(0,0,0,10,7)
	-- line(0,0,10,0,7)
end


-- game functions
function init_game()
	scene="game"
	scene_frame=0
	level_num=1
	score=0
	timer=61*30-1
	is_in_building_phase=true
	bg_color=levels[level_num].bg_color
	reset_tiles()
	load_tiles(levels[level_num].map,tilesets[levels[level_num].tileset])
	bugs={}
	effects={}
	web_points={}
	web_strands={}
	spider=create_spider(levels[level_num].spawn_point[1],levels[level_num].spawn_point[2],true)
end

function update_game()
	timer-=1
	if timer<0 then
		if is_in_building_phase then
			is_in_building_phase=false
			timer=61*30-1
			create_announcement_effect("catch bugs!")
		else
			init_game_over()
			return
		end
	end

	if scene_frame==60 and is_in_building_phase then
		create_announcement_effect("build a web!")
	end

	local level=levels[level_num]
	if not is_in_building_phase then
		foreach(level.bug_spawns,function(spawn)
			if timer/30==spawn[1]+1 then
				create_bug_spawner(4+8*(level.center_point[1]+spawn[2]),4+8*(level.center_point[2]+spawn[3]),spawn[4],spawn[5] or 1,spawn[6] or 0,spawn[7] or 0)
			end
			-- local t=timer/30
			-- local spawn_type=spawn[4]
			-- local spawn_time=spawn[1]
			-- if spawn_type=="single" and spawn_time==t then

			-- if spawn[1]==t then
			-- 	if spawn[4]=="single" then
			-- 		create_bug_of_species(spawn[5],8*level.center_point[1]+spawn[2],8*level.center_point[2]+spawn[3])
			-- 	end
			-- end
		end)
	end

	-- if scene_frame%100==0 then
	-- 	create_fly(50,50)
	-- 	create_firefly(50,70)
	-- 	create_dragonfly(70,70)
	-- 	create_hornet(70,50)
	-- 	create_beetle(60,40)
	-- end

	-- update the web
	foreach(web_strands,update_web_strand)
	foreach(web_points,update_web_point)

	-- update the bugs
	foreach(bugs,update_bug)

	-- update the player spider
	update_spider()

	-- update special effects
	foreach(effects,update_effect)

	-- get rid of anything that isn't alive anymore
	web_strands=filter_list(web_strands,check_for_web_strand_death)
	web_points=filter_list(web_points,check_for_web_point_death)
	bugs=filter_list(bugs,is_alive)
	effects=filter_list(effects,is_alive)
end

function draw_game()
	camera(0,-8)

	-- draw bugs
	foreach(bugs,function(bug)
		draw_bug_bg(bug)
		if bug.is_in_bg then
			draw_bug(bug)
		end
	end)

	-- draw tiles
	draw_tiles()

	-- draw the web
	foreach(web_strands,draw_web_strand)

	-- draw bugs
	foreach(bugs,function(bug)
		if not bug.is_in_bg then
			draw_bug(bug)
		end
	end)

	-- draw the playable spider
	draw_spider()

	-- draw special effects
	foreach(effects,draw_effect)

	-- draw the ui
	camera()
	draw_ui()
end


-- tutorial functions
function init_tutorial()
	scene="tutorial"
	scene_frame=0
	web_points={}
	web_strands={}
	spider=create_spider(0,40,false)
end

function update_tutorial()
	-- update the web
	foreach(web_strands,update_web_strand)
	foreach(web_points,update_web_point)

	if scene_frame==10 then
		spider.is_holding_right=true
		spider.is_holding_down=true
	elseif scene_frame==45 then
		spider.is_holding_right=false
		spider.is_holding_down=false
	elseif scene_frame==60 then
		spider.is_holding_right=true
	elseif scene_frame==80 then
		spider.is_holding_right=false
		spider.is_holding_left=true
	elseif scene_frame==100 then
		spider.is_holding_left=false
		spider.is_holding_down=true
	elseif scene_frame==120 then
		spider.is_holding_down=false
		spider.is_holding_up=true
	elseif scene_frame==140 then
		spider.is_holding_up=false
	elseif scene_frame==200 then
		spider.is_holding_z=true
		spider.has_pressed_z=true
		spider.is_holding_right=true
	elseif scene_frame==201 then
		spider.has_pressed_z=false
	elseif scene_frame==220 then
		spider.is_holding_right=false
	elseif scene_frame==250 then
		spider.is_holding_z=false
	elseif scene_frame==320 then
		spider.is_holding_right=true
	elseif scene_frame==390 then
		spider.has_pressed_z=true
	elseif scene_frame==391 then
		spider.has_pressed_z=false
	elseif scene_frame==410 then
		spider.is_holding_right=false
		spider.is_holding_left=true
	elseif scene_frame==415 then
		spider.is_holding_left=false
	elseif scene_frame==470 then
		spider.is_holding_left=true
		spider.is_holding_down=true
		spider.has_pressed_x=true
	elseif scene_frame==477 then
		spider.has_pressed_x=false
		spider.is_holding_down=false
	elseif scene_frame==500 then
		spider.has_pressed_z=true
		spider.is_holding_z=true
	elseif scene_frame==501 then
		spider.has_pressed_z=false
	elseif scene_frame==550 then
		spider.is_holding_down=true
		spider.is_holding_z=false
		spider.has_pressed_z=true
	elseif scene_frame==552 then
		spider.has_pressed_z=false
	elseif scene_frame==580 then
		spider.is_holding_down=false
		spider.is_holding_left=false
		spider.is_holding_up=true
		spider.is_holding_right=true
	elseif scene_frame==583 then
		spider.is_holding_up=false
		spider.is_holding_right=false
	end

	-- update the player spider
	update_spider()

	-- get rid of anything that isn't alive anymore
	web_strands=filter_list(web_strands,check_for_web_strand_death)
	web_points=filter_list(web_points,check_for_web_point_death)

	if scene_frame>10 then
		if btn(4) then
			init_game()
		elseif btn(5) then
			init_tutorial()
		end
	end
end

function draw_tutorial()
	print("how to play",42,14,7)
	line(42,20,84,20,7)
	if scene_frame>=50 and scene_frame<170 then
		print("use arrow keys to move",20,38,7)
	elseif scene_frame>=190 and scene_frame<320 then
		print("hold z to spin web",28,38,7)
	elseif scene_frame>=340 and scene_frame<470 then
		print("press z again to place",20,38,7)
	elseif scene_frame>=490 and scene_frame<620 then
		print("use strands to make a web",14,38,7)
	elseif scene_frame>=640 then
		print("catch as many bugs as you can!",4,38,7)
	end
	if scene_frame>10 then
		if scene_frame>=640 then
			color(7)
		else
			color(13)
		end
		print("z - continue",10,110)
		print("x - rewatch",70,110)
	end

	-- draw the web
	foreach(web_strands,draw_web_strand)

	-- draw the playable spider
	draw_spider()
end


-- game over functions
function init_game_over()
	scene="game_over"
	scene_frame=0
	visible_bugs_eaten=0
	visible_score=0
end

function update_game_over()
	if (btnp(4) or btnp(5)) and scene_frame>=20 then
		if visible_bugs_eaten<bugs_eaten or visible_score<score then
			visible_bugs_eaten=bugs_eaten
			visible_score=score
		else
			init_title()
		end
	end

	if scene_frame>=20 and scene_frame%2==0 then
		if visible_bugs_eaten<bugs_eaten then
			visible_bugs_eaten=min(bugs_eaten,visible_bugs_eaten+1)
		elseif visible_score<score then
			visible_score=min(score,visible_score+1)
		end
	end
end

function draw_game_over()
	print("game over",46,14,7)
	line(46,20,80,20,7)
	print("bugs eaten",15,45,7)
	print("final score",15,58,7)
	if scene_frame>=20 then
		if visible_score>=score and visible_bugs_eaten<=bugs_eaten then
			print("thank you for playing!",20,79,7)
			print("press z to restart",28,89,13)
			spr(13,60,104)
			if scene_frame%30<20 then
				spr(60,67,101)
				pset(65,109,7)
			end
		end
		-- draw score
		local bugs_text=""..visible_bugs_eaten
		print(bugs_text,110-4*#bugs_text,45,7)

		if visible_bugs_eaten>=bugs_eaten then
			local score_text
			if visible_score<=0 then
				score_text="0"
			else
				score_text=visible_score.."0"
			end
			print(score_text,110-4*#score_text,58,7)
		end
	end
	print("@bridgs_dev",4,122,13)
	print("www.brid.gs",81,122,13)
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
		},
		["center_point"]={8,7},
		["bug_spawns"]={
			{58,   -3,   -2, "fly",       3,    2,    2},
			{52,   -3,   -3, "fly",       3,    2,    0},
			{47,   -3,    3, "fly",       3,    2,    0},
			{42,    1,   -5, "fly",       4,    0,    2},
			{39,   -2,   -2, "fly",       4,    0,    2},
			{34,    0,    0, "beetle"                  },
			{29,   -3,   -3, "fly",       5,    1,    1},
			{28,   -3,    2, "beetle"                  },
			{27,    2,   -3, "beetle"                  },
			{22,   -3,    3, "fly",       2,    1,   -1},
			{21,   -1,    1, "beetle"                  },
			{20,    0,    2, "fly",       2,    1,   -1},
			{19,    2,    0, "beetle"                  },
			{18,    0,   -1, "fly",       2,    1,   -1},
			{17,    2,   -3, "beetle"                  },
			{10, -2.5, -2.5, "firefly",   2,    5,    0},
			{9,     0,    0, "firefly",   2, -2.5,  2.5},
			{8,   2.5,  2.5, "firefly"                 }
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
			["is_sticky"]=true,
		},
		["render"]={
			["icon_sprite"]=62,
			["is_dashed"]=false
		}
	}
	-- ,
	-- {
	-- 	["physics"]={
	-- 		["initial_speed"]=1,
	-- 		["initial_tautness"]=0.00,
	-- 		["dist_between_points"]=5,
	-- 		["gravity"]=0.02,
	-- 		["friction"]=0.05,
	-- 		["elasticity"]=0.60,
	-- 		["break_ratio"]=4.00,
	-- 		["detatch_from_tile_ratio"]=2.00,
	-- 		["spring_force"]=0.2,
	-- 		["is_sticky"]=true,
	-- 	},
	-- 	["render"]={
	-- 		["icon_sprite"]=63,
	-- 		["is_dashed"]=true
	-- 	}
	-- }
}


-- all them functions
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
	-- if scene_frame%16<8 then
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

function create_spider(x,y,is_controllable)
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
		["hitstun"]=0,
		["is_spinning_web"]=false,
		["is_web"]=false,
		["webbing"]=110,
		["max_webbing"]=110,
		["stationary_frames"]=0,
		["bug_interact_dist"]=12,
		["nearest_interactive_bug"]=nil,
		["frames_since_walk_sound"]=99,
		-- controls
		["is_controllable"]=is_controllable,
		["is_holding_left"]=false,
		["is_holding_right"]=false,
		["is_holding_up"]=false,
		["is_holding_down"]=false,
		["is_holding_z"]=false,
		["has_pressed_z"]=false,
		["has_pressed_x"]=false,
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

	if spider.is_controllable then
		spider.is_holding_left=btn(0)
		spider.is_holding_right=btn(1)
		spider.is_holding_up=btn(2)
		spider.is_holding_down=btn(3)
		spider.is_holding_z=btn(4)
		spider.has_pressed_z=btnp(4)
		spider.has_pressed_x=btnp(5)
	end

	spider.frames_since_walk_sound+=1

	if spider.stationary_frames>0 then
		spider.stationary_frames-=1
	end

	spider.was_on_tile = spider.is_on_tile
	spider.was_on_web = spider.is_on_web

	-- figure out if the spider is walking on a tile
	if spider.hitstun>0 then
		spider.is_on_tile=false
	else
		spider.is_on_tile=is_solid_tile_at_spider()
	end

	-- figure out if the spider is walking on web
	local web_x
	local web_y
	local web_square_dist
	web_x,web_y,web_square_dist=calc_closest_spot_on_web(spider.x,spider.y,false)
	if spider.hitstun>0 then
		spider.is_on_web=false
	else
		spider.is_on_web=web_x!=nil and web_y!=nil and web_square_dist<=spider.web_attract_dist*spider.web_attract_dist
	end

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
			sfx(3,2)
		end
	end

	-- if the spider's web gets cut off at the base, it's no longer spinning web
	if spider.attached_web_strand and not spider.attached_web_strand.is_alive then
		spider.attached_web_strand=nil
		spider.spun_web_start_point=nil
		spider.is_spinning_web=false
		mark_all_points_as_not_being_spun()
	end

	-- start spinning web when z is first pressed
	if not spider.attached_web_strand and spider.has_pressed_z and spider.webbing>0 then
		spider.webbing-=1
		spider.is_spinning_web=true
		spider.frames_to_web_spin=web_types[spider.web_type].physics.dist_between_points/2
		local start_point
		local square_dist
		start_point,square_dist=calc_closest_web_point(spider.x,spider.y,true,nil,false,false)
		-- if we can't find a point nearby to attach to, create a new one
		if not start_point or square_dist>=spider.web_attach_dist*spider.web_attach_dist or
			(spider.is_on_tile and not start_point.has_been_anchored) then
			start_point=create_web_point_at_spider(is_solid_tile_at_spider())
		end
		spider.attached_web_strand=create_web_strand(spider,start_point)
		spider.spun_web_start_point=start_point

	-- stop spinning web when z is released
	elseif spider.is_spinning_web and not spider.is_holding_z then
		spider.is_spinning_web=false

	-- cut/place the end of the strand when z is pressed again
	elseif spider.attached_web_strand and not spider.is_spinning_web and spider.has_pressed_z then
		local end_point
		local square_dist
		end_point,square_dist=calc_closest_web_point(spider.x,spider.y,true,spider.spun_web_start_point.id,false,false)
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
		sfx(4,2)
	end

	-- press x switch web types when not spinning
	if not spider.is_spinning_web and spider.has_pressed_x then
		spider.web_type=1+(spider.web_type)%#web_types
	end

	-- move the spider while on tile or web
	if spider.is_on_tile or spider.is_on_web then
		-- todo slowly reduce velocity
		spider.vx=0
		spider.vy=0
		if spider.stationary_frames<=0 then
			-- arrow keys move the spider
			if spider.is_holding_left then
				spider.vx-=spider.move_speed
			end
			if spider.is_holding_right then
				spider.vx+=spider.move_speed
			end
			if spider.is_holding_up then
				spider.vy-=spider.move_speed
			end
			if spider.is_holding_down then
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

	foreach(bugs,function(bug)
		local square_dist=calc_square_dist_between_points(spider.x,spider.y,bug.x,bug.y)
		if square_dist<=49 and bug.is_alive and (bug.state=="active" or bug.state=="caught") then
			create_bug_death_effect(bug)
			create_floating_text_effect("+"..bug.score.."0",bug.colors[1],bug.x-4,bug.y)
			sfx(7,1)
			bug.is_alive=false
			score+=bug.score
			bugs_eaten+=1
			spider.webbing=min(spider.webbing+2,spider.max_webbing)
		end
	end)

	if spider.hitstun>0 then
		spider.hitstun-=1
	end

	-- -- if the spider does wind up out of bounds, she's dead :'(
	-- if spider.x<-8 or spider.x>135 or spider.y<-200 or spider.y>127 then
	-- 	spider.is_alive=false
	-- end

	-- actually just keep the spider in bounds
	if spider.x<3 then
		spider.x=3
		spider.vx=max(0,spider.vx)
	end
	if spider.x>124 then
		spider.x=124
		spider.vx=min(0,spider.vx)
	end
	if spider.y<3 then
		spider.y=3
		spider.vy=max(0,spider.vy)
	end
	if spider.y>116 then
		spider.y=116
		spider.vy=min(0,spider.vy)
	end
end

function draw_spider()
	if spider.is_alive then
		local sprite=29
		local dx=-4
		local dy=-4
		local flipped_x=false
		local flipped_y=false
		if spider.hitstun>0 then
			sprite=61
		elseif spider.facing_x<-0.4 then
			flipped_x=true
			dx=-3
		elseif spider.facing_x<0.4 then
			sprite=13
		end
		if spider.facing_y<-0.4 then
			flipped_y=true
			dy=-3
		elseif spider.facing_y<0.4 then
			sprite=45
		end
		-- flip through the spider's walk cycle
		if (spider.is_on_tile or spider.is_on_web) and (spider.vx!=0 or spider.vy!=0) then
			if scene_frame%10>=5 then
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
		if spider.attached_web_strand then
			sfx(2,3)
		else
			sfx(0,3)
		end
		spider.frames_since_walk_sound=0
	end
	if (spider.was_on_tile or spider.was_on_web) and not spider.is_on_tile and not spider.is_on_web and spider.hitstun<=0 then
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
		["caught_bug"]=nil,
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

	if web_point.caught_bug and not web_point.caught_bug.is_alive then
		web_point.caught_bug=nil
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

function create_bug_of_species(species,x,y)
	if species=="fly" then
		create_fly(x,y)
	elseif species=="firefly" then
		create_firefly(x,y)
	elseif species=="beetle" then
		create_beetle(x,y)
	elseif species=="dragonfly" then
		create_dragonfly(x,y)
	elseif species=="hornet" then
		create_hornet(x,y)
	end
end

function create_fly(x,y)
	create_bug(x,y,"fly",{64},{12,13,5,1},1)
end

function create_firefly(x,y)
	create_bug(x,y,"firefly",{80},{9,4,2,1},2)
end

function create_beetle(x,y)
	create_bug(x,y,"beetle",{71},{8,13,5,1},2)
end

function create_dragonfly(x,y)
	create_bug(x,y,"dragonfly",{96},{11,3,5,1},3)
end

function create_hornet(x,y)
	create_bug(x,y,"hornet",{112},{10,15,4,1},3)
end

function create_bug(x,y,species,sprites,colors,score)
	local bug={
		["species"]=species,
		["x"]=x,
		["y"]=y,
		["vx"]=0,
		["vy"]=0,
		["is_alive"]=true,
		["sprites"]=sprites,
		["colors"]=colors,
		["score"]=score,
		["is_in_bg"]=true,
		["strength"]=0,
		["max_strength"]=1,
		["caught_web_point"]=nil,
		["state"]="spawning",
		["state_frames"]=0
	}
	add(bugs,bug)
	return bug
end

function update_bug(bug)
	bug.state_frames+=1

	-- transition between states
	if bug.state=="spawning" and bug.state_frames>=15 then
		bug.state="incoming"
		bug.state_frames=0
		bug.vy=0.2
	elseif bug.state=="incoming" and bug.state_frames>=30 then
		bug.state="active"
		bug.state_frames=0
		bug.is_in_bg=false
	elseif bug.state=="active" then
		if bug.state_frames>=30 then
			bug.state="escaping"
			bug.state_frames=0
		else
			local web_point
			local square_dist
			web_point,square_dist=calc_closest_web_point(bug.x,bug.y,true,nil,true,true)
			-- the bug got caught in the web
			if web_point and square_dist<=64 then
				bug.caught_web_point=web_point
				web_point.caught_bug=bug
				bug.state="caught"
				bug.state_frames=0
				bug.vx=0
				bug.vy=0
			end
		end
	elseif bug.state=="escaping" and bug.state_frames>=18 then
		bug.is_alive=false
	end

	-- bug stays attached to web point
	if bug.caught_web_point then
		if not bug.caught_web_point.is_alive then
			bug.caught_web_point=nil
			bug.state="escaping"
			bug.state_frames=0
		else
			bug.x=bug.caught_web_point.x
			bug.y=bug.caught_web_point.y
			bug.strength=min(bug.strength+0.01,bug.max_strength)
			if bug.species=="beetle" then
				if bug.state_frames>140 then
					bug.caught_web_point.is_alive=false
				end
			elseif bug.species=="firefly" then
				if bug.state_frames>=130 then
					create_explosion_effect(bug.x,bug.y)
					sfx(9,0)
					bug.is_alive=false
					foreach(web_points,function(web_point)
						local dist=sqrt(calc_square_dist_between_points(bug.x,bug.y,web_point.x,web_point.y))
						if dist<10 then
							web_point.is_alive=false
						elseif dist<30 then
							local x
							local y
							x,y=create_vector(web_point.x-bug.x,web_point.y-bug.y,(30-dist)/8)
							web_point.vx+=x
							web_point.vy+=y
						end
					end)
					local square_dist=sqrt(calc_square_dist_between_points(bug.x,bug.y,spider.x,spider.y))
					if square_dist<400 then
						local x
						local y
						x,y=create_vector(spider.x-bug.x,spider.y-bug.y,6)
						spider.hitstun=15
						spider.vx+=x
						spider.vy+=y
					end
				end
			elseif scene_frame%4==0 and rnd(1)<0.4 then
				local dir=rnd(20)
				if dir>15 then -- extra chance of moving up
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
				if bug.strength>=bug.max_strength and rnd(1)<0.1 then
					bug.state="escaping"
					bug.state_frames=0
					bug.caught_web_point=nil
				end
			end
		end

	-- apply acceleration
	elseif bug.state!="spawning" then
		bug.vy-=0.003
		if bug.state=="escaping" then
			bug.vy-=0.05
		end
	end

	-- apply velocity
	bug.x+=bug.vx
	bug.y+=bug.vy
	
	-- if the bug goes out of bounds, it's dead
	if bug.x<-8 or bug.x>127 or bug.y<-8 or bug.y>127 then
		bug.is_alive=false
	end
end

function draw_bug_bg(bug)
	local r=0
	if bug.state=="incoming" then
		r=4+(30-bug.state_frames)/2
		if bug.state_frames<10 then
			r=0
		else
			color(bug.colors[4])
		end
	elseif bug.state=="active" then
		-- r=7
		-- color(bug.colors[1])
	elseif bug.state=="escaping" then
		r=4+bug.state_frames
		if bug.state_frames<8 then
			color(bug.colors[4])
		else
			r=0
		end
	end
	if r>0 then
		circ(bug.x,bug.y,r)
	end
end

function draw_bug(bug)
	local sprites
	local s=bug.sprites[1]
	local c=bug.colors
	if bug.state=="spawning" then
		sprites={123,124,125,126,127}
		set_single_color(c[1])
	elseif bug.state=="incoming" then
		sprites={s,s+1}
	elseif bug.state=="active" then
		sprites={s+2,s+3}
	elseif bug.state=="escaping" then
		sprites={s+2,s+3}
		if bug.state_frames<8 then
			set_single_color(c[2])
		elseif bug.state_frames<15 then
			set_single_color(c[3])
		else
			set_single_color(c[4])
		end
	elseif bug.state=="caught" then
		sprites={s+4,s+5,s+6}
		if bug.species=="firefly" then
			if bug.state_frames>=25 then
				print(3-flr((bug.state_frames-25)/35),bug.x-1,bug.y-9,8)
			end
			if bug.state_frames%35>25 then
				sprites={s+7,s+8,s+9}
			end
		end
	end
	spr(sprites[flr(bug.state_frames/3)%#sprites+1],bug.x-3,bug.y-4)
	pal()
end

function create_bug_spawner(x,y,species,amt,vx,vy)
	local effect={
		["x"]=x,
		["y"]=y,
		["species"]=species,
		["amt"]=amt,
		["vx"]=vx,
		["vy"]=vy,
		["frames_alive"]=0,
		["is_alive"]=true,
		["update"]=function(effect)
			if effect.frames_alive%15==0 then
				create_bug_of_species(effect.species,effect.x,effect.y)
				sfx(8,0)
				effect.amt-=1
				if effect.amt<=0 then
					effect.is_alive=false
				else
					effect.x+=8*effect.vx
					effect.y+=8*effect.vy
				end
			end
			effect.frames_alive+=1
		end,
		["draw"]=function(effect) end
	}
	add(effects,effect)
	return effect
end

function create_explosion_effect(x,y)
	local effect={
		["x"]=x,
		["y"]=y,
		["frames_alive"]=0,
		["is_alive"]=0,
		["update"]=function(effect)
			effect.frames_alive+=1
			if effect.frames_alive>=12 then
				effect.is_alive=false
			end
		end,
		["draw"]=function(effect)
			local x=effect.x+rnd(2)-1
			local y=effect.y+rnd(2)-1
			if effect.frames_alive<4 then
				circfill(x,y,10,7)
			elseif effect.frames_alive<8 then
				circfill(x,y,15,6)
			elseif effect.frames_alive<10 then
				circfill(x,y,17,5)
			else
				circfill(x,y,18,1)
			end
		end
	}
	add(effects,effect)
	return effect
end

function create_floating_text_effect(txt,col,x,y)
	local effect={
		["x"]=x,
		["y"]=y,
		["txt"]=txt,
		["col"]=col,
		["frames_alive"]=0,
		["is_alive"]=true,
		["update"]=function(effect)
			effect.y-=0.5
			effect.frames_alive+=1
			if effect.frames_alive>=23 then
				effect.is_alive=false
			end
		end,
		["draw"]=function(effect)
			if effect.frames_alive<15 then
				color(effect.col)
			elseif effect.frames_alive<18 then
				color(6)
			elseif effect.frames_alive<21 then
				color(13)
			else
				color(1)
			end
			print(effect.txt,effect.x,effect.y)
		end
	}
	add(effects,effect)
	return effect
end

function create_bug_death_effect(bug)
	local effect={
		["x"]=bug.x,
		["y"]=bug.y,
		["frames_alive"]=0,
		["is_alive"]=true,
		["update"]=function(effect)
			effect.frames_alive+=1
			if effect.frames_alive>=20 then
				effect.is_alive=false
			end
		end,
		["draw"]=function(effect)
			spr(106+flr(effect.frames_alive/4)%5,effect.x-3,effect.y-3)
		end
	}
	add(effects,effect)
	return effect
end

function create_announcement_effect(txt)
	local effect={
		["txt"]=txt,
		["frames_alive"]=0,
		["is_alive"]=true,
		["update"]=function(effect)
			effect.frames_alive+=1
			if effect.frames_alive>=75 then
				effect.is_alive=false
			end
		end,
		["draw"]=function(effect)
			if effect.frames_alive<65 then
				color(7)
			elseif effect.frames_alive<70 then
				color(13)
			else
				color(1)
			end
			print(txt,64-2*#txt,2)
		end
	}
	add(effects,effect)
	return effect
end

function update_effect(effect)
	effect.update(effect)
end

function draw_effect(effect)
	effect.draw(effect)
end

function draw_ui()
	rectfill(0,0,127,7,0)
	if spider.is_spinning_web then
		color(7)
	else
		color(5)
	end
	rectfill(35,2,31+55*spider.webbing/spider.max_webbing,5)
	rect(35,1,86,6)
	spr(web_types[spider.web_type].render.icon_sprite,88,0)

	-- draw timer
	local seconds=flr(timer/30)%60
	local minutes=flr(timer/1800)
	local txt=minutes..":"
	if seconds<10 then
		txt=txt.."0"
	end
	txt=txt..seconds
	if not is_in_building_phase and minutes<=0 and (seconds<=1 or (seconds <= 10 and timer%30>15)) then
		color(8)
	else
		color(7)
	end
	print(txt,112,2)

	-- draw score
	local score_text
	if score<=0 then
		score_text="0"
	else
		score_text=score.."0"
	end
	print(score_text,1,2,7)
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
	if scene=="tutorial" then
		return true
	end
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

function create_vector(x,y,magnitude)
	local length=sqrt(x*x+y*y)
	if length==0 then
		return 0,0
	else
		return x*magnitude/length,y*magnitude/length
	end
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

function calc_closest_web_point(x,y,allow_freefalling,exception_web_point_id,sticky_only,empty_only)
	local i
	local square_dist
	local closest_web_point=nil
	local closest_square_dist=nil
	for i=1,#web_points do
		if not web_points[i].is_being_spun and
			(not exception_web_point_id or web_points[i].id!=exception_web_point_id) and
			(allow_freefalling or web_points[i].has_been_anchored) and
			(not empty_only or not web_points[i].caught_bug) and
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
	closest_web_point,closest_square_dist=calc_closest_web_point(x,y,allow_freefalling,nil,false,false)
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
	return anim[1+flr(scene_frame/frame_rate)%#anim]
end

function ceil(n)
	return -flr(-n)
end

function set_single_color(c)
	local i
	for i=1,15 do
		pal(i,c)
	end
end

__gfx__
00000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000700000007000
00000077770000000000070700000000000000000000000000000000000000000000000000000000000000000000000000000000000777000007770000077700
000077700d7700000000070700000000000000000000000000000000000000000000000000000000000000000000000000000000070777070007770707077700
00077600000770000500070700000000000000000000000000000000000000000000000000000000000000000000000000000000007777700777777000777777
00777000000070005050770600000000000000000000000000000000000000000000000000000000000000000000000000000000000777000007770000077700
007650000000d700d00077d000000000000000000000000000000000000000000000000000000000000000000000000000000000007171700771717000717177
00670000000007000ddd770000007770007700777dd0000000000000000000000000000000000000000000000000000000000000070707070007070707070700
0077d00000000700000077000007007007070700000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0077700000000700076070007d07770070070077000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007770000007000700770060707000d7007000070d0000000000000000000000000000000000000000000000000000000000000077707000777007007770700
000777700005700007770677700077700777077700d0000000000000000000000000000000000000000000000000000000000000077777000777770707777700
0000777775d6000000005500000000000007d000000ddd0000000000000000000000000000000000000000000000000000000000077777770777777007777777
00000777777000000050000000070000007700000ddd0d0000000000000000000000000000000000000000000000000000000000007771700077717000777170
0000dd777777600000055ddd000700000707ddddd000d00000000000000000000000000000000000000000000000000000000000077717070777170700771707
000666d777767700000000007dd77dddd7d700000000000000000000000000000000000000000000000000000000000000000000000770000007700007077000
00777500777767700000000707070077077000005000000000000000000000000000000000000000000000000000000000000000000707000007070000700700
07770000077776770000000707070570700000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d7700000007776676005000707007007dddddd000000000000000000000000000000000000000000000000000000000000000000007000700007070000700070
77700077660777667050507706000000000000000000000000000000000000000000000000000000000000000000000000000000000707000007070000070700
77000700006d776676d00077d0000000000000000000000000000000000000000000000000000000000000000000000000000000077771700777717007777170
7700700000076777770ddd7700000077007007600777000000000000000000000000000000000000000000000000000000000000777777007777770077777700
770070007700777667000077000007007070070d7007000000000000000000000000000000000000000000000000000000000000077771700777717007777170
777070007700777667076070007d07007007070077700ddd00000000000000000000000000000000000000000000000000000000000707000007070000070700
777007000600077676700770060707007dd707007000d00d00000000000000000000000000000000000000000000000000000000007000700070007000070700
07770077700007777007770677700077d00d70000777ddd000000000000000000000000000000000000000000000000000000000070707070000000000000000
077700000000777760000dddd000000000dd0000000d000000000000000000000000000000000000000000000000000000d0d000007171707750055005500550
007770000000777700000d000500000006005000ddd000000000000000000000000000000000000000000000000000000ddddd00000777007777005007000050
0007776000067770000000ddd0500000060005dd000000000000000000000000000000000000000000000000000000000ddddd00007777707777770000070000
0000777777777d00000000000dddddddd6dddd000000000000000000000000000000000000000000000000000000000000ddd000070777070077777700000700
000000777760000000000000000055000700050000000000000000000000000000000000000000000000000000000000000d0000000777000500777705000057
00000000000000000000000000000055575550000000000000000000000000000000000000000000000000000000000000000000000070000550057705500550
00000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008708000080087700000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000087000800800008070000000000000000
000000000000000007707700000000000d06600000d6600000660000008280000782870077828770008280000022000078088000080880000000000000000000
007007000000000006ccc60007ccc70000cdc00000cdc00000dcc000078287000682860066828660778287700828800078882000088820000000000000000000
000cc000007cc70000dcd00006dcd6000cccc0000cccc0000dccd600068886000088800008282800662826608282880078ee880008ee88000000000000000000
000cc000000cc00000ccc00000ccc00000cdc60000cdc00000ccc600000000000000000050e8e05050e8e0508888880007eeee0000eeee000000000000000000
00000000000000000d0c0d000d0c0d0000d066000d0660000c00d000000000000000000000808000008080008272820002020200020202000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000878000000000000000000000000000000000000
00000000000000000000000000000000000000020022000000000000000000080088000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000066020004440000006602000066080004440000006608000000000000000000000000000000000000000000000000
00000000000000000099900000999000009942400092442200999602008842400082448800888608000000000000000000000000000000000000000000000000
70aa070000aa000022aaa22022aaa22009aa444009a4420009aaa424088944400894420008899424000000000000000000000000000000000000000000000000
0a44a0000a44a0007a444a700a444a0009aa424009aaa96009aaa444089942400899986008999444000000000000000000000000000000000000000000000000
0944900079449700092429006924296009aaa90209aaa96009aaa424088998080889886008899424000000000000000000000000000000000000000000000000
00000000000000000044400070444070009996020099900000999602008886080088800000888608000000000000000000000000000000000000000000000000
00000000000000000400040004000400000000000000000000006602000000000000000000006608000000000000000000000000000000000000000000000000
00000000000000000033000000330000000000000000000000000000000000000000000000000000000000007700777006700700000000000000000000000000
0033000000330000003b0000003b0000005bb6000000000005350000000000000007700000777700000076006670066067000677000000060000000000000000
703b0700003b000070330070003300000035bb0000bb6b006b500000000770000070070007000070067076000000000077000067600005560000000000000000
073b7000003b0000673b0760003b0000050b36600b336b600bb50000007777000707707007000070067070000000000000000000560006600000000000000000
00bb000007bb700006bbb60007bbb70000533b000335bb6006303300007777000707707007000070007000000000000000000000560000000550055000000000
0033000070330700035b5000765b56700333300003305b0006b33300000770000070070007000070000000000000000000000000000000000550055000000000
0000000000000000003330006033306003bb30000005350000b3b000000000000007700000777700000000000000000000000000000000005500005500000000
00000000000000000500050005000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000500050005000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
005050000050500070aaa07000aaa00000d5a000066a5a0000500d00000000000000000000000000000000000000000000070000000007000000000000000000
075a5700005a5000675a5760005a5000005aaa00566a5aa05aa50550000000000000000000000000000000000700000000070000700770000000000000000000
069a9600079a9700069a9600079a9700000555000a5955a005a95aa0000000000000000000000000000000000077000000770000077770000007077000070000
0055500006555600005550007655567009a9a6600aaa0d5009aa5aa0000000000000000000000000000000000077700007777700007770000077700007777700
00a7a00000a7a00000a9a00060a9a06005a5a6600a59000006a5aa00000000000000000000000000000000000007700000077000007777007707000000070000
000600000006000000575000005750000aaa00005000000006600000000000000000000000000000000000000000070000070000007700700000000000000000
00000000000000000006000000060000500050000000000000000000000000000000000000000000000000000000000000070000070000000000000000000000
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
0106000021530215251d5301d5252d0002d0002f0002f0002d0002d0052d0002d00500000000002d0002d0002b0002b0052b0002b00500000000002b0002b0002a0002a0002a0002a000300002f0002d0002b000
01060000215502b5512b5512b5412b5310d5012900026000215002b5012b5012b5012b5012b50128000240002900024000280000000000000000000000000000000000000000000000000000000000000002d000
0106000021120211151d1201d1152d000280002d0002f000300002f0002d0002b000290002800000000000000000000000000000000000000000000000000000000000000000000000000000000000000002f000
010300001c7301c730186043060524600182001830018300184001840018500185001860018600187001870018200182000000000000000000000000000000000000000000000000000000000000000000000000
010300001873018730000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0106000024540245302b5202b54013630136111360100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01060000186701865018620247702b7702b7700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c0000185551c5551f5501f55000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010600000c2200c2210c2110c21100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000003065024631186210c61100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

