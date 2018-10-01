better_nametags = {}
better_nametags.allowSneak=true
better_nametags.tags = {}
better_nametags.players = {}
better_nametags.playerTags = {}


local defaultNameFunction = function(_) return _:get_player_name() end
local defaultCheckFunction= function(_) return false end

better_nametags.register_tag = function(tagName, color, checkFunction, nameFunction, rankWeight) 
	if nameFunction == nil then
		nameFunction = defaultNameFunction
	end
	if checkFunction == nil then
		checkFunction = defaultCheckFunction
	end
	better_nametags.tags[tagName] = {
		title = tagName,
		Color = color,
		has = checkFunction,
		getName = nameFunction,
		weight = rankWeight,
	}
end

modpath=minetest.get_modpath("better_nametags")
dofile(modpath.."/tag_types.lua")

minetest.register_chatcommand("players", {
	description = "List all players currently online.",
	func = function(name, _) 
		local onlineCount = #(minetest.get_connected_players())
		local listString = ""..onlineCount.." Online: "
		local iterated=1
		for _,connectedPlayer in ipairs(minetest.get_connected_players()) do
			local tag = better_nametags.tags[better_nametags.playerTags[connectedPlayer:get_player_name()]]
			if tag then
				listString=listString..tag.getName(connectedPlayer)
			else
				listString=listString..connectedPlayer:get_player_name()
			end
			if iterated < onlineCount then
				listString=listString..", "
			end
			iterated=iterated+1
		end
		core.chat_send_player(name, listString)
	end
	
})

minetest.register_entity("better_nametags:nametag", {
	visual = "sprite",	
	textures = {"null.png"},
	immortal = true,
	static_save = false,
	targetPlayer = "",
	tagType = "",
	collisionbox = {0.0,0.0,0.0,0.0,0.0,0.0},
	on_step = function(self, _)
		local player_name = self.targetPlayer
		if player_name ~= "" then
			if better_nametags.players[player_name] then
				local player = minetest.get_player_by_name(player_name)
				local p = player:get_pos()
				self.object:move_to({x=p.x, y=p.y+1.0,z=p.z})
				
				if player:get_nametag_attributes().text ~= " " then
					player:set_nametag_attributes({
						text = " ",
						color = {a = 0, r = 0, g = 0, b = 0}
					})
				end
				
				local tag = ""
				local highestWeight = -1
				local tagColor = "#FFFFFF"
				local tagName = player_name
			
				for _,registeredTag in pairs(better_nametags.tags) do
					if registeredTag.weight > highestWeight then
						if registeredTag.has(player) then
							tag = registeredTag.title
							highestWeight = registeredTag.weight
						end
					end
				end
				if self.tagType == tag then return end
				if better_nametags.tags[tag] then
					tagName = better_nametags.tags[tag].getName(player)
					tagColor = better_nametags.tags[tag].Color
					highestWeight = better_nametags.tags[tag].weight
				end
				self.object:set_nametag_attributes({
					text = tagName,
					color = tagColor
				})
				self.tagType = tag
				better_nametags.players[player:get_player_name()] = tag
				
				return
			end
		end
		self.object:remove()
	end,
})

local function addPlayerTag(player) 
	local pos = player:get_pos()
	local player_name = player:get_player_name()
	local tag = ""
	local highestWeight = -1
	local tagColor = "#FFFFFF"
	local tagName = player:get_player_name()
	
	if better_nametags.enableCustomTags then
		for _,registeredTag in pairs(better_nametags.tags) do
			if registeredTag.weight > highestWeight then
				if registeredTag.has(player) then
					tag = registeredTag.title
					highestWeight = registeredTag.weight
				end
			end
		end
		if better_nametags.tags[tag] then
			tagName = better_nametags.tags[tag].getName(player)
			tagColor = better_nametags.tags[tag].Color
			highestWeight = better_nametags.tags[tag].weight
		end
	end
	
	local nametagEntity = minetest.add_entity(pos, "better_nametags:nametag")
	nametagEntity:get_luaentity().tagType = ""
	
	
	nametagEntity:set_nametag_attributes({
		text = tagName,
		color = tagColor
	})
	
	nametagEntity:get_luaentity().tagType = tag
	nametagEntity:get_luaentity().targetPlayer = player_name
	
	better_nametags.players[player:get_player_name()] = tag
	better_nametags.playerTags[player:get_player_name()] = nametagEntity
end


minetest.register_on_joinplayer(function(player)
	addPlayerTag(player)
end)

minetest.register_on_leaveplayer(function(player, _)
	better_nametags.players[player:get_player_name()] = nil
	better_nametags.playerTags[player:get_player_name()] = nil
end)

minetest.register_globalstep(function(dtime) 
	for pname,entity in pairs(better_nametags.playerTags) do
		if not entity:get_luaentity() then
			--minetest.chat_send_all("[better_nametags] "..pname.."'s nametag died. What the hell?")
			if minetest.get_player_by_name(pname) then
				addPlayerTag(minetest.get_player_by_name(pname))
			end
		end
	end
end)