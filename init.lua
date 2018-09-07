better_nametags = {}
better_nametags.allowSneak=true
better_nametags.enableCustomTags=true
better_nametags.tags = {}
better_nametags.players = {}
better_nametags.sneakingPlayers = {}
better_nametags.playerTags = {}

local defaultNameFunction = function(player) return player:get_player_name() end
local defaultCheckFunction= function(player) return false end

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
		local listString = ""..#(minetest.get_connected_players()).." Online: "
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
	targetPlayer = "",
	tagType = "",
	static_save = false,
	collisionbox = {0.0,0.0,0.0,0.0,0.0,0.0},
	on_step = function(self, _)
		local player_name = self.targetPlayer
		if player_name ~= "" then
			if better_nametags.playerTags[player_name] ~= self.tagType or not better_nametags.players[player_name] then
				self.object:remove()
			elseif minetest.get_player_by_name(player_name) then
				local pos=minetest.get_player_by_name(player_name):get_pos()
				pos.y=pos.y+1.1
				self.object:move_to(pos, false)
			end
		end
	end,
})

minetest.register_on_joinplayer(function(player)
	better_nametags.players[player:get_player_name()] = false
	better_nametags.sneakingPlayers[player:get_player_name()] = false
end)

minetest.register_on_leaveplayer(function(player, _)
	local player_name = player:get_player_name()
	local remainingPlayers = {}
	local remainingPlayerTags = {}
	local remainingPlayersSneaking = {}
	for _, online in ipairs(minetest.get_connected_players()) do
		if online:get_player_name() ~= player_name then
			remainingPlayers[online:get_player_name()] = better_nametags.players[online:get_player_name()]
			remainingPlayerTags[online:get_player_name()] = better_nametags.playerTags[online:get_player_name()]
			remainingPlayersSneaking[online:get_player_name()] = better_nametags.sneakingPlayers[online:get_player_name()]
			
		end
	end
	better_nametags.players = remainingPlayers
	better_nametags.playerTags = remainingPlayerTags
	better_nametags.sneakingPlayers = remainingPlayersSneaking
end)

minetest.register_on_dieplayer(function(player)
	better_nametags.players[player:get_player_name()] = false
	better_nametags.sneakingPlayers[player:get_player_name()] = false
	better_nametags.playerTags[player:get_player_name()] = ""
end)

minetest.register_globalstep(function(dtime) 
	for _, player in ipairs(minetest.get_connected_players()) do
		if player then
			local player_name = player:get_player_name()
			local tag = ""
			local highestWeight = -1
			
			if better_nametags.enableCustomTags then
				for _,registeredTag in pairs(better_nametags.tags) do
					if registeredTag.weight > highestWeight then
						if registeredTag.has(player) then
							tag = registeredTag.title
							highestWeight = registeredTag.weight
						end
					end
				end
			end
			
			if player:get_player_control().sneak and better_nametags.allowSneak then
				better_nametags.players[player_name] = false
				better_nametags.sneakingPlayers[player_name] = true
			else
				better_nametags.sneakingPlayers[player_name] = false
			end
			
			if (tag ~= better_nametags.playerTags[player_name] or not better_nametags.players[player_name]) and not better_nametags.sneakingPlayers[player_name] then
				player:set_nametag_attributes({
					text = " ",
					color = {a = 0, r = 0, g = 0, b = 0}
				})
				local pos = player:get_pos()
				local nametagEntity = minetest.add_entity(pos, "better_nametags:nametag")
				local tagColor = "#FFFFFF"
				local tagName = player:get_player_name()
				nametagEntity:get_luaentity().tagType = ""
				
				if better_nametags.tags[tag] then
					tagName = better_nametags.tags[tag].getName(player)
					tagColor = better_nametags.tags[tag].Color
					highestWeight = better_nametags.tags[tag].weight
				end
				
				nametagEntity:get_luaentity().tagType = tag
				better_nametags.playerTags[player_name] = tag
				
				nametagEntity:set_nametag_attributes({
					text = tagName,
					color = tagColor
				})
				nametagEntity:get_luaentity().targetPlayer = player_name
				better_nametags.players[player_name] = true --I would use set_attach(), but it causes a glitch where the entity's nametag is stuck at (0,0,0) when viewed by the attached player
			end
		end
	end
end)