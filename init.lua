better_nametags = {}
better_nametags.allowSneak=true
better_nametags.privilegeColors=true
better_nametags.playerColor={a=255, r=200, g=200, b=200}
better_nametags.adminColor={a=255, r=255, g=128, b=128}
better_nametags.hostColor="#5555FF"
better_nametags.players = {}
better_nametags.sneakingPlayers = {}

local function listPlayers(name, _) 
	local onlineCount = 0
	onlineCount = #(minetest.get_connected_players())
	local listString = ""..onlineCount.." Online: "
	local foundPlayer = false
	local iterated=1
	for _,connectedPlayer in ipairs(minetest.get_connected_players()) do
		listString=listString..connectedPlayer:get_player_name()
		if iterated < onlineCount then
			listString=listString..", "
		end
		iterated=iterated+1
	end
	core.chat_send_player(name, listString)
end

minetest.register_chatcommand("list", {
	description = "List all players currently online.",
	func = listPlayers,
	
})

minetest.register_entity("better_nametags:nametag", {
	--Don't use "set_attach", it creates a weird effect where the player will see their nametag underground
	visual = "sprite",	
	textures = {"null.png"},
	immortal = true,
	collisionbox = {0.0,0.0,0.0,0.0,0.0,0.0},
	on_step = function(self, _)
		if not better_nametags.players[self.object:get_nametag_attributes().text] then
			self.object:remove()
		elseif minetest.get_player_by_name(self.object:get_nametag_attributes().text) then
			local pos=minetest.get_player_by_name(self.object:get_nametag_attributes().text):get_pos()
			pos.y=pos.y+1.1
			self.object:move_to(pos, false)
		end
	end,
})
minetest.register_on_leaveplayer(function(player)
	better_nametags.players[player:get_player_name()] = false
	better_nametags.sneakingPlayers[player:get_player_name()] = false
end)
minetest.register_on_leaveplayer(function(player, _)
	if better_nametags.players[player:get_player_name()] then
		table.remove(better_nametags.players, player:get_player_name())
	end
	if better_nametags.sneakingPlayers[player:get_player_name()] then
		table.remove(better_nametags.sneakingPlayers, player:get_player_name())
	end
end)

minetest.register_globalstep(function(dtime) 
	for _, player in ipairs(minetest.get_connected_players()) do
		if player then
			local player_name = player:get_player_name()
			
			if not (better_nametags.players[player_name] or better_nametags.sneakingPlayers[player_name]) then
				player:set_nametag_attributes({
					text = "",
					color = {a = 0, r = 0, g = 0, b = 0}
				})
				local pos = player:get_pos()
				local nametagEntity = minetest.add_entity(pos, "better_nametags:nametag")
				local tagColor = better_nametags.playerColor
				if better_nametags.privilegeColors then
					if minetest.check_player_privs(player, {privs=true}) then
						tagColor = better_nametags.adminColor
					end
					if minetest.check_player_privs(player, {server=true}) then
						tagColor = better_nametags.hostColor
					end
				end
				nametagEntity:set_nametag_attributes({
					text = player_name,
					color = tagColor
				})
				better_nametags.players[player_name] = true
			end
			
			if player:get_player_control().sneak and better_nametags.allowSneak then
				better_nametags.players[player_name] = false
				better_nametags.sneakingPlayers[player_name] = true
			else
				better_nametags.sneakingPlayers[player_name] = false
			end
		end
	end
end)