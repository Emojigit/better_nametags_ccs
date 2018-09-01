better_nametags.register_tag(
	"default", 
	"#BBBBBB", 
	function(_) return true end, 
	0
)

better_nametags.register_tag(
	"lowhealth", --Name of the color, must be unique, can overwrite.
	"#DD0000", --Actual color. Hexidecimal value, or {r=r,g=g,b=b,a=a} table can work here
	function(player) --A boolean function with one parameter that will recieve a player: "true" means the player meets the criteria for having their nametag be this color
		return (player:get_hp() < 5)
	end, 
	-1 -- Weight of the color. When a player meets multiple colors' criteria, the highest weighted color will apply. Negative values disable the color entirely
)

better_nametags.register_tag(
	"admin", 
	"#FF5555",
	function(player) return minetest.check_player_privs(player, {ban=true}) end, 
	99
)

better_nametags.register_tag(
	"host", 
	"#6060FF",
	function(player) return minetest.check_player_privs(player, {server=true}) end, 
	100
)