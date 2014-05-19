minetest.register_entity(":__builtin:item", {
	initial_properties = {
		hp_max = 1,
		physical = true,
		collide_with_objects = false,
		collisionbox = {-0.17,-0.17,-0.17, 0.17,0.17,0.17},
		visual = "sprite",
		visual_size = {x=0.5, y=0.5},
		textures = {""},
		spritediv = {x=1, y=1},
		initial_sprite_basepos = {x=0, y=0},
		is_visible = false,
		play_flash = false,
	},
	
	itemstring = '',
	physical_state = true,

	set_item = function(self, itemstring)
		self.itemstring = itemstring
		local stack = ItemStack(itemstring)
		local count = stack:get_count()
		local max_count = stack:get_stack_max()
		if count > max_count then
			count = max_count
			self.itemstring = stack:get_name().." "..max_count
		end
		local a = 0.15 + 0.15*(count/max_count)
		local itemtable = stack:to_table()
		local itemname = nil
		if itemtable then
			itemname = stack:to_table().name
		end
		local item_texture = nil
		local item_type = ""
		if minetest.registered_items[itemname] then
			item_texture = minetest.registered_items[itemname].inventory_image
			item_type = minetest.registered_items[itemname].type
		end
		prop = {
			is_visible = true,
			visual = "wielditem",
			textures = {itemname},
			visual_size = {x=a, y=a},
			collisionbox = {-0.8*a,-0.8*a,-0.8*a, 0.8*a,0.8*a,0.8*a},
			automatic_rotate = math.pi * 0.2,
		}
		self.object:set_properties(prop)
	end,

	get_staticdata = function(self)
		--return self.itemstring
		return minetest.serialize({
			itemstring = self.itemstring,
			always_collect = self.always_collect,
		})
	end,

	on_activate = function(self, staticdata)
		if string.sub(staticdata, 1, string.len("return")) == "return" then
			local data = minetest.deserialize(staticdata)
			if data and type(data) == "table" then
				self.itemstring = data.itemstring
				self.always_collect = data.always_collect
			end
		else
			self.itemstring = staticdata
		end
		self.object:set_armor_groups({immortal=1})
		self.object:setvelocity({x=0, y=2, z=0})
		self.object:setacceleration({x=0, y=-10, z=0})
		self:set_item(self.itemstring)
	end,

	on_step = function(self, dtime)
		local p = self.object:getpos()
		p.y = p.y - 0.3
		local nn = minetest.get_node(p).name
		-- If node is not registered or node is walkably solid and resting on nodebox
		local v = self.object:getvelocity()
		if not minetest.registered_nodes[nn] or minetest.registered_nodes[nn].walkable and v.y == 0 then
			if self.physical_state then
				local own_stack = ItemStack(self.object:get_luaentity().itemstring)
				for _,object in ipairs(minetest.env:get_objects_inside_radius(p, 1)) do
					local obj = object:get_luaentity()
					if obj and obj.name == "__builtin:item" and obj.physical_state == false then
						local stack = ItemStack(obj.itemstring)
						if own_stack:get_name() == stack:get_name() and stack:get_free_space() > 0 then 
							local overflow = false
							local count = stack:get_count() + own_stack:get_count()
							local max_count = stack:get_stack_max()
							if count>max_count then
								overflow = true
								count = count - max_count
							else
								self.itemstring = ''
							end	
							local pos=object:getpos() 
							pos.y = pos.y + (count - stack:get_count())/max_count * 0.15
							object:moveto(pos, false)
							--pos.y = pos.y + (count - stack:get_count())/max_count * 0.16
							--self.object:moveto(pos, false)
							local size
							local max_count = stack:get_stack_max()
								if not overflow then
									obj.itemstring = stack:get_name().." "..count
									local size = 0.15 + 0.15*(count/max_count)
									object:set_properties({
										visual_size = {x=size, y=size},
										collisionbox = {-0.8*size,-0.8*size,-0.8*size, 0.8*size,0.8*size,0.8*size}
									})
									self.object:remove()
									return
								else
									size = 0.3
									object:set_properties({
										visual_size = {x=size, y=size},
										collisionbox = {-0.8*size,-0.8*size,-0.8*size, 0.8*size,0.8*size,0.8*size}
									})
									obj.itemstring = stack:get_name().." "..max_count
									size = 0.15 + 0.15*(count/max_count)
									self.object:set_properties({
										visual_size = {x=size, y=size},
										collisionbox = {-0.8*size,-0.8*size,-0.8*size, 0.8*size,0.8*size,0.8*size}
									})
									self.itemstring = stack:get_name().." "..count
								end
						end
					end
				end
				self.object:setvelocity({x=0,y=0,z=0})
				self.object:setacceleration({x=0, y=0, z=0})
				self.physical_state = false
				self.object:set_properties({
					physical = false
				})
			end
		else
			if not self.physical_state then
				self.object:setvelocity({x=0,y=0,z=0})
				self.object:setacceleration({x=0, y=-10, z=0})
				self.physical_state = true
				self.object:set_properties({
					physical = true
				})
			end
		end
	end,

	on_punch = function(self, hitter)
		if self.itemstring ~= '' then
			local left = hitter:get_inventory():add_item("main", self.itemstring)
			if not left:is_empty() then
				self.itemstring = left:to_string()
				return
			end
		end
		self.itemstring = ''
		self.object:remove()
	end,
})

