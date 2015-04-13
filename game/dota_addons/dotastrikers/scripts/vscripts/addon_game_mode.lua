BASE_MODULES = {
	'util',
	'timers',
	'physics',
	'lib.statcollection',
	'dotastrikers',
	'abilities',
}

function Precache( context )
	-- NOTE: IT IS RECOMMENDED TO USE A MINIMAL AMOUNT OF LUA PRECACHING, AND A MAXIMAL AMOUNT OF DATADRIVEN PRECACHING.
	-- Precaching guide: https://moddota.com/forums/discussion/119/precache-fixing-and-avoiding-issues

	print("[DOTASTRIKERS] Performing pre-load precache")

	-- Particles can be precached individually or by folder
	-- It it likely that precaching a single particle system will precache all of its children, but this may not be guaranteed
	--PrecacheResource("particle", "particles/econ/generic/generic_aoe_explosion_sphere_1/generic_aoe_explosion_sphere_1.vpcf", context)
	PrecacheResource("particle_folder", "particles/ball", context)
	--particles/powershot/windrunner_spell_powershot.vpcf
	PrecacheResource("particle_folder", "particles/powershot", context)
	--PrecacheResource("particle_folder", "particles/shield", context)

	PrecacheResource("particle", "particles/units/heroes/hero_wisp/wisp_tether.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_pugna/pugna_life_drain.vpcf", context)
	--particles/econ/items/puck/puck_alliance_set/puck_dreamcoil_tether_aproset.vpcf
	PrecacheResource("particle", "particles/econ/items/puck/puck_alliance_set/puck_dreamcoil_tether_aproset.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_pugna/pugna_life_drain.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_dark_seer/dark_seer_surge.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_spirit_breaker/spirit_breaker_charge.vpcf", context)
	PrecacheResource("particle", "particles/generic_gameplay/rune_haste_owner.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_medusa/medusa_mana_shield_impact.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_medusa/medusa_mana_shield_mod.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_medusa/medusa_mana_shield_oom.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_medusa/medusa_mana_shield_shell_add.vpcf", context)
	PrecacheResource("particle", "particles/items_fx/courier_shield.vpcf", context)
	PrecacheResource("particle", "particles/courier_shield.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_medusa/medusa_mana_shield_oval_endcap.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_medusa/medusa_mana_shield.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_lich/lich_frost_nova_sphere_1.vpcf", context)
	PrecacheResource("particle", "particles/immunity_sphere_buff.vpcf", context)
	--PrecacheResource("particle", "blah", context)
	--PrecacheResource("particle", "blah", context)
	--PrecacheResource("particle", "blah", context)
	--PrecacheResource("particle", "blah", context)
	--PrecacheResource("particle", "blah", context)
	--PrecacheResource("particle", "blah", context)
	--PrecacheResource("particle", "blah", context)
	--PrecacheResource("particle", "blah", context)
	--PrecacheResource("particle", "blah", context)
	--PrecacheResource("particle", "blah", context)
	--PrecacheResource("particle", "blah", context)
	--PrecacheResource("particle", "blah", context)

	-- Models can also be precached by folder or individually
	--PrecacheModel should generally used over PrecacheResource for individual models
	--PrecacheResource("model_folder", "particles/heroes/antimage", context)
	--PrecacheResource("model", "particles/heroes/viper/viper.vmdl", context)
	--PrecacheModel("models/heroes/viper/viper.vmdl", context)

	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_puck.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_vengefulspirit.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_creeps.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_items.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_ui.vsndevts", context)
	--game_sounds_items
	PrecacheResource("soundfile", "soundevents/soundevents_custom.vsndevts", context)

	-- Entire items can be precached by name
	-- Abilities can also be precached in this way despite the name
	PrecacheItemByNameSync("example_ability", context)
	PrecacheItemByNameSync("item_example_item", context)

	-- Entire heroes (sound effects/voice/models/particles) can be precached with PrecacheUnitByNameSync
	-- Custom units from npc_units_custom.txt can also have all of their abilities and precache{} blocks precached in this way
	PrecacheUnitByNameSync("npc_dota_hero_ancient_apparition", context)
	PrecacheUnitByNameSync("npc_dota_hero_omniknight", context)
end

--MODULE LOADER STUFF by Adynathos
BASE_LOG_PREFIX = '[DS]'


LOG_FILE = "log/DotaStrikers.txt"

InitLogFile(LOG_FILE, "[[ DotaStrikers ]]")

function log(msg)
	print(BASE_LOG_PREFIX .. msg)
	AppendToLogFile(LOG_FILE, msg .. '\n')
end

function err(msg)
	display('[X] '..msg, COLOR_RED)
end

function warning(msg)
	display('[W] '..msg, COLOR_DYELLOW)
end

function display(text, color)
	color = color or COLOR_LGREEN

	log('> '..text)

	Say(nil, color..text, false)
end

local function load_module(mod_name)
	-- load the module in a monitored environment
	local status, err_msg = pcall(function()
		require(mod_name)
	end)

	if status then
		log(' module ' .. mod_name .. ' OK')
	else
		err(' module ' .. mod_name .. ' FAILED: '..err_msg)
	end
end

-- Load all modules
for i, mod_name in pairs(BASE_MODULES) do
	load_module(mod_name)
end
--END OF MODULE LOADER STUFF

-- Create the game mode when we activate
function Activate()
	GameRules.DotaStrikers = DotaStrikers()
	GameRules.DotaStrikers:InitDotaStrikers()
end
