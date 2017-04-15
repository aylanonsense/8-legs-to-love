pico-8 cartridge // http://www.pico-8.com
version 8
__lua__


-- set cart data (for saving and loading high scores)
cartdata("bridgs_8legstolove_1_test1")

-- global vars
local scene
local next_scene
local transition_frames_left=0
local scene_frame
local level_num
local level
local score
local score_cumulative
local bugs_eaten
local timer
local frames_until_spawn_bug
local spawns_until_pause
local spider
local entities
local new_entities
local web_points
local web_strands
local moving_platforms
local tiles
local level_spawn_points
local wind_frames
local wind_dir
local wind_x
local wind_y
local debug_text
local menu_buttons
local is_story_mode


-- constants
local tile_symbols="abcdefghijklmnopqrstuvwxyz0123456789!@#$%^()-=[]{}:;<>/?`~"
local tile_flip_matrix={8,4,2,1,128,64,32,16}
local scenes={}
local levels={
	-- spawn_x,spawn_y,tileset,tiles,hazard,has_bottom
	{20,75,"garden","m##n        vrqn !@      vtr #$n !@  qsu   vr#$n !@qsu  . . o#@n opp  . .+. m!@ i86l .+.*.+. !@ e666j .+*+ ..!@ e669f.+*..+. !@ g666f..+*+. .!@ e686f.+.*+.. op e666f +*+.. w%^xe669h.+.+. y-(((g866j . .. 0((((c544daaaaaac44542233222222322323",nil,true},
	{75,107,"house","       $00#            $00#            $00#            $00#          ..)88(.mo      .+. . . .ksp!!!%.++.++.+.kul000# +.*+**+.kul000#.+*+.+*+.cwd888(.++*+.++ e0f   ..+*+.+*+.gyh    ++..++++.qyr     .ab ... i0j    444444444444    246324632643","paintings"},
	{27,51,"bridge","wxwx        mwxwxwxn          yi ymwl. .   .okz kyi  .*+*+.kxwxl y .+.+.++.. jz  z  . .. .    y 444424476555555300000eg..hf11111000eg. . ..hf111!0c ..+**+. .d1@80a.+++*+*++ b19#!  +++.++.+  @$#8   . . ..   9$#vssssssssssqsu$vssssssssssssssu","river"},
	{30,35,"construction","  0y     c    wy  wy     k    wy  wy     i    wy  wy   +...+  wyssoqsu.+*+*+.mso  wy...+.+*+..wy  wy.+++*+.++.wy  wy.+*.*++*+.wy  wy.+*.**.*+.0y  wy.+.*+.**+.wy  wy.++*+**++.wyg wy..+++++...wyoqssu  ...  msoq  wy          wyaawybbaabbaa awy","platforms"},
	{97,72,"skyscrapers","                          e            gkkikkkm    . +. . o     c. .*+.++.oawwu %u.+*+.*+.qww(u %u ++*.++ s(((u %u..+.**+.s(((u %%u .*+*+ s((-u %%u.+**+..s([-u %%u ++.*+.s(768 %%u. .+*+.s(@!# %%zy0.+*. s(@!# %%324.+...s(@!# %%324   768(@!# ","wind"},
	{64,20,"space"," b   b a 8   a  b  a 6 +..a78  b @da..b*++.a.6    .++.a..b.+. 9 a +*b.gefh..* a   *+.i#(#^j...  9 ++bk%#-)n.2  a  .a.m$)[%l.b.   a.4.o^-][p.+*b   +. .qsura..  b b .a. ..b.+.6  a w{y.+*++*+  a   ;:{ b+.+ a      1<0   a bc!  ba a   b         ","space",true}
}
local tutorial_level={30,35,"construction","                                                                                                                 mssu      moqu   wy        wy    wy        wy    wy        wy    wy        wy   msoqsoqssssoqu   wy        wy    wy        wy  "}
local tilesets={
	-- base_sprite,{solid_bits}
	garden={172,{240,255, 254,255, 204,204, 204,136, 200,204, 236,255, 204,204, 255,255, 232,254, 255,63, 127,1, 200,254, 200,204, 204,204}},
	house={126,{0,238, 236,206, 140,200, 236,254, 255,206, 204,204, 255,207, 119,255}},
	bridge={236,{19,17, 127,51, 255,63, 63,0, 127,19, 238,142, 255,255, 0,240, 0,0, 0,0, 206,8}},
	construction={195,{0,0, 0,0, 0,255, 0,255}},
	skyscrapers={148,{0,200, 119,119, 238,238, 247,255, 254,255, 240,255, 112,255, 238,238, 238,238, 204,204, 51,51}},
	space={209,{0,0, 0,0, 252,255, 128,254, 200,236, 238,238, 238,238, 206,140, 239,8, 255,207, 255,63, 200,254, 49,247, 127,19, 247,127, 255,102, 238,63}},
}
local bug_species={
	-- species_name,base_sprite,colors,points,wiggles
	{"fly",64,{12,13,5,1},1,true},
	{"beetle",80,{8,13,2,1},2},
	{"firefly",96,{9,4,2,1},3},
	{"hornet",112,{10,9,5,1},5,true},
	{"dragonfly",73,{11,3,5,1},5,true}
}
local entity_classes={
	spider={
		vx_strands=0,
		vy_strands=0,
		render_layer=7,
		mass=4,
		-- webbing=70,
		max_webbing=70,
		facing_x=0,
		facing_y=1,
		length_of_spun_web=0,
		walk_counter=0,
		-- is_on_tile=false,
		-- is_on_web=false,
		-- is_in_freefall=false,
		-- is_spinning_web=false,
		-- is_placing_web=false,
		-- spun_strand=nil,
		-- moving_platform=nil,
		frames_of_tile_grace=0,
		frames_until_spin_web=0,
		web_uncollision_frames=0,
		hitstun_frames=0,
		-- button_left=false,
		-- button_right=false,
		-- button_up=false,
		-- button_down=false,
		-- button_spin=false,
		-- button_spin_press=false,
		instruction_index=1,
		frames_since_instruction=0,
		init=function(self)
			if not self.webbing then
				self.webbing=self.max_webbing
			end
		end,
		update=function(self)
			self.button_spin_press=false
			self.frames_since_instruction=increment_looping_counter(self.frames_since_instruction)
			if self.instructions then
				if #self.instructions>self.instruction_index and self.instructions[self.instruction_index]<=self.frames_since_instruction then
					local instruction=self.instructions[self.instruction_index+1]
					self.button_left=(char_at(instruction,2)=="a")
					self.button_right=(char_at(instruction,4)=="d")
					self.button_up=(char_at(instruction,1)=="w")
					self.button_down=(char_at(instruction,3)=="s")
					self.button_spin=(char_at(instruction,5)=="z")
					self.button_spin_press=(char_at(instruction,6)=="+")
					self.instruction_index+=2
					self.frames_since_instruction=0
				end
			else
				self.button_left=btn(0)
				self.button_right=btn(1)
				self.button_up=btn(2)
				self.button_down=btn(3)
				self.button_spin=btn(4)
				self.button_spin_press=btnp(4)
			end
			-- decrement counters
			decrement_counter_prop(self,"web_uncollision_frames")
			decrement_counter_prop(self,"hitstun_frames")
			decrement_counter_prop(self,"frames_of_tile_grace")
			decrement_counter_prop(self,"walk_counter")
			-- figure out if the spider is supported by anything
			local web_x,web_y,web_square_dist=calc_closest_spot_on_web(self.x,self.y,false)
			local was_in_freefall=self.is_in_freefall
			self.is_on_web=web_x!=nil and web_square_dist<=9 and self.web_uncollision_frames<=0 and self.hitstun_frames<=0
			self.is_on_tile=is_solid_tile_at(self.x,self.y) and self.hitstun_frames<=0
			self.moving_platform=self.hitstun_frames<=0 and get_moving_platform_at(self.x,self.y) or nil
			self.is_in_freefall=not self.moving_platform and not self.is_on_tile and not self.is_on_web
			if self.is_on_tile then
				self.frames_of_tile_grace=8
			end
			-- when on web, the spider is pulled towards the strands
			if self.is_on_web and not self.is_on_tile then
				self.x+=(web_x-self.x)/5
				self.y+=(web_y-self.y)/5
			elseif self.is_on_tile then
				self.respawn_x,self.respawn_y=self.x,self.y
			end
			-- the spider falls if unsupported
			if self.is_in_freefall then
				apply_gravity(self,0.05,0.019,0.01)
			-- move the spider
			else
				if self.moving_platform then
					self.x+=self.moving_platform.vx
					self.y+=self.moving_platform.vy
				end
				self.vx,self.vy=(self.button_right and 1 or 0)-(self.button_left and 1 or 0),(self.button_down and 1 or 0)-(self.button_up and 1 or 0)
				-- make sure the spider doesn't move faster when moving diagonally
				if self.vx!=0 and self.vy!=0 then
					self.vx*=0.7
					self.vy*=0.7
				end
			end
			-- apply web_strand velocity
			if self.is_in_freefall then
				local mag=self.vx_strands*self.vx_strands+self.vy_strands*self.vy_strands
				self.vx+=self.vx_strands*mid(0,200*mag,1)
				self.vy+=self.vy_strands*mid(0,200*mag,1)
			end
			-- the spider stays under the speed limit
			self.vx,self.vy,self.vx_strands,self.vy_strands=mid(-2,self.vx,2),mid(-2,self.vy,2),0,0
			-- apply the spider's velocity
			self.x+=self.vx
			self.y+=self.vy
			-- keep track of which direction the spider is facing
			local speed=sqrt(self.vx*self.vx+self.vy*self.vy)
			if self.vx!=0 or self.vy!=0 then
				self.facing_x,self.facing_y=self.vx/speed,self.vy/speed
			end
			-- the spider stops spinning web if it gets cut off at the base
			decrement_counter_prop(self,"frames_until_spin_web")
			if (self.is_spinning_web or self.is_placing_web) and not self.spun_strand.is_alive then
				self.is_spinning_web,self.is_placing_web,self.spun_strand=false -- ,false,nil
				self:finish_spinning_web()
			end
			-- the spider places a spun web when z is pressed
			if self.is_placing_web and self.button_spin_press then
				local web_point=self:spin_web_point(true,false,true)
				self.spun_strand.from,self.is_placing_web,self.spun_strand=web_point -- ,false,nil
				if web_point.is_in_freefall and not web_point.has_been_anchored and speed>0.8 then
					self.web_uncollision_frames=4
				end
				sfx(3,1)
				self:finish_spinning_web()
			-- the spider starts spinning web when z is pressed
			elseif not self.is_spinning_web and self.button_spin_press and self.webbing>0 then
				self.is_spinning_web,self.frames_until_spin_web,self.length_of_spun_web=true,0,0
				local web_point=self:spin_web_point(true,true,false)
				self.spun_strand=create_entity("web_strand",{from=self,to=web_point})
				create_entity("web_length_hint",{
					x=self.x,
					y=self.y,
					web_point=web_point
				})
				-- play spinning sound
				sfx(2,1)
			-- the spider stops spinning web when z is no longer held or it's been spinning for too long
			elseif self.is_spinning_web and not self.button_spin then
				self.is_placing_web,self.is_spinning_web=true -- ,false
				-- stop spinning sound
				sfx(-1,1)
			end
			-- the spider continuously creates web while z is held
			if self.is_spinning_web and self.frames_until_spin_web<=0 and self.webbing>0 and self.length_of_spun_web<25 then
				local web_point=self:spin_web_point(false,true,false)
				self.length_of_spun_web+=1
				self.spun_strand.from=web_point
				self.frames_until_spin_web,self.spun_strand=5,create_entity("web_strand",{from=self,to=web_point})
				decrement_counter_prop(self,"webbing")
			end
			-- the spider stays in bounds
			self.x=mid(4,self.x,123)
			-- the spider can fall off the bottom of bottomless levels
			if level[5]=="river" then
				if self.y>110 and not self.is_on_tile then
					create_entity("splash",extract_props(self,{"x","y"}))
					self:die()
				end
			else
				self.y=(self.is_on_tile or level[6]) and mid(2,self.y,116) or max(2,self.y)
				if self.y>=130 then
					self:die()
				end
			end
			-- play a walking sound effect
			if self.walk_counter<=0 and not self.is_in_freefall and (self.vx!=0 or self.vy!=0) then
				self.walk_counter=7
				sfx(0,0)
			end
			-- play a jumping sound effect
			if self.is_in_freefall and not was_in_freefall then
				sfx(1,0)
			end
		end,
		draw=function(self)
			local sprite,dx,dy,flipped_x,flipped_y=29,3.5,3.5
			if self.facing_x<-0.4 then
				flipped_x,dx=true,2.5
			elseif self.facing_x<0.4 then
				sprite=13
			end
			if self.facing_y<-0.4 then
				flipped_y,dy=true,2.5
			elseif self.facing_y<0.4 then
				sprite=45
			end
			-- flip through the walk cycle
			if not self.is_in_freefall and (self.vx!=0 or self.vy!=0) then
				sprite+=1+flr(scene_frame%10/5)
			end
			if spider.hitstun_frames%4<2 then
				spr(sprite,self.x-dx,self.y-dy,1,1,flipped_x,flipped_y)
			end
		end,
		on_death=function(self)
			self:finish_spinning_web()
			create_entity("spider_respawn",extract_props(self,{"x","y","respawn_x","respawn_y","webbing"}))
		end,
		spin_web_point=function(self,can_be_fixed,is_being_spun,prefer_tile)
			local x,y=self.x,self.y
			local moving_platform=get_moving_platform_at(x,y)
			local is_fixed=can_be_fixed and (moving_platform or is_solid_tile_at(x,y))
			-- search for an existing web point
			if can_be_fixed and not (is_fixed and prefer_tile) then
				local web_point,square_dist=calc_closest_web_point(x,y,true,true)
				if square_dist<81 then
					return web_point
				end
			end
			-- there is a grace period where you can still spin web points onto tile
			if not is_fixed and can_be_fixed and self.frames_of_tile_grace>0 then
				is_fixed,x,y=true,self.respawn_x,self.respawn_y
			end
			-- otherwise just create a new one
			return create_entity("web_point",{
				x=x,
				y=y,
				vx=self.vx-self.facing_x,
				vy=self.vy-self.facing_y,
				has_been_anchored=is_fixed,
				is_being_spun=is_being_spun,
				is_in_freefall=not is_fixed,
				moving_platform=moving_platform
			})
		end,
		finish_spinning_web=function(self)
			foreach(web_points,function(web_point)
				web_point.is_being_spun=false
			end)
		end
	},
	web_length_hint={
		render_layer=8,
		radius=5,
		update=function(self)
			if self.web_point then
				self.x,self.y=self.web_point.x,self.web_point.y
			end
			if spider and spider.is_spinning_web and spider.webbing>0 and spider.length_of_spun_web<25 then
				self.radius+=1.5
			end
			if self.frames_to_death<=0 and (not self.web_point.is_alive or not spider or not spider.is_alive or not (spider.is_placing_web or spider.is_spinning_web)) then
				self.frames_to_death=3
			end
		end,
		draw=function(self)
			local x,y,f,a,s=self.x,self.y,self.frames_to_death -- ,nil,nil
			if self.radius<15 then
				s=20
			elseif self.radius<30 then
				s=12
			else
				s=8
			end
			for a=0,360,s do
				pset(x+self.radius*cos((a+self.frames_alive)/360),y+self.radius*sin((a+self.frames_alive)/360),7)
			end
		end
	},
	spider_respawn={
		frames_to_death=60,
		update=function(self)
			self.x+=(self.respawn_x-self.x)/self.frames_to_death
			self.y+=(self.respawn_y-self.y)/self.frames_to_death
		end,
		draw=function(self)
			local x,y,f=self.x,self.y,self.frames_to_death
			local r=(1100-(f-30)*(f-30))/100
			local s,c=r*sin(f/40),r*cos(f/40)
			color(7+self.frames_to_death/4%6)
			circ(x+s,y+c,1)
			circ(x-s,y-c,1)
			circ(x-c,y+s,1)
			circ(x+c,y-s,1)
		end,
		on_death=function(self)
			spider=create_entity("spider",extract_props(self,{"x","y","respawn_x","respawn_y","instructions","webbing"}))
		end
	},
	web_point={
		vx_strands=0,
		vy_strands=0,
		mass=1,
		-- is_soaked=false,
		-- has_strands_attached=false,
		-- caught_bug=nil,
		-- moving_platform=nil,
		add_to_game=function(self)
			add(web_points,self)
		end,
		update=function(self)
			if self.is_in_freefall then
				self.mass=1
				if level[5]=="river" and self.y>=110 then
					self.mass=2.5
				end
				apply_gravity(self,0.02,0.02,0.01)
				-- apply web_strand velocity
				self.vx+=self.vx_strands
				self.vy+=self.vy_strands
				self.vx_strands,self.vy_strands=0,0
				-- apply velocity
				self.vx,self.vy=0.9*mid(-3,self.vx,3),0.9*mid(-3,self.vy,3)
				self.x+=self.vx
				self.y+=self.vy
			elseif self.moving_platform then
				self.x+=self.moving_platform.vx
				self.y+=self.moving_platform.vy
			end
			if self.x<-20 or self.x>147 or self.y<-20 or self.y>180 then
				self:die()
			end
			-- we use a silly solution to count strand connections
			-- a point without any strands shouldn't exist
			if self.frames_alive>1 and not self.has_strands_attached then
				self:die()
			end
			self.has_strands_attached=false
		end
	},
	web_strand={
		render_layer=4,
		stretched_length=5,
		percent_elasticity_remaining=1,
		-- spring_force=0.25,
		-- elasticity=1.65,
		-- base_length=5,
		-- break_length=25,
		add_to_game=function(self)
			add(web_strands,self)
		end,
		update=function(self)
			local from,to=self.from,self.to
			-- count points attached to the strand
			from.has_strands_attached,to.has_strands_attached=true,true
			-- strands transfer anchored status
			if from.class_name=="web_point" and to.class_name=="web_point" and not from.is_being_spun and not to.is_being_spun and (from.has_been_anchored or to.has_been_anchored) then
				from.has_been_anchored,to.has_been_anchored=true,true
			end
			-- find the current length of the strand
			local dx,dy=to.x-from.x,to.y-from.y
			local len=sqrt(dx*dx+dy*dy)
			-- if the strand stretches too far, it loses elasticity
			local percent_elasticity=mid(0,(25-len)/11.75,1)
			if percent_elasticity<self.percent_elasticity_remaining then
				self.percent_elasticity_remaining,self.stretched_length=percent_elasticity,len/(1+1.65*percent_elasticity)
			end
			-- bring the two points closer to each other
			if len>self.stretched_length and self.percent_elasticity_remaining>0 then
				local f=(len-self.stretched_length)/4
				local from_mult,to_mult=f*to.mass/from.mass/len,f*from.mass/to.mass/len
				if from.is_in_freefall then
					from.vx_strands+=mid(-2,from_mult*dx,2)
					from.vy_strands+=mid(-2,from_mult*dy,2)
				end
				if to.is_in_freefall then
					to.vx_strands-=mid(-2,to_mult*dx,2)
					to.vy_strands-=mid(-2,to_mult*dy,2)
				end
			end
			-- die if the strand gets too long or if the points die
			if len>=25 or not from.is_alive or not to.is_alive then
				self:die()
			end
		end,
		draw=function(self)
			color(({8,8,9,15,7})[ceil(1+4*self.percent_elasticity_remaining)])
			if level[5]=="river" then
				if self.from.y>=115 and self.to.y>=115 then
					color(13)
				elseif self.from.y>=110 and self.to.y>=110 then
					color(6)
				end
			end
			line(self.from.x,self.from.y,self.to.x,self.to.y)
		end
	},
	bug_spawn_flash={
		render_layer=1,
		frames_to_death=15,
		draw=function(self)
			if self.frames_to_death<=15 then
				colorwash(bug_species[self.species][3][1])
				spr(44-ceil(self.frames_to_death/3),self.x-3,self.y-4)
				pal()
			end
		end,
		on_death=function(self)
			create_entity("bug",extract_props(self,{"species","x","y"}))
		end
	},
	bug={
		render_layer=2,
		-- is_catchable=false,
		-- caught_web_point=nil,
		frames_until_escape=0,
		vy=0.35,
		init=function(self)
			local k,v
			for k,v in pairs({"species_name","base_sprite","colors","points","wiggles"}) do
				self[v]=bug_species[self.species][k]
			end
			create_entity("spawn_ring",{target=self})
		end,
		update=function(self)
			-- bugs move downwards while spawning
			if self.frames_alive<45 then
				self.vy*=0.95
			-- bugs become catchable after spawning
			elseif self.frames_alive==45 then
				self.render_layer,self.is_catchable,self.vy=5,true,0
			-- bugs escape after a pause
			elseif self.frames_alive>80 and self.is_catchable then
				self:escape()
			end
			-- bugs can be caught in webs
			local species_name=self.species_name
			local web_point,square_dist=calc_closest_web_point(self.x,self.y,true) -- could be costly to always do
			if self.is_catchable and web_point and square_dist<64 then
				self.frames_until_escape,self.caught_web_point,web_point.caught_bug,self.is_catchable=175,web_point,self
				if species_name=="dragonfly" then
					self.frames_until_escape*=2
				end
			end
			-- bugs escape webs in time or if they break
			if self.frames_until_escape>0 and self.caught_web_point then
				if decrement_counter_prop(self,"frames_until_escape") then
					-- fireflies explode, actually
					if species_name=="firefly" then
						create_entity("firefly_explosion",extract_props(self,{"x","y"}))
						foreach(web_points,function(web_point)
							local dist=sqrt(calc_square_dist(self.x,self.y,web_point.x,web_point.y))
							if dist<10 then
								web_point.die(web_point)
							elseif dist<30 then
								local x,y=create_vector(web_point.x-self.x,web_point.y-self.y,(30-dist)/8)
								web_point.vx+=x
								web_point.vy+=y
							end
						end)
						if spider and spider.is_alive then
							if calc_square_dist(self.x,self.y,spider.x,spider.y)<625 then
								spider.vx,spider.vy=create_vector(spider.x-self.x,spider.y-self.y,1.5)
								spider.hitstun_frames=25
							end
						end
						self:die()
					else
						self:escape()
					end
				-- dragonflies shoot projectiles
				elseif self.frames_until_escape%80==0 and species_name=="dragonfly" then
					create_entity("dragonfly_fireball_spawn",{bug=self})
				end
			end
			-- move the bug
			if self.caught_web_point then
				self.x,self.y=self.caught_web_point.x,self.caught_web_point.y
				-- wiggle the web point too
				if self.wiggles and self.frames_until_escape%4==0 then
					self.caught_web_point.vx+=rnd(1)-0.5
					self.caught_web_point.vy+=rnd(1)-0.5
				end
				if not self.caught_web_point.is_alive then
					self:escape()
				end
			else
				self.x+=self.vx
				self.y+=self.vy
			end
			-- bugs can be eaten by the spider
			if spider and spider.is_alive and 49>calc_square_dist(spider.x,spider.y,self.x,self.y) then
				if species_name=="hornet" and self.is_catchable then
					if spider.hitstun_frames<=0 then
						spider.hitstun_frames,spider.vy=25,1.5
						spider.vx*=0.5
					end
				elseif self.is_catchable or self.caught_web_point then
					local props=extract_props(self,{"colors","x","y"})
					props.text="+"..self.points.."0"
					create_entity("floating_points",props)
					score+=self.points
					bugs_eaten+=1
					spider.webbing=min(spider.webbing+1,spider.max_webbing)
					self:die()
				end
			end
		end,
		draw=function(self)
			-- draw tri rings
			if self.species_name=="hornet" and self.is_catchable and not self.caught_web_point then
				local f,i=self.frames_alive/50
				for i=1,5 do
					line(self.x+7*cos(f+i/3),self.y+7*sin(f+i/3),self.x+7*cos(f+(i+1)/3),self.y+7*sin(f+(i+1)/3),8)
				end
			end
			-- draw the actual bug
			local sprite=self.base_sprite
			if self.caught_web_point then
				sprite+=4+flr(self.frames_alive/5)%3
				if self.species_name=="firefly" and self.frames_until_escape<105 and self.frames_until_escape%35>25 then
					colorwash(8)
				end
			else
				if self.frames_alive%6<3 then
					sprite+=1
				end
				if self.is_catchable then
					sprite+=2
				end
				if self.frames_to_death>0 then
					sprite+=2
					colorwash(self.colors[4-flr(self.frames_to_death/4)])
				end
			end
			spr(sprite,self.x-3,self.y-4)
			pal()
			-- draw countdown
			if self.species_name=="firefly" and self.caught_web_point and self.frames_until_escape<=105 then
				print(ceil(self.frames_until_escape/35),self.x,self.y-10,8)
			end
		end,
		escape=function(self)
			if self.caught_web_point then
				-- beetles chew through web
				if self.species_name=="beetle" then
					self.caught_web_point:die()
				end
				self.caught_web_point.caught_bug,self.caught_web_point=nil -- ,nil
			end
			self.render_layer,self.frames_to_death,self.vy,self.is_catchable=8,12,-1.5 -- ,false
		end,
		on_death=function(self)
			if self.caught_web_point then
				self.caught_web_point.caught_bug=nil
			end
		end
	},
	dragonfly_fireball_spawn={
		render_layer=4,
		frames_to_death=30,
		draw=function(self)
			local x,y,f=self.bug.x,self.bug.y,self.frames_alive
			local s,c,r=(10-f/3)*sin(f/100),(10-f/3)*cos(f/100),f/20
			color(8)
			circfill(x+s,y+c,r)
			circfill(x-s,y-c,r)
			circfill(x-c,y+s,r)
			circfill(x+c,y-s,r)
		end,
		on_death=function(self)
			if self.bug.is_alive and self.bug.caught_web_point and spider and spider.is_alive then
				local dx,dy=spider.x-self.bug.x,spider.y-self.bug.y
				local dist=max(1,sqrt(dx*dx+dy*dy))
				create_entity("dragonfly_fireball",{
					x=self.bug.x,
					y=self.bug.y,
					vx=dx/dist,
					vy=dy/dist
				})
			end
		end
	},
	dragonfly_fireball={
		frames_to_death=150,
		render_layer=6,
		update=function(self)
			self.x+=self.vx
			self.y+=self.vy
			if spider and spider.is_alive and spider.hitstun_frames<=0 and 9>calc_square_dist(self.x,self.y,spider.x,spider.y) then
				spider.hitstun_frames,spider.vy=25,-1.5
				spider.vx*=0.5
				self:die()
			end
		end,
		draw=function(self)
			circfill(self.x,self.y,1,8)
		end
	},
	firefly_explosion={
		frames_to_death=18,
		render_layer=2,
		draw=function(self)
			local x,y,f=self.x+rnd(2)-1,self.y+rnd(2)-1,flr(self.frames_alive)
			local r=9+1.8*f-f*f/20
			if f>=12 then
				color(1)
			else
				color(7-flr(f/4))
			end
			if f<16 then
				circfill(x,y,r)
			else
				circ(x,y,r)
			end
		end
	},
	floating_points={
		render_layer=9,
		frames_to_death=20,
		update=function(self)
			self.y-=0.5
		end,
		draw=function(self)
			print(self.text,self.x-2*#self.text,self.y-2,self.colors[max(1,flr(self.frames_alive/2-5))])
		end
	},
	spawn_ring={
		render_layer=1,
		frames_to_death=48,
		draw=function(self)
			circ(self.target.x,self.target.y,15-self.frames_alive/4,1)
		end
	},
	splash={
		frames_to_death=18,
		draw=function(self)
			circ(self.x,self.y,self.frames_alive/3,self.frames_alive>8 and 6 or 7)
		end
	},
	level_intro={
		x=59,
		y=47,
		frames_to_death=139,
		draw=function(self)
			local f=self.frames_alive-40
			if f>2 then
				local colors,j,i={1,5,13,6,7},mid(flr(f/4),1,flr(25-f/4)) -- ,nil
				for i=j,#colors do
					pal(colors[i],colors[j])
				end
				spr(38,44,18+16)
				sspr(48,24,32,8,43,26+16)
				spr(57+level_num,75,25+16)
				pal()
			end
		end,
		on_death=function(self)
			create_entity("spider_respawn",extract_props(self,{"x","y","respawn_x","respawn_y"}))
		end
	},
	moving_platform={
		render_layer=3,
		add_to_game=function(self)
			add(moving_platforms,self)
		end,
		init=function(self)
			self.chains=create_entity("chains",{})
		end,
		update=function(self)
			local f=self.frames_alive%357
			if f<128 then
				self.vy=0.5
			elseif 178<f and f<=306 then
				self.vy=-0.5
			else
				self.vy=0
			end
			self.x+=self.vx
			self.y+=self.vy
			self.chains.x,self.chains.y=self.x,self.y
		end,
		draw=function(self)
			sspr(72,96,40,8,self.x,self.y)
			spr(197,self.x+8,self.y-8)
		end,
		contains_point=function(self,x,y)
			if x>=self.x+8 and x<self.x+16 and y>=self.y-6 and y<self.y then
				return true
			end
			return x>=self.x and y>=self.y and x<self.x+40 and y<self.y+8
		end
	},
	chains={
		render_layer=2,
		draw=function(self)
			local y
			for y=self.y-8,-8,-8 do
				spr(196,self.x,y)
				spr(196,self.x+33,y)
			end
		end
	},
	wind_particle={
		render_layer=1,
		init=function(self)
			self.is_truth=rnd_int(0,1)
		end,
		update=function(self)
			self.vx+=wind_x/20
			self.vy+=wind_y/20
			self.vx,self.vy=self.vx*0.96+0.01*wind_dir,self.vy*0.96
			self.x+=self.vx*self.move_scale
			self.y+=self.vy*self.move_scale
			self.x,self.y=wrap_number(-10,self.x,138),wrap_number(-10,self.y,130)
		end,
		draw=function(self)
			local tail_mult=(self.vx*self.vx+self.vy*self.vy<0.2 and 0 or 1.5)
			line(self.x,self.y,self.x-self.vx*tail_mult,self.y-self.vy*tail_mult,1)
		end
	},
	speech_box={
		x=8,
		y=14,
		characters_per_line=28,
		characters_shown=0,
		frames_fully_shown=0,
		update=function(self)
			self.characters_shown=min(self.characters_shown+1,#self.text)
			if self.characters_shown>=#self.text then
				self.frames_fully_shown=increment_looping_counter(self.frames_fully_shown)
			else
				local c=sub(self.text,self.characters_shown,self.characters_shown)
				if c!=" " and c!="/" then
					sfx(4,3)
				end
			end
		end,
		draw=function(self)
			local c,r=self.characters_per_line -- ,nil
			for r=0,3 do
				local text=sub(self.text,c*r+r+1,min(self.characters_shown,c*r+r+c))
				print(text,self.x,self.y+9*r,7)
			end
		end
	},
	buttons={
		-- frozen=false,
		button_index=1,
		init=function(self)
			self.button_entities={}
			local i
			for i=1,#self.buttons do
				add(self.button_entities,create_entity("button",{
					text=self.buttons[i],
					y=self.y-16+16*i
				}))
			end
			self.button_entities[self.button_index].is_highlighted=true
		end,
		update=function(self)
			-- scroll up and down through the buttons
			if (btnp(2) or btnp(3)) and not self.frozen then
				self.button_entities[self.button_index].is_highlighted=false
				self.button_index=wrap_number(1,self.button_index + (btnp(3) and 1 or 0) - (btnp(2) and 1 or 0),#self.button_entities)
				self.button_entities[self.button_index].is_highlighted=true
			end
		end,
		select=function(self)
			if not self.frozen then
				self.frozen=true
				self.button_entities[self.button_index].blink_frames=2
			end
		end
	},
	button={
		-- is_highlighted=false,
		blink_frames=0,
		update=function(self)
			decrement_counter_prop(self,"blink_frames")
		end,
		draw=function(self)
			if self.blink_frames<=0 then
				color(7)
				local y,d,d2=self.y,0,0
				if self.is_highlighted then
					line(11,y+11,116,y+11,5)
					color(7)
					spr(8,57,y-4)
					spr(8,62,y-4,1,1,true)
					spr(9,57,y+7)
					spr(9,62,y+7,1,1,true)
					d2=7
				else
					colorwash(13)
					d=2
				end
				line(15,y,63-d2,y)
				line(63+d2,y,112,y)
				line(15,y+10,63-d2,y+10)
				line(63+d2,y+10,112,y+10)
				spr(7,7+d,y-1)
				spr(7,7+d,y+4,1,1,false,true)
				spr(7,113-d,y-1,1,1,true)
				spr(7,113-d,y+4,1,1,true,true)
				print(self.text,64-2*#self.text,y+3)
				pal()
			end
		end
	},
	game_event_text={
		render_layer=3,
		x=64,
		y=42,
		frames_to_death=100,
		draw=function(self)
			color(({7,6,5,1})[mid(1,flr(self.frames_alive/4-20),4)])
			local wiggle=self.frames_alive<4 and 2*(self.frames_alive%2)-1 or 0
			print(self.text,self.x+wiggle-2*#self.text,self.y)
		end
	},
	painting1={
		render_layer=3,
		draw=function(self)
			sspr(56,32,16,32,64,0)
		end
	},
	painting2={
		render_layer=3,
		draw=function(self)
			sspr(72,40,24,16,0,56)
		end
	}
}


-- main functions
function _init()
	init_scene("title")
end

-- local frame_skip=0
function _update()
	-- frame_skip=increment_looping_counter(frame_skip)
	-- if frame_skip%4>0 then
	-- 	return
	-- end
	if transition_frames_left>0 then
		transition_frames_left=decrement_counter(transition_frames_left)
		if transition_frames_left==30 then
			init_scene(next_scene)
			next_scene=nil
		end
	end
	scene_frame=increment_looping_counter(scene_frame)
	scenes[scene][2]()
end

function _draw()
	camera()
	rectfill(0,0,127,127,0)
	-- draw guidelines
	-- color(1)
	-- line(0,0,0,127)
	-- line(31,0,31,127)
	-- line(62,0,62,127)
	-- line(65,0,65,127)
	-- line(96,0,96,127)
	-- line(127,0,127,127)
	-- line(0,0,127,0)
	-- line(0,62,127,62)
	-- line(0,31,127,31)
	-- line(0,96,127,96)
	-- line(0,65,127,65)
	-- line(0,127,127,127)
	-- draw the scene
	scenes[scene][3]()
	-- draw the scene transition
	camera()
	if transition_frames_left>0 then
		local t,x,y=transition_frames_left
		if t<30 then
			t+=30
		end
		for y=0,128,6 do
			for x=0,128,6 do
				local size=mid(0,50-t-y/10-x/40,4)
				if transition_frames_left<30 then
					size=4-size
				end
				if size>0 then
					circfill(x,y,size,0)
				end
			end
		end
	end
	-- draw debug stats
	-- camera()
	-- color(15)
	-- print("entities: "..#entities,2,110)
	-- print("memory:   "..flr(stat(0)*(100/1024)).."%",2,116)
	-- print("cpu:      "..flr(100*stat(1)).."%",2,122)
	if debug_text then
		rectfill(0,121,4*#debug_text,128,0)
		print(debug_text,1,122,8)
	end
end


-- title functions
function update_title()
	if btnp(4) and scene_frame>7 then
		init_scene("menu")
	end
end

function draw_title()
	draw_corners()
	sspr(0,0,48,32,40,26)
	line(73,58,73,74,7)
	spr(13,69,75)
	if scene_frame%30<20 then
		print("press z to start",32,100,7)
	end
end


-- menu functions
function init_menu()
	init_simulation()
	menu_buttons=create_entity("buttons",{
		y=46,
		buttons={"play game","how to play","level select","credits + scores"}
	})
end

function update_menu()
	update_simulation()
	if scene_frame>7 and transition_frames_left<=0 then
		if btnp(4) then
			menu_buttons:select()
			local button_index=menu_buttons.button_index
			-- play game
			if button_index==1 then
				level_num,score_cumulative,is_story_mode=1,0,true
				transition_to_scene("game")
			-- how to play
			elseif button_index==2 then
				transition_to_scene("tutorial")
			-- level select
			elseif button_index==3 then
				init_scene("level_select")
			-- credits + scores
			elseif button_index==4 then
				init_scene("credits")
			end
		elseif btnp(5) then
			init_scene("title")
		end
	end
end

function draw_menu()
	draw_corners()
	print("press z to select an option",10,26,7)
	draw_simulation()
end


-- tutorial functions
function init_tutorial()
	-- reset entities, tiles, and variables
	init_simulation()
	-- load the tutorial level
	level=tutorial_level
	load_tiles(level[4],level[3])
end

function update_tutorial()
	-- update all the entities and whatnot
	update_simulation()
	if scene_frame==45 then
		create_entity("spider_respawn",{
			x=64,
			y=30,
			respawn_x=64,
			respawn_y=97,
			instructions={
				70,
				-- move with arrow keys
				" a    ",20,
				"   d  ",40,
				" a    ",20,
				"      ",10,
				-- walk up pillar
				" a    ",35,
				"wa    ",10,
				"w     ",30,
				"   d  ",10,
				"      ",130,
				-- spin web
				"    z+",40,
				"      ",50,
				-- jump to next pillar
				"   d  ",73,
				"w  d  ",10,
				"w     ",30,
				" a    ",8,
				"      ",121,
				-- place end of web
				"     +",10,
				"   d  ",10,
				"      ",220,
				-- eat bug
				" a    ",45,
				"      ",60,
				-- make a web
				"  s z+",25,
				"   d  ",35,
				"wa   +",45,
				" as z+",19,
				"      ",9,
				"w  d +",31,
				"  s   ",1,
				"      "
			}
		})
	elseif scene_frame==105 then
		create_entity("speech_box",{
			text="                            / use the arrow keys to move./",
			frames_to_death=200
		})
	elseif scene_frame==365 then
		create_entity("speech_box",{
			text="     hold z to spin web.    /    the longer it's held,   /    the longer the strand.  ",
			frames_to_death=250
		})
	elseif scene_frame==715 then
		create_entity("speech_box",{
			text="       tap z again to       /    place the other end     /        of the web.         ",
			frames_to_death=170
		})
	elseif scene_frame==915 then
		create_entity("speech_box",{
			text="     catch bugs in your     /     web, then eat them     /      to gain points.       ",
			frames_to_death=200
		})
	elseif scene_frame==965 then
		create_entity("bug_spawn_flash",{
			frames_to_death=15,
			species=1, -- fly
			x=64,
			y=56
		})
	elseif scene_frame==1165 then
		create_entity("speech_box",{
			text="      build a nice web,     /    eat some tasty bugs,    /        and have fun!       "
		})
	elseif scene_frame==1415 then
		transition_to_scene("title")
	end
end

function draw_tutorial()
	draw_corners()
	camera(0,-8)
	-- draw the entities and tiles
	draw_simulation()
	-- local s="use the arrow keys to move"
	-- local s="hold z to spin a strand of web. the longer you hold, the longer the strand"
	-- color(7)
	-- print(s,64-2*#s,10)
end


-- level select functions
function init_level_select()
	init_simulation()
	menu_buttons=create_entity("buttons",{
		y=24,
		buttons={"garden","house","bridge","construction","skyscrapers","space"}
	})
end

function update_level_select()
	update_simulation()
	if scene_frame>7 and transition_frames_left<=0 then
		if btnp(4) then
			menu_buttons:select()
			level_num,score_cumulative,is_story_mode=menu_buttons.button_index,0 -- ,false
			transition_to_scene("game")
		elseif btnp(5) then
			init_scene("menu")
		end
	end
end

function draw_level_select()
	draw_corners()
	draw_simulation()
	local i
	for i=1,6 do
		spr(21+i,100,9+16*i)
	end
	print("select a level",36,10,7)
end


-- game functions
function init_game()
	local i
	-- reset entities, tiles, and variables
	init_simulation()
	level,timer,frames_until_spawn_bug,spawns_until_pause=levels[level_num],141,0,3
	-- load the level
	load_tiles(level[4],level[3])
	-- create entities
	create_entity("level_intro",{respawn_x=level[1],respawn_y=level[2]})
	-- spider=create_entity("spider",{x=level[1],y=level[2],respawn_x=level[1],respawn_y=level[2]})
	if level[5]=="platforms" then
		create_entity("moving_platform",{x=52,y=32})
	elseif level[5]=="wind" then
		wind_frames,wind_dir,wind_x,wind_y=300,1,0,0
		for i=1,50 do
			create_entity("wind_particle",{
				x=rnd_int(0,128),
				y=rnd_int(0,120),
				move_scale=0.25+rnd(0.75)
			})
		end
	elseif level[5]=="paintings" then
		create_entity("painting1",{})
		create_entity("painting2",{})
	end
end

function update_game()
	-- count down the timer
	if scene_frame%30==0 then
		if timer<=0 then
			transition_to_scene("scoring")
		elseif timer==131 then
			create_entity("game_event_text",{text="build a web!"})
		elseif timer==101 then
			create_entity("game_event_text",{text="10 seconds!"})	
		elseif timer==92 then
			create_entity("game_event_text",{text="catch bugs!"})	
		end
		timer=decrement_counter(timer)
	end
	-- spawn bugs from 1:30 to 0:04
	if timer==mid(4,timer,90) then
		local phase=min(flr(4-timer/30),3)
		-- spawn a new bug every so often
		frames_until_spawn_bug=decrement_counter(frames_until_spawn_bug)
		if frames_until_spawn_bug<=0 then
			local max_bug_type,dir_x,dir_y,num_bugs,r,bug_type,i=flr(0.5+(level_num+phase)/1.5),rnd_int(-1,1),rnd_int(-1,1),rnd_int(1,3),rnd(1),1
			if dir_x==0 and dir_y==0 then
				dir_x=1
			end
			local spawn_point=level_spawn_points[num_bugs][rnd_int(1,#level_spawn_points[num_bugs])]
			for i=5,2,-1 do
				if r<i/10 and max_bug_type>=i then
					bug_type=i
				end
			end
			if bug_type>=max_bug_type then
				num_bugs=1 -- fine that this is after num_bugs is first used
			end
			for i=1,num_bugs do
				create_entity("bug_spawn_flash",{
					frames_to_death=15*i,
					species=bug_type,
					x=8*(spawn_point[1]+i*dir_x-dir_x)-5,
					y=8*(spawn_point[2]+i*dir_y-dir_y)-10
				})
			end
			-- phase 1: 1.0s to 2.5s between spawns
			-- phase 2: 0.5s to 2.0s between spawns
			-- phase 3: 0.5s to 1.0s between spawns
			frames_until_spawn_bug=15*flr(num_bugs+max(1,3-phase)+rnd(min(8-2*phase,4)))
			-- after every couple of spawns, there is a pause
			spawns_until_pause=decrement_counter(spawns_until_pause)
			if spawns_until_pause<=0 then
				spawns_until_pause=rnd_int(3,3+2*phase)
				frames_until_spawn_bug+=120
			end
		end
	end
	-- update the wind
	if level[5]=="wind" then
		wind_frames=decrement_counter(wind_frames)
		if wind_frames<=0 then
			if wind_x==0 and wind_y==0 then
				wind_dir,wind_frames,wind_x,wind_y=-1*wind_dir,rnd_int(175,300),wind_dir*rnd_int(2,4),rnd_int(-2,1)/2
			else
				wind_frames,wind_x,wind_y=rnd_int(125,250),0,0
			end
		end
	end
	-- update all the entities and whatnot
	update_simulation()
end

function draw_game()
	camera(0,-8)
	-- draw the entities and tiles
	draw_simulation()
	-- draw ui
	camera()
	rectfill(0,0,127,7,0)
	-- draw webbing meter
	color(spider and spider.is_spinning_web and 7 or 5)
	rectfill(35,2,35+50*(spider and spider.webbing/spider.max_webbing or 1),5)
	rect(35,1,85,6)
	spr(10,87,0)
	-- draw timer
	if timer<=5 and scene_frame%30<=20 then
		color(8)
	else
		color(7)
	end
	local t=min(timer,135)
	print(flr(t/60)..":"..(t%60<10 and "0" or "")..t%60,112,2)
	-- draw score
	print(score_cumulative+score<=0 and "0" or (score_cumulative+score).."0",1,2,7)
end


-- scoring functions
function init_scoring()
	score_cumulative+=score
	-- save level high score
	if dget(level_num)<=score then
		dset(level_num,score)
	end
	-- save story mode high score
	if is_story_mode and dget(0)<=score_cumulative then
		dset(0,score_cumulative)
	end
end

function update_scoring()
	local final_frame=74+bugs_eaten+score
	if scene_frame>15 and btnp(4) then
		if scene_frame<final_frame then
			scene_frame=final_frame
		elseif transition_frames_left<=0 then
			if is_story_mode and level_num<#levels then
				level_num+=1
				transition_to_scene("game")
			else
				transition_to_scene("title")
			end
		end
	end
end

function draw_scoring()
	draw_corners()
	color(7)
	print("level complete!",35,24)
	line(35,30,92,30)
	local f,score_text=scene_frame-40
	-- draw number of bugs eaten
	local b=mid(0,f,bugs_eaten)
	if f>0 then
		print("bugs eaten",17,45)
		print(b,107-4*#(""..b),45)
	end
	-- draw score
	if f>bugs_eaten+20 then
		print("score",17,59)
		local s=mid(0,f-bugs_eaten-20,score)
		score_text=s==0 and "0" or s.."0"
		print(score_text,107-4*#score_text,59)
	end
	-- draw cumulative score
	if f>bugs_eaten+score+40 then
		print("total score",17,73)
		score_text=score_cumulative==0 and "0" or score_cumulative.."0"
		print(score_text,107-4*#score_text,73)
	end
	-- draw continue text
	if f>bugs_eaten+score+60 then
		if (f-bugs_eaten-score-60)%30<20 then
			if dget(level_num)<=score then
				print("best!",108,57,13)
			end
			if is_story_mode and dget(0)<=score_cumulative then
				print("best!",108,71,13)
			end
			print("press z to continue",26,93,13)
		end
	end
end


-- credits functions
function update_credits()
	if scene_frame>7 and (btnp(4) or btnp(5)) then
		init_scene("menu")
	end
end

function draw_credits()
	draw_corners()
	color(7)
	print("created by bridgs",30,13)
	print("your high scores",32,44)
	print("press z to return",30,110)
	color(13)
	print("http://brid.gs",36,20)
	print("@bridgs_dev",42,27)
	local i
	for i=1,7 do
		local s=dget(i==7 and 0 or i)
		score_text=s==0 and "0" or s.."0"
		print(i==7 and "playthrough" or levels[i][3],17,44+7*i)
		print(score_text,107-4*#score_text,44+7*i)
	end
end


-- simulation functions
function init_simulation()
	local i
	-- reset some vars
	score,bugs_eaten=0,0
	-- reset entities
	entities,new_entities,web_points,web_strands,moving_platforms,spider={},{},{},{},{} -- ,nil`
	-- reset tiles
	reset_tiles()
end

function update_simulation()
	-- update entities
	foreach(entities,function(entity)
		-- call the entity's update function
		entity:update()
		-- do some default update stuff
		entity.frames_alive=increment_looping_counter(entity.frames_alive)
		if entity.frames_to_death>0 and decrement_counter_prop(entity,"frames_to_death") then
			entity:die()
		end
	end)
	-- add new entities to the game
	add_new_entities_to_game()
	-- remove dead entities from the game
	filter_entity_list(entities)
	filter_entity_list(web_strands)
	filter_entity_list(web_points)
	filter_entity_list(moving_platforms)
	-- sort entities for rendering
	sort_list(entities,function(a,b)
		return a.render_layer>b.render_layer
	end)
end

function draw_simulation()
	-- render layers:
	--  1=bg effects
	--  2=background
	--  tiles
	--  3=moving platforms
	--  4=web
	--  5=midground
	--  6=projectiles
	--  7=spider
	--  8=foreground
	--  9=ui effects
	local i,j
	-- draw background entities
	for i=1,#entities do
		if entities[i].render_layer>2 then
			j=i
			break
		end
		entities[i]:draw()
	end
	-- draw the level
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
			-- 				rectfill(x+2*x2,y+2*y2,x+2*x2+1,y+2*y2+1,8)
			-- 			end
			-- 		end
			-- 	end
			-- end
		end
	end)
	-- draw foreground entities
	if j then
		for i=j,#entities do
			entities[i].draw(entities[i])
		end
	end
end


-- entity functions
function create_entity(class_name,args)
	-- create default entity
	local entity,k,v={
		class_name=class_name,
		render_layer=5,
		x=0,
		y=0,
		vx=0,
		vy=0,
		is_alive=true,
		frames_alive=0,
		frames_to_death=0,
		add_to_game=noop,
		init=noop,
		update=noop,
		draw=noop,
		on_death=noop,
		die=function(self)
			self:on_death()
			self.is_alive=false
		end
	} -- ,nil,nil
	-- add class properties/methods onto it
	for k,v in pairs(entity_classes[class_name]) do
		entity[k]=v
	end
	-- add properties onto it from the arguments
	for k,v in pairs(args) do
		entity[k]=v
	end
	-- initialize it
	entity:init(args)
	-- return it
	add(new_entities,entity)
	return entity
end

function add_new_entities_to_game()
	foreach(new_entities,function(entity)
		entity:add_to_game()
		add(entities,entity)
	end)
	new_entities={}
end


-- tile functions
function reset_tiles()
	local i
	tiles,level_spawn_points={},{{},{},{}}
	for i=1,240 do
		tiles[i]=false
	end
end

function load_tiles(map,tileset_name)
	local i,c,r
	-- loop through the 2d array of symbols
	for c=1,16 do
		for r=1,15 do
			local tile_coords,s,tile_index,i={c,r},r*16+c-16
			local symbol=sub(map,s,s)
			-- find the tile index of the symbol
			for i=1,#tile_symbols do
				if symbol==sub(tile_symbols,i,i) then
					tile_index=i
					break
				end
			end
			-- create the tile if the symbol exists
			if tile_index then
				tiles[c*15+r-15]=create_tile(tilesets[tileset_name],tile_index,c,r)
			-- otherwise we may need to log it as a spawn point
			elseif symbol=="." then
				add(level_spawn_points[1],tile_coords)
			elseif symbol=="+" then
				add(level_spawn_points[1],tile_coords)
				add(level_spawn_points[2],tile_coords)
			elseif symbol=="*" then
				add(level_spawn_points[1],tile_coords)
				add(level_spawn_points[2],tile_coords)
				add(level_spawn_points[3],tile_coords)
			end
		end
	end
end

function create_tile(tileset,tile_index,col,row)
	local is_flipped,half_tile_index,solid_bits,i=(tile_index%2==0),ceil(tile_index/2),{255,255} -- ,nil
	if #tileset[2]>=2*half_tile_index then
		solid_bits={tileset[2][2*half_tile_index-1],tileset[2][2*half_tile_index]}
	end
	if is_flipped then
		for i=1,2 do
			local new_bits,j=0
			for j=1,#tile_flip_matrix do
				if band(solid_bits[i],2^(j-1))>0 then
					new_bits+=tile_flip_matrix[j]
				end
			end
			solid_bits[i]=new_bits
		end
	end
	return {
		sprite=tileset[1]+half_tile_index-1,
		col=col,
		row=row,
		is_flipped=is_flipped,
		solid_bits=solid_bits
	}
end

function get_tile_at(x,y)
	if 0<=y and y<=116 then
		return tiles[1+flr(x/8)*15+flr(y/8)]
	end
end

function get_moving_platform_at(x,y)
	local i
	for i=1,#moving_platforms do
		if moving_platforms[i].contains_point(moving_platforms[i],x,y) then
			return moving_platforms[i]
		end
	end
end

function is_solid_tile_at(x,y)
	-- turn the position into a bit 1 to 16
	local tile,bit,i=get_tile_at(x,y),1+flr(x/2)%4+4*(flr(y/2)%4) -- ,nil
	if tile then
		-- check that against the tile's solid_bits
		if bit>8 then
			return band(2^(bit-9),tile.solid_bits[2])>0
		end
		return band(2^(bit-1),tile.solid_bits[1])>0
	end
	return false
end


-- math functions
function apply_gravity(entity,grav,space_grav,wind_mag)
	-- some levels have space gravity
	if level[5]=="space" then
		local square_dist,x,y=calc_square_dist(entity.x,entity.y,63,55),create_vector(63-entity.x,55-entity.y,space_grav)
		if square_dist>576 then
			entity.vx+=x
			entity.vy+=y
		end
	-- others are pretty simple
	else
		entity.vy+=grav
	end
	-- apply wind
	if level[5]=="wind" then
		entity.vx+=wind_mag*wind_x
		entity.vy+=wind_mag*wind_y
	end
end

function rnd_int(min_val,max_val)
	return flr(min_val+rnd(1+max_val-min_val))
end

function ceil(n)
	return -flr(-n)
end

function wrap_number(min,n,max)
	return n<min and max or (n>max and min or n)
end

function create_vector(x,y,magnitude)
	local length=sqrt(x*x+y*y)
	if length==0 then
		return 0,0
	else
		return x*magnitude/length,y*magnitude/length
	end
end

function calc_square_dist(x1,y1,x2,y2)
	local dx,dy=x2-x1,y2-y1
	return dx*dx+dy*dy
end

function calc_closest_point_on_line(x1,y1,x2,y2,cx,cy)
	local dx,dy,match_x,match_y=x2-x1,y2-y1 -- ,nil,nil
	-- if the line is nearly vertical, it's easy
	if 0.1>dx and dx>-0.1 then
		match_x,match_y=x1,cy
	-- if the line is nearly horizontal, it's also easy
	elseif 0.1>dy and dy>-0.1 then
		match_x,match_y=cx,y1
	--otherwise we have a bit of math to do...
	else
		-- find equation of the line y=mx+b
		-- find reverse equation from circle
		local m,m2=dy/dx,-dx/dy
		local b,b2=y1-m*x1,cy-m2*cx -- b=y-mx
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
	local closest_square_dist,closest_web_point=9999 -- ,nil
	foreach(web_points,function(web_point)
		if not web_point.is_being_spun and
			(allow_occupied or not web_point.caught_bug) and
			(allow_unanchored or web_point.has_been_anchored) then
			local square_dist=calc_square_dist(x,y,web_point.x,web_point.y)
			if square_dist>=0 and (not closest_web_point or square_dist<closest_square_dist) then
				closest_web_point,closest_square_dist=web_point,square_dist
			end
		end
	end)
	return closest_web_point,closest_square_dist
end

function calc_closest_spot_on_web(x,y,allow_unanchored)
	local closest_x,closest_y
	local closest_web_point,closest_square_dist=calc_closest_web_point(x,y,allow_unanchored,true)
	if closest_web_point then
		closest_x,closest_y=closest_web_point.x,closest_web_point.y
	end
	foreach(web_strands,function(web_strand)
		local from_obj,to_obj=web_strand.from,web_strand.to
		if not from_obj.is_being_spun and not to_obj.is_being_spun and
			(allow_unanchored or (from_obj.has_been_anchored and to_obj.has_been_anchored)) then
			local x2,y2=calc_closest_point_on_line(from_obj.x,from_obj.y,to_obj.x,to_obj.y,x,y)
			if x2!=nil and y2!=nil then
				local square_dist=calc_square_dist(x,y,x2,y2)
				if square_dist>=0 and (not closest_square_dist or square_dist<closest_square_dist) then
					closest_x,closest_y,closest_square_dist=x2,y2,square_dist
				end
			end
		end
	end)
	return closest_x,closest_y,closest_square_dist
end


-- helper functions
function noop() end

function draw_corners()
	-- draw corners
	spr(6,1,1)
	spr(6,119,1,1,1,true)
	spr(6,1,119,1,1,false,true)
	spr(6,119,119,1,1,true,true)
end

function char_at(s,n)
	return sub(s,n,n)
end

function init_scene(s)
	scene,scene_frame=s,0
	scenes[scene][1]()
end

function debug_print(s)
	debug_text="> " .. s
end

function transition_to_scene(s)
	next_scene=s
	if transition_frames_left<=0 then
		transition_frames_left=60
	end
end

function increment_looping_counter(n)
	if n>32000 then
		n-=10000
	end
	return n+1
end

function decrement_counter_prop(obj,k)
	local just_reached_zero=0<obj[k] and obj[k]<=1
	obj[k]=decrement_counter(obj[k])
	return just_reached_zero
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

function sort_list(list,func)
	local i
	for i=1,#list do
		local j=i
		while j>1 and func(list[j-1],list[j]) do
			list[j],list[j-1]=list[j-1],list[j]
			j-=1
		end
	end
end

function filter_entity_list(list)
	local num_deleted,i=0
	for i=1,#list do
		if list[i].is_alive then
			list[i-num_deleted],list[i]=list[i],nil
		else
			list[i]=nil
			num_deleted+=1
		end
	end
end

function extract_props(obj,props_names)
	local props,i={}
	foreach(props_names,function(p)
		props[p]=obj[p]
	end)
	return props
end


-- set up the scenes now that the functions are defined
scenes={
	title={noop,update_title,draw_title},
	menu={init_menu,update_menu,draw_menu},
	tutorial={init_tutorial,update_tutorial,draw_tutorial},
	level_select={init_level_select,update_level_select,draw_level_select},
	game={init_game,update_game,draw_game},
	scoring={init_scoring,update_scoring,draw_scoring},
	credits={noop,update_credits,draw_credits}
}


__gfx__
000000000000000000000070000000000000000000000000dd0ddddd077700700000000000000000000000000000000000000000000070000000700000007000
000000777700000000000707000000000000000000000000d0d000d0070077770000007000000000775005500800080008000800000777000007770000077700
000077700d770000000007070000000000000000000000000ddddd00070070700000770000000000777700500080800000808000070777070007770707077700
000776000007700005000707000000000000000000000000d0d00000007777007007070077707700777777000008000000080000007777700777777000777777
007770000000700050507707000000000000000000000000d0d00000007070000770007000070700007777770080800000808000000777000007770000077700
007650000000d700d0007760000000000000000000000000d0d00000077700000000000000000070050077770800080008000800007171700771717000717177
00670000000007000ddd770000007770007700777dd00000dd000000707000000000000000000000055005770000000000000000070707070007070707070700
0077d00000000700000077000007007007070700000d0000d0000000077700000000000000000000000000000000000000000000000000000000000000000000
0077700000000700076070007007770070070077000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007770000007000700770060707000d7007000070d000000b0000bb00066000a9900aa9060505060000aaa00000606008000800077707000777007007770700
000777700005700007770677700077700777077700d000000b330b3300066ee0040000408885058800000a000c00000600808000077777000777770707777700
0000777775d6000000005500000000000007d000000ddd0099900bb3000660be66666666222a0522200009900003630000080000077777770777777007777777
00000777777000000050000000070000007700000ddd0d00994000b06600003366d00d660608880620000990070c310000808000007771700077717000777170
0000dd777777600000055ddd000700000707ddddd000d00094400e82660000ffad0000da06000006220009cc00066c0008000800077717070777170700771707
000666d777767700000000007dd77dddd7d700000000000099400882000600ffa9cccc9a88800088266009cc6600000000000000000770000007700007077000
00777500777767700000000707070077077000005000000044444444004444449cccccc92220002226d0cccc6d0000c000000000000707000007070000700700
07770000077776770000000707070570700000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d7700000007776676005000707007007dddddd000000000000000000000000000007000000000700000000000000000008000800007000700007070000700070
77700077660777667050507707000000000000000000000000000000070000000007000070077000000000000000000000808000000707000007070000070700
77000700006d776676d0007760000000000000000000000000000000007700000077000007777000000707700007000000080000077771700777717007777170
7700700000076777770ddd7700000077007007d07770000000000070007770000777770000777000007770000777770000808000777777007777770077777700
77007000770077766700007700000700707007070070000000000707000770000007700000777700770700000007000008000800077771700777717007777170
777070007700777667076070007007007070700777000ddd00000707000007000007000000770070000000000000000000000000000707000007070000070700
777007000600077676700770060707007d7070070000d00d05000707000000000007000007000000000000000000000000000000007000700070007000070700
07770077700007777007770677700077d0070000777dddd050507707000000000000000000070000000070000077770000077700000007700077777000077700
077700000000777760000dddd000000000dd0000000d0000d0007760000000000000000000707000000670000770677000700770000707700070000000760070
007770000000777700000d000500000006005000ddd000000ddd7700000077707007d07770707000007770000700067000600760007707700077700007700000
0007776000067770000000ddd0500000060005dd0000000000007700000700707007070070707000000770000000076000007700007607700000670007707700
0000777777777d00000000000dddddddd6dddd000000000007607000700777007070077700707000000770000000770000000770007007700060077007760070
000000777760000000000000000055000700050000000000700770060707000d707007000007700d000770000007700000700770007777700770077007700670
0000000000000000000000000000005557555000000000000777067770007770070000777d760dd0000770000077006000777760000006700777777000777770
0000000000000000000000000000000007000000000000000000550000000000dd00000000000000000770000777777000077700000007700077760000077700
00000000000000000000000000000000000000000000000000000000777efffff77fffff00000000000000000033000000330000000000000000000000000000
0000000000000000000000000000000000000000000000000000000077e4eff77fffff770033000000330000003b0000003b0000005bbd000000000005350000
000000000000000007707700000000000d0dd00000ddd00000dd0000fe4ffe7fffff7777703b0700003b000070330070003300000035bb0000bbdb00db500000
007007000000000006ccc60007ccc70000cdc00000cdc00000dcc000f4e7e4e4ffe7777f073b7000003b0000673b0760003b0000050b3dd00b33dbd00bb50000
000cc000007cc70000dcd00006dcd6000cccc0000cccc0000dccdd00e47ffe4f7e4e7fff00bb000007bb700006bbb60007bbb70000533b000335bbd00d303300
000cc000000cc00000ccc00000ccc00000cdcd0000cdc00000cccd00744fffe4747fff770033000070330700035b5000765b56700333300003305b000db33300
00000000000000000d0c0d000d0c0d0000d0dd000d0dd0000c00d0004f4e77744efe77ff0000000000000000003330006033306003bb30000005350000b3b000
00000000000000000000000000000000000000000000000000000000e44777e4efe4feff00000000000000000500050005000500000000000000000000000000
000000000000000000000000000000000000000008708000080087707e4e7f4477f4e4ef66615551155511111111155500000000000000000000000000000000
000000000000000000000000000000000000000087000800800008077742ff47fffe4eff566155ccc1c55516155515dd08000800080008000800080008000800
078287000082800077828770008280000022000078088000080880007ff4e42fef44efff561155c1cc1c551115551d5500808000008080000080800000808000
06828600078287006682866077828770082880007888200008882000ff7e42ff44efffff511655c1111155111555d55500080000000800000008000000080000
008880000688860008282800662826608282880078ee880008ee880077ff42e4ffffffff5111ccc1111155555555155500808000008080000080800000808000
000000000000000050e8e05050e8e0508888880007eeee0000eeee00ffff4442ffffffff5111551ccc111566555d555508000800080008000800080008000800
00000000000000000080800000808000827282000202020002020200ffeff44fffffffff5555c5111115565565555d5500000000000000000000000000000000
00000000000000000000000000000000087800000000000000000000fe4eff4efffeffff5555cc111115595556555d5500000000000000000000000000000000
00000000000000000000000000000000000000020022000000000000ffe44e44fff44eff5555c1cc111185555556d55500000000000000000000000000000000
000000000000000000000000000000000000dd02000444000000dd02ffffe444ef4fefff555c1111115155555555555508000800080008000800080008000800
00000000000000000099900000999000009942400092442200999d02ffffff4444efffff555c1111155115555555555500808000008080000080800000808000
70aa070000aa000022aaa22022aaa22009aa444009a4420009aaa424fffff444ef2effff555c1111115115555555555500080000000800000008000000080000
0a44a0000a44a0007a444a700a444a0009aa424009aaa9d009aaa444fffff442ffefffff55cc111111511555555555dd00808000008080000080800000808000
0944900079449700092429006924296009aaa90209aaa9d009aaa424fffff44fffffffff55c1111111111555555ddd5508000800080008000800080008000800
0000000000000000004440007044407000999d020099900000999d02ffff442ffffffeff55c1111111111555ddd5555d00000000000000000000000000000000
0000000000000000040004000400040000000000000000000000dd02fff4f42fffffffff55c11111111155dd5555dddd00000000000000000000000000000000
00000000000000000500050005000500000000000000000000000000fff4f42fffffffff00000000000000000000000000000000000000000000000000000033
005050000050500070aaa07000aaa00000d5a0000dda5a0000500d00ff4f422fffffefff0800080008000800080008000800080008000800000000000000003b
075a5700005a5000675a5760005a5000005aaa005dda5aa05aa50550f4242424ffffffff0080800000808000008080000080800000808000000000000000f533
069a9600079a9700069a9600079a9700000555000a5955a005a95aa044244242ffffffff000800000008000000080000000800000008000000000000000ffff3
0055500006555600005550007655567009a9add00aaa0d5009aa5aa04244222294999999008080000080800000808000008080000080800006666666000fffff
00a7a00000a7a00000a9a00060a9a06005a5add00a5900000da5aa00444242224f4999e9080008000800080008000800080008000800080000566666000fffff
000600000006000000575000005750000aaa0000500000000dd000004444222f94f4f9f900000000000000000000000000000000000000000005566600005fff
0000000000000000000600000006000050005000000000000000000044224229499f9999000000000000000000000000000000000000000000005555000005ff
00000555000005ff5fffffff0000003b0000eeeeeeee000005ffffff00eeeee000b3033000b30b30ffffffffffffffff44444444444444444444444477777777
0000005f00005fff55ffffff0000003b0000e222eeeeee005fffffffee2eeeee00b3033000b30b30ffffffffffffffff44444444444444444444444477777777
0000005f00005fff05ffffff0000003b000e99922eeeee005fffffffeee2222e00b3033055b35b35ffffffffffffffff44444422222222222222222277777777
0000005f00022eee055fffff0000003b0099e224222eee0022eeeeeeee22222200b3033055b35335eeeeeeeeffffffff44444429999999999999999977777777
0000005f0022eeee0055ffff0000003b0a002222eee2e20022eeeeeeee22492200b30b3055335335eeeeeeeeffffffff44444429444444444444444466666666
0000005f0022222200055fff0000003b00000eeeeeee22b022222222ee22229e00330330ffffffff22222222ffffffff44444429444444444444444466666666
000005ff02222222000055ff0000003b0000eeee0000333b2222222202ee222900b30b30ffffffff22222222ffffffff4444442944444444444aa94455555555
000005ff05ffffff000000550000003b000000000000003b5fffffff0322ee2a00330b30ffffffffffffffffffffffff444444294444444444aa999455555555
5555555577776655555555557777665500000000006600000000a000aa666600000a0a0a0000000000000000000a0a0a00090944000104442222000044444444
5555555577776655555555557777665500000000066660000000a000a0666600000a009a0000000000000000000a009a00090022000104942222000022224222
666666667777665566666555777766550000000066666d000060a606aaaaaaaaaaaaaaaaaaaaaaaaaaaaa000000a000900040009000104942222000000004000
6666666677776655666656557777665500000000666d6d0000dddddda0adda000a000a000a000a000a000a00000aa00a00099409000114442222000000004000
77777777777766557777665566665655000000046d6d6d0000009900a0addaa090a090a090a090a090a090a0000a0a0a00040444000104442222000044444444
7777777777776655777766556666655500000002dddddd0000009900a0adda0a000a000a000a000a000a000a000a009a00040422000104942222000022224222
7777777777776655777766555555555500004000d0000d000000aaa099999999999999999999999999999999000a000900010401000104942222000000004000
7777777777776655777766555555555500004000d0000d00000aa00a00dddd00000990090000000000000000000aa00a00041401000114442222000000004000
6d66d66d66d5dd506d66d66d66d55550ccccccccccc555556c66c66c66c5555522222222444444444c4444444444444400000000000222220000449900004499
56556556556d55d06d66d66d66d5555055555555555555556c66c66c66c55555e2e2e2e2949494949c9494949494949400000000002224240000449900004944
ddddddddddd55550ddddddddddd55550ccccccccccc55555ccccccccccc55555e2e2e2e2949494949c9494949494949422222222222242420000494400004499
6d66d66d66d555506d66d66d66d555506c66c66c66c555556c66c66c66c555552222222244444444ccc444444444444444444244424244440000449900004449
6d66d66d66d555506d66d66d66d555506c66c66c66c555556c66c66c66c5555522222222444444444c4444444444767444444444244424240000449900440494
6d66d66d66d555506d66d66d66d555506c66c66c66c555556c66c66c66c55555e2e2e2e2949494949c9494949494676442444444442244420000444904000049
ddddddddddd55550ddddddddddd55550ccccccccccc55555ccccccccccc55555e2e2e2e2949494949c9494949494ddd444444424444444240000494400000044
6d66d66d66d555506d66d66d66d555506c66c66c66c555556c66c66c66c5555522222222444444444c4444444444d4d444444444444444440000449900000004
0004000400000449000033bb3bb3bbbb0000000333b333bb333b33b30000000000000002000022884444444422222222999999999999999933b3bb3333bbb3bb
0000404900004444000033b33bbbbbbb0000033b3bbbbbbbbbbbbb300000000200000022000022284442444422222222999999999999999933b33b3b333bb33b
000404490044449900003bb33b3bbb3b000333bbbbbbbbbbb33b3500000002220000002800002282444444444242424299999999999944993bb3bb333b3bbb33
000004440444949900003bbb5b3b3b3b0003bb3bbbbb33b33b335000000022280000022200002228424442442444242499999999994999993bb33b3b3b3bbbb3
000044994449994900003bbb53bb33bb0033b3bbbbb3bb33355000000002228200000228000022284444244444444244999999999994444933b33b3b3333bbb3
0000444944449999000053b3533bb3bb033b33bb3b33335550000000002288280000228200002288444244422424424499999999999999993bb33b333b33bbb3
0000094449944499000053bb0533333b3333bbbb33335000000000000228288800002282000022822422242442442424999999999999999933b3bb3333b33b3b
00004499449999990000053b0053b3333b3bbbbb35500000000000002282888800002228000022282222222244444444999999999999999933b33b3b33bbb33b
02222222888888882288eee80000000000505000000000000000000000dddd00007766008888888888888888888888888888888888888888760d0006d000706d
2222222288888888888eeeee000000000005000000000000000000000076dd0007d66dd0022225522222222522555222222222222222252076006006d006006d
228288828888888882eeeeee0011110000050000000000000005550000066dd0076766d00222ee22222222e22eee2222222222222222e22076000706d0d0006d
282882288888888888eeeee8001111000050500000aaaa0000500050000006d007d76dd00220022222200e22eee00222222002222220022076000066dd00006d
88888882888888888eeeee8811111100005050000aaaaaa008688868007006d006d76dd002e002222220022eee2002222220022222e0022076000706d0d0006d
82888888888888888eee888811111100000500000aaaaaa008886888006776d00aaaa9900ee22222222e22eee2222222222222222e22222076006006d006006d
88888888888888888888888811111111000500000aa999a00288d88200066d000aaaa9900e22222222e22eee2222222222222222e2222220760d0006d000706d
888888888888888888888888111111110050500099a9a9a90222222200000000066666d0888888888888888888888888888888888888888876d00006d000066d
76aaaaaa100000000000000000000000000000000000000c00cc111100c61613000cc111c6161116166166111111111100000000000000006d66d6d00000dc00
76a5555a00000100000000000006777700000000000000cc00cc1111006c73b3000cc1110c61616667166166111167110000006666000000d6dd6dd00600cd00
76aaaaaa000000000000c000666767760000000000000cc600cc111100c61b37000cc11100666716666166666116167100006666676600006d6ddd006d60dc00
76a55a5a00000000000c0c0076767667000007760000cc6100c61116006633730000cc1100076676676666767611676100066d6676776000d6dddd006d6d666d
76aaaaaa000000000000c00066666166000676670000c616006c617100c631160000cc110000077666767667676677160066d6666dd67600ddddd000dd6d66dd
76aaa55a00010000000000007667161600676176000cc16100c617160063111300000cc1000000007777677677777677006d6d66d66d6600dddd00006d60cd00
76aaaaaa0000001000100000637661110c6116160006c111006c111100cc1161000000cc0000000000067777777670000666d666d76d6760dd0000000600dc00
76d0000d000010000000000036661111cc111166000cc11100cc111100cc16110000000c000000000000000000000000066d66666dd66660000000000000cd00
007677000000000000000000c00ccc001111113316766716b3333111111111113661111166666666dd66666666666666d6d000006d66d5556d666d666d555555
7776777700006660000d660050c666c0166176366767617133111111636111113361611166666666ddd666666d66dd66d6d000006d55d6d06d6666655dd6d500
6c7677760006d660006666600c66ff6c11173677776166161111111166371611333616116666666666dd6666d6dd66d6d50000005d66d6d05d55555d665d0000
06777760000d66d0066666d0c566fffc111363677611176171111111676671613633676666666666666d66666ddd66d66d0000006d66d5006666d66ddd000000
0077770000000dd00d6d66000c6f6f6c111633366116171616111111336766163363167766666666666d6666dddddd6d6d0000005d5550006555ddd500000000
00755700066000000dd6dd0005c6f66c1133b3631616766111111111633677613336116666666666666d6666ddddd6d6d0000000d6d500006d66550000000000
005775000dd0000000ddd000505cc6c0113b3b36611166111111111137311676111111116666666666d66666dddd6d6d50000000d6d5000055dd000000000000
000550000000000000000000050ccc001333b3113611111111111111637611111111111166666666dd66666dddddddddd00000005d5000005500000000000000
004400400000999a999a9aa900000000ccccccccccccccccd999af9a9a9a99aa494f49446d6666666d60d6666666666666666666ff9f9dd9f56666669f9a9a9a
004444000999a9aa9aa9aaaa00000000ccccccccccccccccdd99faa9aaa9aaaa44ff49446d6d6666ddd6dddddddddddddddddddd9aa9dd9d9566d66699a9a9af
04444000099a9aaa99aaaaaa00000000cccccccccccccccccdd999afaaaaaaaa444f44945d555555555555555555555555555555aafa9f55559555559f9a9af9
4f9400000999aa9a9aa9aaaa00000000ccccccccccccccccdddd99f9aaaaa9a944f4f49466666d66dd55d5dddd5dd5ddd5dddddd9f9af99d99666d6df99f9aaa
99400000099999a9999a9aaa00000000ccccccccccccccccccddd99faa9a9a9944f4f44466d66d66d5d5d5d5ddddd5ddd5555d5da9afa9f9f9dd6d669af9a9fa
94000000000999999999a9a94f4f4f40cc9caaccccccccccccccdd99a9a9999949444f446666dd66d66d6d6666666d666d66d5559af9aa999dd66d669f9af9af
44000000000009990999999924242420ccc9aaacccccccccccddddd99999999949f44f9455555d5555555d5555555d556d55d66daf9af9f9f5595d55999f9af9
40000000000000000099999902222200cccc99cccccccccccccccddd9999999944ff44946d66666d6d66d6666d6666d6550055559aaf9a99a996d666f999af99
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
01060000215302b5312b5312b5212b5310d5012900026000215002b5012b5012b5012b5012b50128000240002900024000280000000000000000000000000000000000000000000000000000000000000002d000
011800000c1400e1411014111141131411514117141181411a1411c1411d1411f1412114123141241412614128141291412b1412d1412f1413014132101341010000000000000000000000000000000000000000
010c00001c15024101181010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001856000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

