requires = {
	'lib.statcollection',
	'util',
	'timers',
	'physics',
	'constants',
	'dotastrikers',
	'initmap',
	'referee',
	'ball',
	'myphysics',
	'ability_proxy',
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
	PrecacheResource("particle_folder", "particles/powershot", context)
	PrecacheResource("particle_folder", "particles/pass_me", context)
	PrecacheResource("particle_folder", "particles/thunderclap", context)
	PrecacheResource("particle_folder", "particles/frowns", context)
	PrecacheResource("particle_folder", "particles/wall_eg", context)
	PrecacheResource("particle_folder", "particles/powershot", context)
	PrecacheResource("particle_folder", "particles/slam", context)
	--PrecacheResource("particle_folder", "particles/econ/items/earthshaker/earthshaker_gravelmaw", context)

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
	PrecacheResource("particle", "particles/units/heroes/hero_nevermore/nevermore_shadowraze_ground_cracks.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_ground_cracks.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_brewmaster/brewmaster_thunder_clap.vpcf", context)
	PrecacheResource("particle", "particles/items2_fx/phase_boots.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/earthshaker/earthshaker_gravelmaw/earthshaker_fissure_gravelmaw.vpcf", context)
	PrecacheResource("particle", "particles/medusa_mana_shield_impact_highlight01.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/earthshaker/egteam_set/hero_earthshaker_egset/earthshaker_echoslam_egset.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_silencer/silencer_last_word_trigger_cracks.vpcf", context)
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
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_earthshaker.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_vengefulspirit.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_creeps.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_items.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_ui.vsndevts", context)
	--game_sounds_items
	PrecacheResource("soundfile", "soundevents/soundevents_custom.vsndevts", context)

	PrecacheItemByNameSync("item_phase_boots", context)

	-- Entire heroes (sound effects/voice/models/particles) can be precached with PrecacheUnitByNameSync
	-- Custom units from npc_units_custom.txt can also have all of their abilities and precache{} blocks precached in this way
	PrecacheUnitByNameSync("npc_dota_hero_ancient_apparition", context)
	PrecacheUnitByNameSync("npc_dota_hero_omniknight", context)
	PrecacheUnitByNameSync("npc_dota_hero_earthshaker", context)
end

-- Create the game mode when we activate
function Activate()
	GameRules.DotaStrikers = DotaStrikers()
	GameRules.DotaStrikers:InitDotaStrikers()
end

for i,v in ipairs(requires) do
	require(v)
end