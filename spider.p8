pico-8 cartridge // http://www.pico-8.com
version 8
__lua__


-- old global vars
local visible_score=0
local level_num=0
local bugs_eaten=0
local visible_bugs_eaten=0
local is_in_building_phase=false
local effects={}


-- global vars
local actual_frame=0
local scene=nil
local scene_frame=0
local score=0
local timer=0
local spider=nil
local entities={}
local new_entities={}
local bugs={}
local web_points={}
local web_strands={}
local tiles={}


-- constants
local frame_skip=1
local render_layers={"far_background","background","web","midground","spider","foreground","far_foreground"}
local tile_symbols="abcdefghijklmnopqrstuvwxyz0123456789"
local tile_flip_matrix={8,4,2,1,128,64,32,16}
local scenes={}
local levels={
	{
		["spawn_point"]={63,17},
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
local tilesets={
	["carrot"]={128,{240,255, 254,255, 204,204, 204,136, 200,204, 236,255, 204,204, 255,239, 232,254, 255,63, 127,1}}
}
local bug_species={
	["fly"]={
		["base_sprite"]=64,
		["colors"]={12,13,5,1},
		["points"]=1
	},
	["beetle"]={
		["base_sprite"]=71,
		["colors"]={8,13,2,1},
		["points"]=2
	},
	["firefly"]={
		["base_sprite"]=80,
		["colors"]={9,4,2,1},
		["points"]=2
	},
	["dragonfly"]={
		["base_sprite"]=96,
		["colors"]={11,3,5,1},
		["points"]=3
	},
	["hornet"]={
		["base_sprite"]=112,
		["colors"]={10,9,5,1},
		["points"]=3
	}
}
local entity_classes={
	["spider"]={
		["render_layer"]="spider",
		["move_speed"]=1,
		["gravity"]=0.05,
		["mass"]=4,
		["webbing"]=110,
		["max_webbing"]=110,
		["facing_x"]=0,
		["facing_y"]=1,
		["is_on_tile"]=false,
		["is_on_web"]=false,
		["is_in_freefall"]=false,
		["is_holding_left"]=false,
		["is_holding_right"]=false,
		["is_holding_up"]=false,
		["is_holding_down"]=false,
		["is_holding_z"]=false,
		["has_pressed_z"]=false,
		["is_spinning_web"]=false,
		["is_placing_web"]=false,
		["spun_strand"]=nil,
		["frames_until_spin_web"]=0,
		["web_uncollision_frames"]=0,
		["update"]=function(entity)
			-- record inputs
			entity.is_holding_left=btn(0)
			entity.is_holding_right=btn(1)
			entity.is_holding_up=btn(2)
			entity.is_holding_down=btn(3)
			entity.is_holding_z=btn(4)
			entity.has_pressed_z=btnp(4)
			-- figure out if the spider is supported by anything
			entity.web_uncollision_frames=decrement_counter(entity.web_uncollision_frames)
			local web_x
			local web_y
			local web_square_dist
			web_x,web_y,web_square_dist=calc_closest_spot_on_web(entity.x,entity.y,false)
			entity.is_on_web=web_x!=nil and web_y!=nil and web_square_dist<=9 and entity.web_uncollision_frames<=0
			entity.is_on_tile=is_solid_tile_at(entity.x,entity.y)
			entity.is_in_freefall=not entity.is_on_tile and not entity.is_on_web
			-- when on web, the spider is pulled towards the strands
			if entity.is_on_web and not entity.is_on_tile then
				entity.x+=(web_x-entity.x)/5
				entity.y+=(web_y-entity.y)/5
			end
			-- the spider falls if unsupported
			if entity.is_in_freefall then
				entity.vy+=entity.gravity
			-- move the spider
			else
				entity.vx=0
				entity.vy=0
				if entity.is_holding_left then
					entity.vx-=entity.move_speed
				end
				if entity.is_holding_right then
					entity.vx+=entity.move_speed
				end
				if entity.is_holding_up then
					entity.vy-=entity.move_speed
				end
				if entity.is_holding_down then
					entity.vy+=entity.move_speed
				end
				-- make sure the spider doesn't move faster when moving diagonally
				if entity.vx!=0 and vy!=0 then
					entity.vx*=sqrt(0.5)
					entity.vy*=sqrt(0.5)
				end
			end
			-- apply the spider's velocity
			entity.x+=entity.vx
			entity.y+=entity.vy
			-- keep track of which direction the spider is facing
			local speed=sqrt(entity.vx*entity.vx+entity.vy*entity.vy)
			if entity.vx!=0 or entity.vy!=0 then
				entity.facing_x=entity.vx/speed
				entity.facing_y=entity.vy/speed
			end
			entity.frames_until_spin_web=decrement_counter(entity.frames_until_spin_web)
			-- the spider stops spinning web if it gets cut off at the base
			if (entity.is_spinning_web or entity.is_placing_web) and not entity.spun_strand.is_alive then
				entity.is_spinning_web=false
				entity.is_placing_web=false
				entity.spun_strand=nil
				entity.finish_spinning_web(entity)
			end
			-- the spider places a spun web when z is pressed
			if entity.is_placing_web and entity.has_pressed_z then
				entity.is_placing_web=false
				local web_point=entity.spin_web_point(entity,true,false)
				entity.spun_strand.set_from(entity.spun_strand,web_point)
				entity.spun_strand=nil
				if web_point.is_in_freefall and not web_point.has_been_anchored and speed>entity.move_speed then
					entity.web_uncollision_frames=4
				end
				entity.finish_spinning_web(entity)
			-- the spider starts spinning web when z is pressed
			elseif not entity.is_spinning_web and entity.has_pressed_z and entity.webbing>0 then
				entity.is_spinning_web=true
				entity.frames_until_spin_web=0
				entity.spun_strand=create_entity("web_strand",{["from"]=entity,["to"]=entity.spin_web_point(entity,true,true)})
			-- the spider stops spinning web when z is no longer held
			elseif entity.is_spinning_web and not entity.is_holding_z then
				entity.is_spinning_web=false
				entity.is_placing_web=true
			end
			-- the spider continuously creates web while z is held
			if entity.is_spinning_web and entity.frames_until_spin_web<=0 and entity.webbing>0 then
				entity.frames_until_spin_web=5
				local web_point=entity.spin_web_point(entity,false,true)
				entity.spun_strand.set_from(entity.spun_strand,web_point)
				entity.spun_strand=create_entity("web_strand",{["from"]=entity,["to"]=web_point})
				entity.webbing=decrement_counter(entity.webbing)
			end
			-- the spider eats bugs
			foreach(bugs,function(bug)
				if (bug.is_catchable or bug.caught_web_point) and 25>calc_square_dist(entity.x,entity.y,bug.x,bug.y) then
					create_entity("bug_wings",{
						["x"]=bug.x,
						["y"]=bug.y	
					})
					create_entity("floating_points",{
						["text"]="+"..bug.points.."0",
						["colors"]=bug.colors,
						["x"]=bug.x,
						["y"]=bug.y	
					})
					score+=bug.points
					bug.die(bug)
				end
			end)
			-- the spider stays in bounds
			spider.x=mid(3,spider.x,124)
			spider.y=mid(-1,spider.y,116)
		end,
		["draw"]=function(entity)
			local sprite=29
			local dx=4
			local dy=4
			local flipped_x=false
			local flipped_y=false
			if entity.facing_x<-0.4 then
				flipped_x=true
				dx=3
			elseif entity.facing_x<0.4 then
				sprite=13
			end
			if entity.facing_y<-0.4 then
				flipped_y=true
				dy=3
			elseif entity.facing_y<0.4 then
				sprite=45
			end
			-- flip through the walk cycle
			if not entity.is_in_freefall and (entity.vx!=0 or entity.vy!=0) then
				if scene_frame%10>=5 then
					sprite+=2
				else
					sprite+=1
				end
			end
			spr(sprite,entity.x+0.5-dx,entity.y+0.5-dy,1,1,flipped_x,flipped_y)
		end,
		["spin_web_point"]=function(entity,can_be_fixed,is_being_spun)
			-- search for an existing web point
			if can_be_fixed then
				local web_point
				local square_dist
				web_point,square_dist=calc_closest_web_point(entity.x,entity.y,true,true)
				if web_point and square_dist<81 then
					return web_point
				end
			end
			-- otherwise just create a new one
			local is_fixed=can_be_fixed and is_solid_tile_at(entity.x,entity.y)
			return create_entity("web_point",{
				["x"]=entity.x,
				["y"]=entity.y,
				["vx"]=entity.vx-entity.facing_x,
				["vy"]=entity.vy-entity.facing_y,
				["has_been_anchored"]=is_fixed,
				["is_being_spun"]=is_being_spun,
				["is_in_freefall"]=not is_fixed
			})
		end,
		["finish_spinning_web"]=function(entity)
			foreach(web_points,function(web_point)
				web_point.is_being_spun=false
			end)
		end
	},
	["web_point"]={
		["friction"]=0.1,
		["gravity"]=0.02,
		["mass"]=1,
		["num_strands"]=0,
		["caught_bug"]=nil,
		["add_to_game"]=function(entity)
			add(web_points,entity)
		end,
		["update"]=function(entity)
			if entity.is_in_freefall then
				entity.vy+=entity.gravity
				entity.vx*=(1-entity.friction)
				entity.vy*=(1-entity.friction)
				entity.vx=mid(-3,entity.vx,3)
				entity.vy=mid(-3,entity.vy,3)
				entity.x+=entity.vx
				entity.y+=entity.vy
			end
			if entity.x<-20 or entity.x>147 or entity.y<-20 or entity.y>180 then
				entity.die(entity)
			end
			-- we use a silly solution to count strand connections
			-- a point without any strands shouldn't exist
			if entity.frames_alive>1 and entity.num_strands==0 then
				entity.die(entity)
			end
			entity.num_strands=0
		end
	},
	["web_strand"]={
		["render_layer"]="web",
		["spring_force"]=0.25,
		["elasticity"]=1.65,
		["base_length"]=5,
		["stretched_length"]=5,
		["break_length"]=25,
		["percent_elasticity_remaining"]=1,
		["add_to_game"]=function(entity)
			add(web_strands,entity)
		end,
		["update"]=function(entity)
			local from=entity.from
			local to=entity.to
			-- count points attached to the strand
			if from.class_name=="web_point" then
				from.num_strands+=1
			end
			if to.class_name=="web_point" then
				to.num_strands+=1
			end
			-- strands transfer anchored status
			if from.class_name=="web_point" and to.class_name=="web_point" and not from.is_being_spun and not to.is_being_spun and (from.has_been_anchored or to.has_been_anchored) then
				from.has_been_anchored=true
				to.has_been_anchored=true
			end
			-- find the current length of the strand
			local dx=to.x-from.x
			local dy=to.y-from.y
			local len=sqrt(dx*dx+dy*dy)
			-- if the strand stretches too far, it loses elasticity
			local min_len=entity.base_length*(1+entity.elasticity)
			local max_len=entity.break_length -- not multiplied by elasticity b/c it is 0 at the break length
			if len>min_len then
				local percent_elasticity=mid(0,1-((len-min_len)/(max_len-min_len)),1)
				if percent_elasticity<=entity.percent_elasticity_remaining then
					entity.percent_elasticity_remaining=percent_elasticity
					entity.stretched_length=len/(1+entity.elasticity*percent_elasticity)
				end
			end
			-- bring the two points closer to each other
			if len>entity.stretched_length and entity.percent_elasticity_remaining>0 then
				local elastic_dist=len-entity.stretched_length
				local f=elastic_dist*entity.spring_force
				local m1=from.mass
				local m2=to.mass
				if from.is_in_freefall then
					from.vx+=mid(-2,f*(m2/m1)*(dx/len),2)
					from.vy+=mid(-2,f*(m2/m1)*(dy/len),2)
				end
				if to.is_in_freefall then
					to.vx-=mid(-2,f*(m1/m2)*(dx/len),2)
					to.vy-=mid(-2,f*(m1/m2)*(dy/len),2)
				end
			end
			-- die if the strand gets too long or if the points die
			if len>=entity.break_length or not from.is_alive or not to.is_alive then
				entity.die(entity)
			end
		end,
		["draw"]=function(entity)
			if entity.percent_elasticity_remaining>0.7 then
				color(7)
			elseif entity.percent_elasticity_remaining>0.5 then
				color(15)
			elseif entity.percent_elasticity_remaining>0.2 then
				color(9)
			else
				color(8)
			end
			line(entity.from.x,entity.from.y,entity.to.x,entity.to.y)
		end,
		["set_to"]=function(entity,to)
			entity.to=to
		end,
		["set_from"]=function(entity,from)
			entity.from=from
		end
	},
	["bug_spawn"]={
		["render_layer"]="far_background",
		["frames_to_death"]=15,
		["init"]=function(entity,args)
			entity.color=bug_species[entity.species].colors[1]
		end,
		["draw"]=function(entity)
			colorwash(entity.color)
			spr(123+flr(entity.frames_alive/3),entity.x-3,entity.y-4)
			pal()
		end,
		["on_death"]=function(entity)
			create_entity("bug",{
				["species"]=entity.species,
				["x"]=entity.x,
				["y"]=entity.y
			})
		end
	},
	["bug"]={
		["render_layer"]="background",
		["is_catchable"]=false,
		["caught_web_point"]=nil,
		["frames_until_escape"]=0,
		["vy"]=0.5,
		["add_to_game"]=function(entity)
			add(bugs,entity)
		end,
		["init"]=function(entity,args)
			local k
			local v
			for k,v in pairs(bug_species[entity.species]) do
				entity[k]=v
			end
			local c=entity.colors
			create_entity("ripple",{
				["target"]=entity,
				["frames_to_death"]=48,
				["starting_radius"]=19,
				["expansion_rate"]=-1/3,
				["colors"]={entity.colors[4]},
				["color_tween"]="shrinking"
			})
		end,
		["update"]=function(entity)
			-- bugs move downwards while spawning
			if entity.frames_alive<45 then
				entity.vy-=0.01
			-- bugs become catchable after spawning
			elseif entity.frames_alive==45 then
				entity.render_layer="midground"
				entity.is_catchable=true
				entity.vy=0
			-- bugs escape after a pause
			elseif entity.frames_alive>80 and entity.is_catchable then
				entity.escape(entity)
			end
			-- bugs can be caught in webs
			if entity.is_catchable then
				local web_point
				local square_dist
				web_point,square_dist=calc_closest_web_point(entity.x,entity.y,true,false)
				if web_point and square_dist<64 then
					entity.is_catchable=false
					entity.caught_web_point=web_point
					web_point.caught_bug=entity
					entity.frames_until_escape=flr(60+30*rnd())
				end
			end
			-- bugs escape webs in time or if they break
			if entity.frames_until_escape>0 then
				entity.frames_until_escape=decrement_counter(entity.frames_until_escape)
				if entity.frames_until_escape<=0 then
					entity.escape(entity)
				end
			end
			if entity.caught_web_point and not entity.caught_web_point.is_alive then
				entity.escape(entity)
			end
			-- move the bug
			if entity.caught_web_point then
				entity.x=entity.caught_web_point.x
				entity.y=entity.caught_web_point.y
			else
				entity.x+=entity.vx
				entity.y+=entity.vy
			end
		end,
		["draw"]=function(entity)
			local sprite=entity.base_sprite
			if entity.caught_web_point then
				sprite+=4+flr(entity.frames_alive/5)%3
			else
				if entity.frames_alive%6<3 then
					sprite+=1
				end
				if entity.is_catchable then
					sprite+=2
				end
				if entity.frames_to_death>0 then
					sprite+=2
					colorwash(entity.colors[4-flr(entity.frames_to_death/4)])
				end
			end
			spr(sprite,entity.x-3,entity.y-4)
			pal()
		end,
		["escape"]=function(entity)
			create_entity("ripple",{
				["target"]=entity,
				["frames_to_death"]=8,
				["starting_radius"]=2,
				["expansion_rate"]=1,
				["colors"]=entity.colors,
				["color_tween"]="expanding"
			})
			if entity.caught_web_point then
				entity.caught_web_point.caught_bug=nil
				entity.caught_web_point=nil
			end
			entity.render_layer="foreground"
			entity.is_catchable=false
			entity.frames_to_death=12
			entity.vy=-1
		end,
		["on_death"]=function(entity)
			if entity.caught_web_point then
				entity.caught_web_point.caught_bug=nil
			end
		end
	},
	["bug_wings"]={
		["frames_to_death"]=20,
		["draw"]=function(entity)
			spr(106+flr(5*entity.frames_alive/20),entity.x-3,entity.y-4)
		end
	},
	["floating_points"]={
		["render_layer"]="far_foreground",
		["frames_to_death"]=20,
		["vy"]=-1,
		["update"]=function(entity)
			entity.x+=entity.vx
			entity.y+=entity.vy
		end,
		["draw"]=function(entity)
			print(entity.text,entity.x-2*#entity.text,entity.y-2,entity.colors[max(1,flr(entity.frames_alive/2-5))])
		end
	},
	["ripple"]={
		["render_layer"]="far_background",
		["draw"]=function(entity)
			local x=entity.x
			local y=entity.y
			if entity.target then
				x=entity.target.x
				y=entity.target.y
			end
			-- if entity.color_tween=="expanding" then
				color(entity.colors[max(1,1+#entity.colors-ceil(entity.frames_to_death/2))])
			-- else
			-- 	color(entity.colors[flr(1+entity.frames_to_death/6)])
			-- end
			circ(x,y,entity.starting_radius+entity.expansion_rate*entity.frames_alive)
		end
	}
}


-- main functions
function _init()
	init_scene("game")
end

function _update()
	actual_frame=increment_looping_counter(actual_frame)
	if actual_frame%frame_skip>0 then
		return
	end
	scene_frame=increment_looping_counter(scene_frame)
	scenes[scene][2]()
end

function _draw()
	camera()
	rectfill(0,0,127,127,0)
	scenes[scene][3]()
end


-- title functions
function update_title()
	if btnp(4) and scene_frame>5 then
		init_scene("game")
	end
end

function draw_title()
	sspr(0,0,48,32,40,32,48,32)
	line(73,64,73,80,7)
	spr(13,69,81)
	if scene_frame%30<20 then
		print("press z to start",32,106,7)
	end
end


-- game functions
function init_game()
	score=0
	timer=90
	entities={}
	new_entities={}
	bugs={}
	web_points={}
	web_strands={}
	tiles={}
	reset_tiles()
	load_tiles(levels[1].map,levels[1].tileset)
	spider=create_entity("spider",{
		["x"]=levels[1].spawn_point[1],
		["y"]=levels[1].spawn_point[2]
	})
end

function update_game()
	if scene_frame%80==3 then
		create_entity("bug_spawn",{
			["species"]="fly",
			["x"]=50,
			["y"]=50
		})
	end
	if scene_frame%30==0 then
		timer=decrement_counter(timer)
	end
	-- update entities
	foreach(entities,function(entity)
		-- call the entity's update function
		entity.update(entity)
		-- do some default update stuff
		entity.frames_alive=increment_looping_counter(entity.frames_alive)
		if entity.frames_to_death>0 then
			entity.frames_to_death-=1
			if entity.frames_to_death<=0 then
				entity.die(entity)
			end
		end
	end)
	-- add new entities to the game
	add_new_entities_to_game()
	-- remove dead entities from the game
	entities=filter_list(entities,is_alive)
	bugs=filter_list(bugs,is_alive)
	web_strands=filter_list(web_strands,is_alive)
	web_points=filter_list(web_points,is_alive)
end

function draw_game()
	camera(0,-8)
	-- draw each render layer
	foreach(render_layers,function(render_layer)
		-- draw the entities on this layer
		foreach(entities,function(entity)
			if entity.render_layer==render_layer then
				entity.draw(entity)
			end
		end)
		if render_layer=="background" then
			-- draw tiles
			foreach(tiles,function(tile)
				if tile then
					spr(tile.sprite,8*tile.col-8,8*tile.row-8,1,1,tile.is_flipped)
					-- uncomment to see terrain "hitboxes"
					-- if scene_frame%16<8 then
					-- 	local x=8*tile.col-8
					-- 	local y=8*tile.row-8
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
			end)
		end
	end)
	-- draw ui
	camera()
	-- draw webbing meter
	rectfill(0,0,127,7,0)
	if spider.is_spinning_web then
		color(7)
	else
		color(5)
	end
	rectfill(35,2,35+50*spider.webbing/spider.max_webbing,5)
	rect(35,1,85,6)
	spr(62,87,0)
	-- draw timer
	local timer_text=flr(timer/60)..":"
	local seconds=timer%60
	if seconds<10 then
		timer_text=timer_text.."0"
	end
	timer_text=timer_text..seconds
	if timer<=5 and scene_frame%30<=20 then
		color(8)
	else
		color(7)
	end
	print(timer_text,112,2)
	-- draw score
	local score_text
	if score<=0 then
		score_text="0"
	else
		score_text=score.."0"
	end
	print(score_text,1,2,7)
end


-- tutorial functions
function init_tutorial()
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

	if scene_frame>640 then
		if btn(4) then
			init_scene("game")
		elseif btn(5) then
			init_scene("tutorial")
		end
	end
	if btn(4) and btn(5) then
		init_scene("game")
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
			color(0)
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
	visible_bugs_eaten=0
	visible_score=0
end

function update_game_over()
	if (btnp(4) or btnp(5)) and scene_frame>=20 then
		if visible_bugs_eaten<bugs_eaten or visible_score<score then
			visible_bugs_eaten=bugs_eaten
			visible_score=score
		else
			init_scene("title")
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
				spr(63,67,101)
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


-- entity functions
function create_entity(class_name,args)
	-- create default entity
	local entity={
		["class_name"]=class_name,
		["render_layer"]="midground",
		["x"]=0,
		["y"]=0,
		["vx"]=0,
		["vy"]=0,
		["is_alive"]=0,
		["frames_alive"]=0,
		["frames_to_death"]=0,
		["add_to_game"]=noop,
		["init"]=noop,
		["update"]=noop,
		["draw"]=noop,
		["on_death"]=noop,
		["die"]=function(entity)
			entity.on_death(entity)
			entity.is_alive=false
		end
	}
	-- add class properties/methods onto it
	local k
	local v
	for k,v in pairs(entity_classes[class_name]) do
		entity[k]=v
	end
	-- add properties onto it from the arguments
	for k,v in pairs(args) do
		entity[k]=v
	end
	-- initialize it
	entity.init(entity,args)
	-- return it
	add(new_entities,entity)
	return entity
end

function add_new_entities_to_game()
	foreach(new_entities,function(entity)
		if entity.add_to_game(entity)!=false then
			add(entities,entity)
		end
	end)
	new_entities={}
end

function is_alive(entity)
	return entity.is_alive
end


-- tile functions
function reset_tiles()
	tiles={}
	local i
	for i=1,240 do
		tiles[i]=false
	end
end

function load_tiles(map,tileset_name)
	local c
	for c=1,16 do
		local r
		for r=1,15 do
			local s=sub(map[r],c,c)
			if s!=" " then
				tiles[c*15+r-15]=create_tile(s,tilesets[tileset_name],c,r)
			end
		end
	end
end

function create_tile(symbol,tileset,col,row)
	-- find index of the symbol
	local tile_index=1
	local i
	for i=1,#tile_symbols do
		if symbol==sub(tile_symbols,i,i) then
			tile_index=i
			break
		end
	end
	local is_flipped=(tile_index%2==0)
	local half_tile_index=ceil(tile_index/2)
	local solid_bits={255,255}
	if #tileset[2]>=2*half_tile_index then
		solid_bits={tileset[2][2*half_tile_index-1],tileset[2][2*half_tile_index]}
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
		["sprite"]=tileset[1]+half_tile_index-1,
		["col"]=col,
		["row"]=row,
		["is_flipped"]=is_flipped,
		["solid_bits"]=solid_bits
	}
end

function get_tile_at(x,y)
	if y>=0 then
		return tiles[1+flr(x/8)*15+flr(y/8)]
	end
end

function is_solid_tile_at(x,y)
	local tile=get_tile_at(x,y)
	if tile then
		-- turn the position into a bit 1 to 16
		local bit=1+flr(x/2)%4+4*(flr(y/2)%4)
		-- check that against the tile's solid_bits
		if bit>8 then
			return band(2^(bit-9),tile.solid_bits[2])>0
		else
			return band(2^(bit-1),tile.solid_bits[1])>0
		end
	end
	return false
end


-- math functions
function ceil(n)
	return -flr(-n)
end

function calc_square_dist(x1,y1,x2,y2)
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


-- web functions
function calc_closest_web_point(x,y,allow_unanchored,allow_occupied)
	local square_dist
	local closest_web_point=nil
	local closest_square_dist=nil
	foreach(web_points,function(web_point)
		if not web_point.is_being_spun and
			(allow_occupied or not web_point.caught_bug) and
			(allow_unanchored or web_point.has_been_anchored) then
			square_dist=calc_square_dist(x,y,web_point.x,web_point.y)
			if closest_square_dist==nil or square_dist<closest_square_dist then
				closest_web_point=web_point
				closest_square_dist=square_dist
			end
		end
	end)
	return closest_web_point,closest_square_dist
end

function calc_closest_spot_on_web(x,y,allow_unanchored)
	local closest_web_point
	local closest_square_dist
	closest_web_point,closest_square_dist=calc_closest_web_point(x,y,allow_unanchored,true)
	local closest_x=nil
	local closest_y=nil
	if closest_web_point then
		closest_x=closest_web_point.x
		closest_y=closest_web_point.y
	end
	foreach(web_strands,function(web_strand)
		if not web_strand.from.is_being_spun and not web_strand.to.is_being_spun and
			(allow_unanchored or (web_strand.from.has_been_anchored and web_strand.to.has_been_anchored)) then
			local x2
			local y2
			x2,y2=calc_closest_point_on_line(
				web_strand.from.x,web_strand.from.y,
				web_strand.to.x,web_strand.to.y,
				x,y)
			if x2!=nil and y2!=nil then
				local square_dist=calc_square_dist(x,y,x2,y2)
				if closest_square_dist==nil or square_dist<closest_square_dist then
					closest_x=x2
					closest_y=y2
					closest_square_dist=square_dist
				end
			end
		end
	end)
	return closest_x,closest_y,closest_square_dist
end


-- helper functions
function noop() end

function init_scene(s)
	actual_frame=0
	scene=s
	scene_frame=0
	scenes[scene][1]()
end

function increment_looping_counter(n)
	n+=1
	if n>32000 then
		n-=10000
	end
	return n
end

function decrement_counter(n)
	return max(0,n-1)
end

function colorwash(c)
	local i
	for i=1,15 do
		pal(i,c)
	end
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


-- set up the scenes now that the functions are defined
scenes={
	["title"]={noop,update_title,draw_title},
	["game"]={init_game,update_game,draw_game},
	["tutorial"]={init_tutorial,update_tutorial,draw_tutorial},
	["game_over"]={init_game_over,update_game_over,draw_game_over}
}


-- 	-- limit velocity
-- 	spider.vx=mid(-spider.max_speed,spider.vx,spider.max_speed)
-- 	spider.vy=mid(-spider.max_speed,spider.vy,spider.max_speed)

-- 	-- keep dat spider in bounds so long as she isn't freefalling
-- 	if spider.is_on_tile then
-- 		spider.x=mid(0,spider.x,127)
-- 		spider.y=mid(0,spider.y,119)
-- 	end

-- 	foreach(bugs,function(bug)
-- 		local square_dist=calc_square_dist(spider.x,spider.y,bug.x,bug.y)
-- 		if square_dist<=49 and bug.is_alive and (bug.state=="active" or bug.state=="caught") then
-- 			create_bug_death_effect(bug)
-- 			create_floating_text_effect("+"..bug.score.."0",bug.colors[1],bug.x-4,bug.y)
-- 			sfx(7,1)
-- 			bug.is_alive=false
-- 			score+=bug.score
-- 			bugs_eaten+=1
-- 			spider.webbing=min(spider.webbing+2,spider.max_webbing)
-- 		end
-- 	end)

-- 	if spider.hitstun>0 then
-- 		spider.hitstun-=1
-- 	end

-- 	-- -- if the spider does wind up out of bounds, she's dead :'(
-- 	-- if spider.x<-8 or spider.x>135 or spider.y<-200 or spider.y>127 then
-- 	-- 	spider.is_alive=false
-- 	-- end

-- 	-- actually just keep the spider in bounds
-- 	if spider.x<3 then
-- 		spider.x=3
-- 		spider.vx=max(0,spider.vx)
-- 	end
-- 	if spider.x>124 then
-- 		spider.x=124
-- 		spider.vx=min(0,spider.vx)
-- 	end
-- 	if spider.y<3 then
-- 		spider.y=3
-- 		spider.vy=max(0,spider.vy)
-- 	end
-- 	if spider.y>116 then
-- 		spider.y=116
-- 		spider.vy=min(0,spider.vy)
-- 	end
-- end

-- 	-- bug stays attached to web point
-- 	if bug.caught_web_point then
-- 		if not bug.caught_web_point.is_alive then
-- 			bug.caught_web_point=nil
-- 			bug.state="escaping"
-- 			bug.state_frames=0
-- 		else
-- 			bug.x=bug.caught_web_point.x
-- 			bug.y=bug.caught_web_point.y
-- 			bug.strength=min(bug.strength+0.01,bug.max_strength)
-- 			if bug.species=="beetle" then
-- 				if bug.state_frames>140 then
-- 					bug.caught_web_point.is_alive=false
-- 				end
-- 			elseif bug.species=="firefly" then
-- 				if bug.state_frames>=130 then
-- 					create_explosion_effect(bug.x,bug.y)
-- 					sfx(9,0)
-- 					bug.is_alive=false
-- 					foreach(web_points,function(web_point)
-- 						local dist=sqrt(calc_square_dist(bug.x,bug.y,web_point.x,web_point.y))
-- 						if dist<10 then
-- 							web_point.is_alive=false
-- 						elseif dist<30 then
-- 							local x
-- 							local y
-- 							x,y=create_vector(web_point.x-bug.x,web_point.y-bug.y,(30-dist)/8)
-- 							web_point.vx+=x
-- 							web_point.vy+=y
-- 						end
-- 					end)
-- 					local square_dist=sqrt(calc_square_dist(bug.x,bug.y,spider.x,spider.y))
-- 					if square_dist<400 then
-- 						local x
-- 						local y
-- 						x,y=create_vector(spider.x-bug.x,spider.y-bug.y,6)
-- 						spider.hitstun=15
-- 						spider.vx+=x
-- 						spider.vy+=y
-- 					end
-- 				end
-- 			elseif scene_frame%4==0 and rnd(1)<0.4 then
-- 				local dir=rnd(20)
-- 				if dir>15 then -- extra chance of moving up
-- 					bug.caught_web_point.vy-=bug.strength
-- 				elseif dir>10 then -- extra chance of moving up and to the left
-- 					bug.caught_web_point.vx-=bug.strength*0.7
-- 					bug.caught_web_point.vy-=bug.strength*0.7
-- 				elseif dir>5 then -- extra chance of moving up and to the right
-- 					bug.caught_web_point.vx+=bug.strength*0.7
-- 					bug.caught_web_point.vy-=bug.strength*0.7
-- 				elseif dir>4 then
-- 					bug.caught_web_point.vx-=bug.strength*0.7
-- 					bug.caught_web_point.vy+=bug.strength*0.7
-- 				elseif dir>3 then
-- 					bug.caught_web_point.vx+=bug.strength*0.7
-- 					bug.caught_web_point.vy+=bug.strength*0.7
-- 				elseif dir>2 then
-- 					bug.caught_web_point.vx+=bug.strength
-- 				elseif dir>1 then
-- 					bug.caught_web_point.vx-=bug.strength
-- 				else
-- 					bug.caught_web_point.vy+=bug.strength
-- 				end
-- 				if bug.strength>=bug.max_strength and rnd(1)<0.1 then
-- 					bug.state="escaping"
-- 					bug.state_frames=0
-- 					bug.caught_web_point=nil
-- 				end
-- 			end
-- 		end

-- function create_bug_spawner(x,y,species,amt,vx,vy)
-- 	local effect={
-- 		["x"]=x,
-- 		["y"]=y,
-- 		["species"]=species,
-- 		["amt"]=amt,
-- 		["vx"]=vx,
-- 		["vy"]=vy,
-- 		["frames_alive"]=0,
-- 		["is_alive"]=true,
-- 		["update"]=function(effect)
-- 			if effect.frames_alive%15==0 then
-- 				create_bug_of_species(effect.species,effect.x,effect.y)
-- 				sfx(8,0)
-- 				effect.amt-=1
-- 				if effect.amt<=0 then
-- 					effect.is_alive=false
-- 				else
-- 					effect.x+=8*effect.vx
-- 					effect.y+=8*effect.vy
-- 				end
-- 			end
-- 			effect.frames_alive+=1
-- 		end,
-- 		["draw"]=function(effect) end
-- 	}
-- 	add(effects,effect)
-- 	return effect
-- end

-- function create_explosion_effect(x,y)
-- 	local effect={
-- 		["x"]=x,
-- 		["y"]=y,
-- 		["frames_alive"]=0,
-- 		["is_alive"]=0,
-- 		["update"]=function(effect)
-- 			effect.frames_alive+=1
-- 			if effect.frames_alive>=12 then
-- 				effect.is_alive=false
-- 			end
-- 		end,
-- 		["draw"]=function(effect)
-- 			local x=effect.x+rnd(2)-1
-- 			local y=effect.y+rnd(2)-1
-- 			if effect.frames_alive<4 then
-- 				circfill(x,y,10,7)
-- 			elseif effect.frames_alive<8 then
-- 				circfill(x,y,15,6)
-- 			elseif effect.frames_alive<10 then
-- 				circfill(x,y,17,5)
-- 			else
-- 				circfill(x,y,18,1)
-- 			end
-- 		end
-- 	}
-- 	add(effects,effect)
-- 	return effect
-- end

-- function create_vector(x,y,magnitude)
-- 	local length=sqrt(x*x+y*y)
-- 	if length==0 then
-- 		return 0,0
-- 	else
-- 		return x*magnitude/length,y*magnitude/length
-- 	end
-- end

__gfx__
00000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000700000007000
00000077770000000000070700000000000000000000000008000800080008000800080008000800080008000800080008000800000777000007770000077700
000077700d7700000000070700000000000000000000000000808000008080000080800000808000008080000080800000808000070777070007770707077700
00077600000770000500070700000000000000000000000000080000000800000008000000080000000800000008000000080000007777700777777000777777
00777000000070005050770600000000000000000000000000808000008080000080800000808000008080000080800000808000000777000007770000077700
007650000000d700d00077d000000000000000000000000008000800080008000800080008000800080008000800080008000800007171700771717000717177
00670000000007000ddd770000007770007700777dd0000000000000000000000000000000000000000000000000000000000000070707070007070707070700
0077d00000000700000077000007007007070700000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0077700000000700076070007d07770070070077000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007770000007000700770060707000d7007000070d0000008000800080008000800080008000800080008000800080008000800077707000777007007770700
000777700005700007770677700077700777077700d0000000808000008080000080800000808000008080000080800000808000077777000777770707777700
0000777775d6000000005500000000000007d000000ddd0000080000000800000008000000080000000800000008000000080000077777770777777007777777
00000777777000000050000000070000007700000ddd0d0000808000008080000080800000808000008080000080800000808000007771700077717000777170
0000dd777777600000055ddd000700000707ddddd000d00008000800080008000800080008000800080008000800080008000800077717070777170700771707
000666d777767700000000007dd77dddd7d700000000000000000000000000000000000000000000000000000000000000000000000770000007700007077000
00777500777767700000000707070077077000005000000000000000000000000000000000000000000000000000000000000000000707000007070000700700
07770000077776770000000707070570700000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d7700000007776676005000707007007dddddd000000000008000800080008000800080008000800080008000800080008000800007000700007070000700070
77700077660777667050507706000000000000000000000000808000008080000080800000808000008080000080800000808000000707000007070000070700
77000700006d776676d00077d0000000000000000000000000080000000800000008000000080000000800000008000000080000077771700777717007777170
7700700000076777770ddd7700000077007007600777000000808000008080000080800000808000008080000080800000808000777777007777770077777700
770070007700777667000077000007007070070d7007000008000800080008000800080008000800080008000800080008000800077771700777717007777170
777070007700777667076070007d07007007070077700ddd00000000000000000000000000000000000000000000000000000000000707000007070000070700
777007000600077676700770060707007dd707007000d00d00000000000000000000000000000000000000000000000000000000007000700070007000070700
07770077700007777007770677700077d00d70000777ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000
077700000000777760000dddd000000000dd0000000d000008000800080008000800080008000800080008000800080008000800080008007750055000d0d000
007770000000777700000d000500000006005000ddd000000080800000808000008080000080800000808000008080000080800000808000777700500ddddd00
0007776000067770000000ddd0500000060005dd000000000008000000080000000800000008000000080000000800000008000000080000777777000ddddd00
0000777777777d00000000000dddddddd6dddd000000000000808000008080000080800000808000008080000080800000808000008080000077777700ddd000
000000777760000000000000000055000700050000000000080008000800080008000800080008000800080008000800080008000800080005007777000d0000
00000000000000000000000000000055575550000000000000000000000000000000000000000000000000000000000000000000000000000550057700000000
00000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008708000080087700000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000087000800800008070800080008000800
000000000000000007707700000000000d06600000d6600000660000008280000782870077828770008280000022000078088000080880000080800000808000
007007000000000006ccc60007ccc70000cdc00000cdc00000dcc000078287000682860066828660778287700828800078882000088820000008000000080000
000cc000007cc70000dcd00006dcd6000cccc0000cccc0000dccd600068886000088800008282800662826608282880078ee880008ee88000080800000808000
000cc000000cc00000ccc00000ccc00000cdc60000cdc00000ccc600000000000000000050e8e05050e8e0508888880007eeee0000eeee000800080008000800
00000000000000000d0c0d000d0c0d0000d066000d0660000c00d000000000000000000000808000008080008272820002020200020202000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000878000000000000000000000000000000000000
00000000000000000000000000000000000000020022000000000000000000080088000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000066020004440000006602000066080004440000006608080008000800080008000800080008000800080008000800
00000000000000000099900000999000009942400092442200999602008842400082448800888608008080000080800000808000008080000080800000808000
70aa070000aa000022aaa22022aaa22009aa444009a4420009aaa424088944400894420008899424000800000008000000080000000800000008000000080000
0a44a0000a44a0007a444a700a444a0009aa424009aaa96009aaa444089942400899986008999444008080000080800000808000008080000080800000808000
0944900079449700092429006924296009aaa90209aaa96009aaa424088998080889886008899424080008000800080008000800080008000800080008000800
00000000000000000044400070444070009996020099900000999602008886080088800000888608000000000000000000000000000000000000000000000000
00000000000000000400040004000400000000000000000000006602000000000000000000006608000000000000000000000000000000000000000000000000
00000000000000000033000000330000000000000000000000000000000000000000000000000000000000007700777000000000000000000000000000000000
0033000000330000003b0000003b0000005bb6000000000005350000000000000007700000777700000076006670066006700700000000000000000008000800
703b0700003b000070330070003300000035bb0000bb6b006b500000000770000070070007000070067076000000000067000677000000060000000000808000
073b7000003b0000673b0760003b0000050b36600b336b600bb50000007777000707707007000070067070000000000077000067600005560000000000080000
00bb000007bb700006bbb60007bbb70000533b000335bb6006303300007777000707707007000070007000000000000000000000560006600000000000808000
0033000070330700035b5000765b56700333300003305b0006b33300000770000070070007000070000000000000000000000000560000000550055008000800
0000000000000000003330006033306003bb30000005350000b3b000000000000007700000777700000000000000000000000000000000000550055000000000
00000000000000000500050005000500000000000000000000000000000000000000000000000000000000000000000000000000000000005500005500000000
00000000000000000500050005000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
005050000050500070aaa07000aaa00000d5a000066a5a0000500d00080008000800080008000800080008000000000000070000000007000000000000000000
075a5700005a5000675a5760005a5000005aaa00566a5aa05aa50550008080000080800000808000008080000700000000070000700770000000000000000000
069a9600079a9700069a9600079a9700000555000a5955a005a95aa0000800000008000000080000000800000077000000770000077770000007077000070000
0055500006555600005550007655567009a9a6600aaa0d5009aa5aa0008080000080800000808000008080000077700007777700007770000077700007777700
00a7a00000a7a00000a9a00060a9a06005a5a6600a59000006a5aa00080008000800080008000800080008000007700000077000007777007707000000070000
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

