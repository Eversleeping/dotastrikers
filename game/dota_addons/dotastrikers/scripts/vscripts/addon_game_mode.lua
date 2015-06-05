requires = {
	'lib.statcollection',
	'util',
	'timers',
	'physics',
	--'newphysics',
	'dotastrikers',
	'components',
	'initmap',
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
	PrecacheResource("particle_folder", "particles/ball2", context)
	PrecacheResource("particle_folder", "particles/thunderclap", context)
	PrecacheResource("particle_folder", "particles/frowns", context)
	PrecacheResource("particle_folder", "particles/taunts", context)
	PrecacheResource("particle_folder", "particles/powershot", context)
	PrecacheResource("particle_folder", "particles/slam", context)
	PrecacheResource("particle_folder", "particles/black_hole", context)
	PrecacheResource("particle_folder", "particles/time_walk", context)
	PrecacheResource("particle_folder", "particles/saved_txt", context)
	PrecacheResource("particle_folder", "particles/scored_txt", context)
	PrecacheResource("particle_folder", "particles/stolen", context)
	PrecacheResource("particle_folder", "particles/stolen_badguys", context)
	--PrecacheResource("particle_folder", "blah", context)
	--PrecacheResource("particle_folder", "blah", context)
	--PrecacheResource("particle_folder", "blah", context)
	--PrecacheResource("particle_folder", "blah", context)
	--PrecacheResource("particle_folder", "blah", context)

	PrecacheResource("particle", "particles/units/heroes/hero_wisp/wisp_tether.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_pugna/pugna_life_drain.vpcf", context)
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
	PrecacheResource("particle", "particles/units/heroes/hero_bounty_hunter/bounty_hunter_windwalk.vpcf", context)
	PrecacheResource("particle", "particles/ninja_invis_sprint/dark_seer_surge.vpcf", context)
	PrecacheResource("particle", "particles/pass_me.vpcf", context)
	PrecacheResource("particle", "particles/exclamation.vpcf", context)
	PrecacheResource("particle", "particles/legion_duel_victory/legion_commander_duel_victory.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_rubick/rubick_telekinesis.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_wisp/wisp_overcharge.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_meepo/meepo_earthbind.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_templar_assassin/templar_assassin_trap_explode.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_puck/puck_illusory_orb.vpcf", context)
	PrecacheResource("particle", "particles/illusory_orb/puck_illusory_orb.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/puck/puck_alliance_set/puck_waning_rift_aproset.vpcf", context)
	PrecacheResource("particle", "particles/items_fx/blink_dagger_start.vpcf", context)
	PrecacheResource("particle", "particles/ghost_model.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_bloodseeker/bloodseeker_rupture.vpcf", context)
	PrecacheResource("particle", "particles/batrider_stickynapalm_stack.vpcf", context)
	PrecacheResource("particle", "particles/wisp_relocate_timer.vpcf", context)
	PrecacheResource("particle", "particles/wisp_relocate_timer_b.vpcf", context)

	-- blood
	PrecacheResource("particle", "particles/units/heroes/hero_life_stealer/life_stealer_infest_emerge_bloody.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_centaur/centaur_double_edge_bloodspray_src.vpcf", context)

	PrecacheResource("particle", "particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_chakra_magic.vpcf", context)
	PrecacheResource("particle", "particles/generic_gameplay/radiant_fountain_regen.vpcf", context)
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
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_spirit_breaker.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_slardar.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_weaver.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_bounty_hunter.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_enigma.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_brewmaster.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_leshrac.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_earth_spirit.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_elder_titan.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_creeps.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_items.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_ui.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_ambient.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_roshan_halloween.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/soundevents_custom.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_rubick.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_templar_assassin.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_wisp.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_faceless_void.vsndevts", context)
	--PrecacheResource("soundfile", "blah", context)
	--PrecacheResource("soundfile", "blah", context)
	--PrecacheResource("soundfile", "blah", context)
	--PrecacheResource("soundfile", "blah", context)
	--PrecacheResource("soundfile", "blah", context)
	--PrecacheResource("soundfile", "blah", context)
	--PrecacheResource("soundfile", "blah", context)
	--PrecacheResource("soundfile", "blah", context)
	--PrecacheResource("soundfile", "blah", context)

	PrecacheItemByNameSync("item_phase_boots", context)

	-- Entire heroes (sound effects/voice/models/particles) can be precached with PrecacheUnitByNameSync
	-- Custom units from npc_units_custom.txt can also have all of their abilities and precache{} blocks precached in this way
	PrecacheUnitByNameSync("npc_dota_hero_ancient_apparition", context)
	PrecacheUnitByNameSync("npc_dota_hero_omniknight", context)
	PrecacheUnitByNameSync("npc_dota_hero_earthshaker", context)
	PrecacheUnitByNameSync("npc_dota_roshan", context)
	PrecacheUnitByNameSync("npc_dota_bloodseeker", context)
	--PrecacheUnitByNameSync("npc_dota_hero_rubick", context)
	--PrecacheUnitByNameSync("blah", context)
	--PrecacheUnitByNameSync("blah", context)
	--PrecacheUnitByNameSync("blah", context)
	--PrecacheUnitByNameSync("blah", context)
	--PrecacheUnitByNameSync("blah", context)
	--PrecacheUnitByNameSync("blah", context)
	--PrecacheUnitByNameSync("blah", context)
	--PrecacheUnitByNameSync("blah", context)
end

-- Create the game mode when we activate
function Activate()
	GameRules.DotaStrikers = DotaStrikers()
	GameRules.DotaStrikers:InitDotaStrikers()
end

for i,v in ipairs(requires) do
	require(v)
end
