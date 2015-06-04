print ('[DOTASTRIKERS] dotastrikers.lua' )

Testing = true
NEXT_FRAME = .033
--TestMoreAbilities = false
OutOfWorldVector = Vector(5000, 5000, -200)
DrawDebug = false
UseCursorStream = false

Bounds = {max = 1366.77}
Bounds.min = -1*Bounds.max

HERO_SELECTION_TIME = 60
PRE_GAME_TIME = 0
POST_GAME_TIME = 30

PRE_FIRSTROUND_START = 8
SCORE_TO_WIN = 13

if Testing then
	PRE_FIRSTROUND_START = 1
	--SCORE_TO_WIN = 4
end

RoundsCompleted = 0

-- define classes
Ball = {}
MovementComponents = {}

if not Testing then --Only send stats when not testing
  statcollection.addStats({
    modID = '7044690ce484329ad2704e8c12a0498b'
  })
end

ColorStr = 
{	-- This is plyID+1
	[1] = "blue",
	[2] = "cyan",
	[3] = "purple",
	[4] = "yellow",
	[5] = "orange",
	[6] = "pink",
	[7] = "light_green",
	[8] = "sky_blue",
	[9] = "dark_green",
	[10] = "brown",
}

ColorHex = 
{	-- This is plyID+1
	[1] = COLOR_BLUE,
	[2] = COLOR_BLUE,
	[3] = COLOR_PURPLE,
	[4] = COLOR_DYELLOW,
	[5] = COLOR_ORANGE,
	[6] = COLOR_PINK,
	[7] = COLOR_GREEN,
	[8] = COLOR_SBLUE,
	[9] = COLOR_DGREEN,
	[10] = COLOR_GOLD,
}

DummyNames =
{
	[1] = "Myll",
	[2] = "Steve",
	[3] = "Nathan",
	[4] = "Alex",
	[5] = "Joan",
	[6] = "Christian",
	[7] = "Amy",
	[8] = "Chris",
	[9] = "Jim",
	[10] = "Dan",
}

-- Generated from template
if DotaStrikers == nil then
	--print ( '[DOTASTRIKERS] creating dotastrikers game mode' )
	DotaStrikers = class({})
end

function DotaStrikers:PostLoadPrecache()
	--print("[DOTASTRIKERS] Performing Post-Load precache")

	PrecacheUnitByNameAsync("npc_precache_everything", function(...) end)
end

--[[
  This function is called once and only once as soon as the first player (almost certain to be the server in local lobbies) loads in.
  It can be used to initialize state that isn't initializeable in InitDotaStrikers() but needs to be done before everyone loads in.
]]
function DotaStrikers:OnFirstPlayerLoaded()
	--print("[DOTASTRIKERS] First Player has loaded")
end

--[[
  This function is called once and only once after all players have loaded into the game, right as the hero selection time begins.
  It can be used to initialize non-hero player state or adjust the hero selection (i.e. force random etc)
]]
function DotaStrikers:OnAllPlayersLoaded()
	PlayerCount = 0
	for i=0,9 do
		local ply = PlayerResource:GetPlayer(i)
		if ply and ply:GetAssignedHero() == nil then
			PlayerCount = PlayerCount + 1
			self.vPlayers[i] = ply
		end
	end

	Timers:CreateTimer(HERO_SELECTION_TIME, function()
		HeroSelectionOver = true
	end)

	Timers:CreateTimer(.06, function()
		FireGameEvent("all_players_loaded", {})
	end)

	Timers:CreateTimer(function()
		if not AllPlayersSelectedHeroes and not HeroSelectionOver then
			return .1
		end

		local count = PRE_FIRSTROUND_START
		Timers:CreateTimer(function()
			if count == 0 then
				ShowCenterMsg("PLAY!", 1)
			else
				ShowCenterMsg(tostring(count), 1)
				count = count - 1
				return 1
			end
		end)

		Timers:CreateTimer(PRE_FIRSTROUND_START, function()
			for _,ply in pairs(DotaStrikers.vPlayers) do
				local hero = ply:GetAssignedHero()

				if not hero then
					-- player did not select a hero. so force select one

				else
					RemoveEndgameRoot(hero)

					for i=1,6 do
						local abil = hero:GetAbilityByIndex(i-1)
						hero:RemoveAbility(abil:GetAbilityName())
						hero:AddAbility(hero.round_in_progress_abils[i])
						hero:FindAbilityByName(hero.round_in_progress_abils[i]):SetLevel(1)
					end
				end
			end
			print("RoundInProgress")
			RoundInProgress = true
		end)
	end)

	--[[local secs_till_game_starts = HERO_SELECTION_TIME

	Timers:CreateTimer(function()
		if secs_till_game_starts == 0 then
			--ShowCenterMsg( "PLAY!", 1 )
			return
		end

		--ShowCenterMsg( tostring(secs_till_game_starts), 1 )
		secs_till_game_starts = secs_till_game_starts - 1
		return 1
	end)]]

end

function DotaStrikers:OnPreGameState(  )

end

--[[
	This function is called once and only once when the game completely begins (about 0:00 on the clock).  At this point,
	gold will begin to go up in ticks if configured, creeps will spawn, towers will become damageable etc.  This function
	is useful for starting any game logic timers/thinkers, beginning the first round, etc.
]]
function DotaStrikers:OnGameInProgress()
	--print("[DOTASTRIKERS] The game has officially begun")
end

function DotaStrikers:PlayerSay( keys )
	local ply = keys.ply
	local hero = ply:GetAssignedHero()
	local txt = keys.text
	local ball = Ball.unit

	if keys.teamOnly then
		-- This text was team-only.
	end

	if txt == nil or txt == "" then
		return
	end
	--print("txt: " .. txt)
	if Testing then
		if txt == "pancamera" then
			PlayerResource:SetCameraTarget(ply:GetPlayerID(), Ball.unit)
			--print("pancamera")
		end
		if txt == "pancamera_off" then
			PlayerResource:SetCameraTarget(ply:GetPlayerID(), nil)
			--print("pancamera")
		end
		if txt == "ball_controller" then
			if ball.controller == nil then print ("ball controller is nil.") end
		end
		if txt == "silence" then
			print("txt==silence")
			FireGameEvent("toggle_show_ability_silenced", {player_ID=hero:GetPlayerID(), ability_index=2})
		end
		if txt == "particle" then
			ParticleManager:CreateParticle("particles/generic_gameplay/radiant_fountain_regen.vpcf", PATTACH_ABSORIGIN, hero)
		end
	end
end

-- Cleanup a player when they leave
function DotaStrikers:OnDisconnect(keys)
	--print('[DOTASTRIKERS] Player Disconnected ' .. tostring(keys.userid))
	--PrintTable(keys)

	local name = keys.name
	local networkid = keys.networkid
	local reason = keys.reason
	local userid = keys.userid
end

-- The overall game state has changed
function DotaStrikers:OnGameRulesStateChange(keys)

	local newState = GameRules:State_Get()
	if newState == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then
		-- load the game rules, help, etc
		self.bSeenWaitForPlayers = true
	elseif newState == DOTA_GAMERULES_STATE_INIT then
		Timers:RemoveTimer("alljointimer")
	elseif newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
		local et = 1
		if self.bSeenWaitForPlayers then
			et = .01
		end
		Timers:CreateTimer("alljointimer", {
			useGameTime = true,
			endTime = et,
			callback = function()
				if PlayerResource:HaveAllPlayersJoined() then
					DotaStrikers:PostLoadPrecache()
					DotaStrikers:OnAllPlayersLoaded()
					return
				end
				return .1 -- Check again later in case more players spawn
			end})
	elseif newState == DOTA_GAMERULES_STATE_PRE_GAME then
		self:OnPreGameState()
		--FireGameEvent("turn_off_waitforplayers", {})
	elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		DotaStrikers:OnGameInProgress()
	end
end

-- An NPC has spawned somewhere in game.  This includes heroes
function DotaStrikers:OnNPCSpawned(keys)
	local npc = EntIndexToHScript(keys.entindex)
	local ply = npc:GetPlayerOwner()
	if npc:IsRealHero() and ply ~= nil then
		local hero = npc
		if not ply.firstTime then
			if not self.greetPlayers then
				self:GreetPlayers()
				Ball.unit:SpawnParticle()
				self.greetPlayers = true
			end

			self:OnHeroInGameFirstTime(hero)
			ply.firstTime = true

		else
			self:OnHeroRespawn(hero)
		end
	end
end

function DotaStrikers:OnHeroInGameFirstTime( hero )
	--print("OnHeroInGameFirstTime")

	function hero:OnThink(  )
		--if not RoundInProgress then return end

		local pos = hero:GetAbsOrigin()
		--print("pos: " .. VectorString(pos))
		if hero.goalie then
			-- check if actually still in goal
			-- for the goalie, there is no z limit
			if not GetGoalUnitIsWithin( hero ) then
				hero.goalie = false
				hero.gc.goalie = nil
				hero.ballGoalieProc = false

				DotaStrikers:RemoveGoalieJump(hero) -- in initmap

				if hero:HasModifier("modifier_goalie") then
					hero:RemoveModifierByName("modifier_goalie")
				end
			else
				-- check to see if goalie jump is not added. if not, add it.
				DotaStrikers:AddGoalieJump(hero)

				if not hero:HasModifier("modifier_goalie") then
					GlobalDummy.dummy_passive:ApplyDataDrivenModifier(GlobalDummy, hero, "modifier_goalie", {})
				end
			end
		end

		if pos.x > 0 then
			if hero:GetTeam() == DOTA_TEAM_BADGUYS then
				hero.onOwnSide = true
			else
				hero.onOwnSide = false
			end
		else
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				hero.onOwnSide = true
			else
				hero.onOwnSide = false
			end
		end

		local isInBlackHole = false
		for i=0,9 do
			local bh_accel = hero.last_bh_accels[i]
			if bh_accel and bh_accel ~= Vector(0,0,0) then
				isInBlackHole = true
			end
		end
		hero.isInBlackHole = isInBlackHole

		if hero.isSprinter then
			if not hero.isInBlackHole and hero:GetPhysicsAcceleration():Length() < (-1*GRAVITY+50) then
				hero:SetPhysicsAcceleration(Vector(0,0,GRAVITY))
				--print("setting accel.")
			end
			--print("accel mag: " .. hero:GetPhysicsAcceleration():Length())
		end
	end

	hero.base_move_speed = 320

	Timers:CreateTimer(.1, function()
		hero.spawn_pos = hero:GetAbsOrigin()
	end)

	hero.plyID = hero:GetPlayerID()
	hero.colHex = ColorHex[hero.plyID+1]
	hero.colStr = ColorStr[hero.plyID+1]
	hero.components = {}
	AddMovementComponent(hero, "base", hero.base_move_speed)

	GlobalDummy.dummy_passive:ApplyDataDrivenModifier(GlobalDummy, hero, "modifier_hero_passive", {})

	-- Store the player's name inside this hero handle.
	hero.playerName = PlayerResource:GetPlayerName(hero.plyID)
	if hero.playerName == nil or hero.playerName == "" then
		hero.playerName = DummyNames[hero.plyID+1]
	end

	SetupStats(hero)

	if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
		hero.gc = self.gcs[1]
		--hero:SetCustomHealthLabel( hero.playerName, 255, 0, 0 )
	else
		hero.gc = self.gcs[2]
		--hero:SetCustomHealthLabel( hero.playerName, 0, 0, 255 )
	end

	-- mark the hero as a dota strikers hero.
	hero.isDSHero = true
	--Referee:SetControllableByPlayer(hero:GetPlayerID(), true)


	-- Store this hero handle in this table.
	table.insert(self.vHeroes, hero)
	--table.insert(self.colliderFilter, hero)

	hero.last_peak_z = 0

	hero.pp_collisions = {} -- player-player collisions

	hero.colliderID = DoUniqueString("a")
	self.colliderFilter[hero.colliderID] = hero

	self:SetupPhysicsSettings(hero)

	hero.tauntItem = CreateItem("item_taunt", hero, hero)
	hero.frownItem = CreateItem("item_frown", hero, hero)
	hero:AddItem(hero.tauntItem)
	hero:AddItem(hero.frownItem)

	-- this is for black holes.
	hero.last_bh_accels = {}
	for i=0,9 do
		hero.last_bh_accels[i] = Vector(0,0,0)
	end

	local classname = hero:GetClassname()
	--print("classname: " .. classname)
	local heroes_kv_name = "sprint"
	if classname == "npc_dota_hero_antimage" then
		hero.isSprinter = true
	elseif classname == "npc_dota_hero_slark" then
		hero.isNinja = true
		heroes_kv_name = "ninja"
	elseif classname == "npc_dota_hero_enigma" then
		hero.isEnigma = true
		hero.bh_targets = {}
		heroes_kv_name = "black_hole"
	-- why it's a capital I, i have no idea.
	elseif classname == "npc_dota_hero_Invoker" then
		hero.isPowershot = true
		heroes_kv_name = "powershot"
	elseif classname == "npc_dota_hero_earthshaker" then
		hero.isSlam = true
		heroes_kv_name = "slam"
	elseif classname == "npc_dota_hero_wisp" then
		hero.isPull = true
		heroes_kv_name = "pull"
	elseif classname == "npc_dota_hero_bloodseeker" then
		hero.isTackle = true
		hero.tackle_end_time = 0
		heroes_kv_name = "tackle"
		hero.tackleTargets = {}
	elseif classname == "npc_dota_hero_queenofpain" then
		hero.isBlink = true
		heroes_kv_name = "blink"
	elseif classname == "npc_dota_hero_pudge" then
		hero.isHook = true
		heroes_kv_name = "hook"
	elseif classname == "npc_dota_hero_puck" then
		hero.isSwap = true
		heroes_kv_name = "swap"
	end

	hero.heroes_kv_name = heroes_kv_name
	--print("heroes_kv_name: " .. heroes_kv_name)

	-- this is useful in between rounds, swapping ability bars. it's in initmap.lua
	self:GetRoundAbils(hero)

	self:SetupPersonalColliders(hero)

	Timers:CreateTimer(.04, function()
		if hero:GetPlayerOwner():GetAssignedHero() == nil then print("Hero still nil.") end
		InitAbilities(hero)
	end)

	hero.surgeTimer = Timers:CreateTimer(SURGE_TICK, function()
		local currMana = hero:GetMana()
		local maxMana = hero:GetMaxMana()
		local manaDrainInterval = SURGE_TICK*20
		local manaGainInterval = SURGE_TICK*10

		if hero.surgeOn then
			if currMana <= 0 then
				if hero.isSprinter then
					if hero:HasAbility("super_sprint_break") then
						hero:CastAbilityNoTarget(hero:FindAbilityByName("super_sprint_break"), 0)
					end
				elseif hero.isNinja then
					if hero:HasAbility("ninja_invis_sprint_break") then
						hero:CastAbilityNoTarget(hero:FindAbilityByName("ninja_invis_sprint_break"), 0)
					end
				elseif hero.isPowershot then
					if hero:HasAbility("powersprint_break") then
						hero:CastAbilityNoTarget(hero:FindAbilityByName("powersprint_break"), 0)
					end
				else
					if hero:HasAbility("surge_break") then
						hero:CastAbilityNoTarget(hero:FindAbilityByName("surge_break"), 0)
					end
				end
			end
			if hero.isSprinter then
				manaDrainInterval = SURGE_TICK*40
			elseif hero.isPowershot then
				manaDrainInterval = SURGE_TICK*40
			end
			hero:SetMana(currMana - manaDrainInterval)
			--print("draining " .. manaDrainInterval .. " mana")
		else
			if not (currMana >= maxMana) then
				hero:SetMana(currMana + manaGainInterval)

			end
		end
		return SURGE_TICK
	end)


	if #self.vHeroes >= PlayerCount then
		AllPlayersSelectedHeroes = true
		print("AllPlayersSelectedHeroes")
	end

	-- Physics thinker
	hero:OnPhysicsFrame(function(unit)
		DotaStrikers:OnMyPhysicsFrame(hero)
	end)

	-- Replace the abils with the round_not_in_progress abils
	if not RoundInProgress then
		Timers:CreateTimer(.03, function()
			AddEndgameRoot(hero)
			for i=1,6 do
				local abil = hero:GetAbilityByIndex(i-1)
				hero:RemoveAbility(abil:GetAbilityName())
				hero:AddAbility(hero.round_not_in_progress_abils[i])
				hero:FindAbilityByName(hero.round_not_in_progress_abils[i]):SetLevel(1)
			end
		end)
	end
end

function DotaStrikers:SetupPhysicsSettings( unit )
	Physics:Unit(unit)
	unit:Hibernate(false)
	--unit:FollowNavMesh (false)
	unit:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
	unit:SetGroundBehavior(PHYSICS_GROUND_ABOVE)
	-- gravity
	unit:SetPhysicsAcceleration(BASE_ACCELERATION)
	--unit:SetPhysicsBoundingRadius(unit:GetPaddedCollisionRadius()+20)
	unit.shieldParticles = {}
	unit.lastShieldParticleTime = GameRules:GetGameTime()

	unit:OnBounce(function(_unit, _normal)
		DotaStrikers:OnGridNavBounce( _unit, _normal )
	end)
	unit:OnPreBounce(function(_unit, _normal)
		DotaStrikers:OnPreGridNavBounce( _unit, _normal )
	end)
end

function DotaStrikers:OnHeroRespawn( hero )

end

function DotaStrikers:GreetPlayers(  )
	local lines = 
	{
		[1] = "Welcome to " .. ColorIt("Dota Strikers!!", "green"),
		[2] = "This is a " .. ColorIt("Football", "yellow") .. " game. When you have the ball, press " .. ColorIt("W", "orange") .. " to kick, and " .. ColorIt("E", "orange") .. " to sprint!",
		[3] = "Some heros have special abilities. Use " .. ColorIt("Q", "orange") .. " to use your hero's special ability!",
		[4] = "Press " .. ColorIt("D", "orange") .. " and " .. ColorIt("F", "orange") .. " to make your hero say stuff!",
		[5] = ColorIt("GOOD LUCK, HAVE FUN!!", "pink"),
	}

	Timers:CreateTimer(2, function()
		ShowQuickMessages( lines, 2 )
	end)
end

-- An entity somewhere has been hurt.  This event fires very often with many units so don't do too many expensive
-- operations here
function DotaStrikers:OnEntityHurt(keys)
	--print("[DOTASTRIKERS] Entity Hurt")
	--PrintTable(keys)
	local attacker = EntIndexToHScript(keys.entindex_attacker)
	local victim = EntIndexToHScript(keys.entindex_killed)
end

-- An item was picked up off the ground
function DotaStrikers:OnItemPickedUp(keys)
	--print ( '[DOTASTRIKERS] OnItemPurchased' )
	--PrintTable(keys)

	local heroEntity = EntIndexToHScript(keys.HeroEntityIndex)
	local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local itemname = keys.itemname
end

-- A player has reconnected to the game.  This function can be used to repaint Player-based particles or change
-- state as necessary
function DotaStrikers:OnPlayerReconnect(keys)
	--print ( '[DOTASTRIKERS] OnPlayerReconnect' )
	--PrintTable(keys)
end

-- An item was purchased by a player
function DotaStrikers:OnItemPurchased( keys )
	--print ( '[DOTASTRIKERS] OnItemPurchased' )
	--PrintTable(keys)

	-- The playerID of the hero who is buying something
	local plyID = keys.PlayerID
	if not plyID then return end

	-- The name of the item purchased
	local itemName = keys.itemname

	-- The cost of the item purchased
	local itemcost = keys.itemcost

end

-- An ability was used by a player
function DotaStrikers:OnAbilityUsedProxy(keys)
	self:OnAbilityUsed(keys)
end

-- A non-player entity (necro-book, chen creep, etc) used an ability
function DotaStrikers:OnNonPlayerUsedAbility(keys)
	--print('[DOTASTRIKERS] OnNonPlayerUsedAbility')
	--PrintTable(keys)

	local abilityname=  keys.abilityname
end

-- A player changed their name
function DotaStrikers:OnPlayerChangedName(keys)
	--print('[DOTASTRIKERS] OnPlayerChangedName')
	--PrintTable(keys)

	local newName = keys.newname
	local oldName = keys.oldName
end

-- A player leveled up an ability
function DotaStrikers:OnPlayerLearnedAbility( keys)
	--print ('[DOTASTRIKERS] OnPlayerLearnedAbility')
	--PrintTable(keys)

	local player = EntIndexToHScript(keys.player)
	local abilityname = keys.abilityname
end

-- A channelled ability finished by either completing or being interrupted
function DotaStrikers:OnAbilityChannelFinished(keys)
	--print ('[DOTASTRIKERS] OnAbilityChannelFinished')
	--PrintTable(keys)

	local abilityname = keys.abilityname
	local interrupted = keys.interrupted == 1
end

-- A player leveled up
function DotaStrikers:OnPlayerLevelUp(keys)
	--print ('[DOTASTRIKERS] OnPlayerLevelUp')
	--PrintTable(keys)

	local player = EntIndexToHScript(keys.player)
	local level = keys.level
end

-- A player last hit a creep, a tower, or a hero
function DotaStrikers:OnLastHit(keys)
	--print ('[DOTASTRIKERS] OnLastHit')
	--PrintTable(keys)

	local isFirstBlood = keys.FirstBlood == 1
	local isHeroKill = keys.HeroKill == 1
	local isTowerKill = keys.TowerKill == 1
	local player = PlayerResource:GetPlayer(keys.PlayerID)
end

-- A tree was cut down by tango, quelling blade, etc
function DotaStrikers:OnTreeCut(keys)
	--print ('[DOTASTRIKERS] OnTreeCut')
	--PrintTable(keys)

	local treeX = keys.tree_x
	local treeY = keys.tree_y
end

-- A rune was activated by a player
function DotaStrikers:OnRuneActivated (keys)
	--print ('[DOTASTRIKERS] OnRuneActivated')
	--PrintTable(keys)

	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local rune = keys.rune

	--[[ Rune Can be one of the following types
	DOTA_RUNE_DOUBLEDAMAGE
	DOTA_RUNE_HASTE
	DOTA_RUNE_HAUNTED
	DOTA_RUNE_ILLUSION
	DOTA_RUNE_INVISIBILITY
	DOTA_RUNE_MYSTERY
	DOTA_RUNE_RAPIER
	DOTA_RUNE_REGENERATION
	DOTA_RUNE_SPOOKY
	DOTA_RUNE_TURBO
	]]
end

-- A player took damage from a tower
function DotaStrikers:OnPlayerTakeTowerDamage(keys)
	--print ('[DOTASTRIKERS] OnPlayerTakeTowerDamage')
	--PrintTable(keys)

	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local damage = keys.damage
end

-- A player picked a hero
function DotaStrikers:OnPlayerPickHero(keys)
	--print ('[DOTASTRIKERS] OnPlayerPickHero')
	--PrintTable(keys)

	local heroClass = keys.hero
	local heroEntity = EntIndexToHScript(keys.heroindex)
	local player = EntIndexToHScript(keys.player)
end

-- A player killed another player in a multi-team context
function DotaStrikers:OnTeamKillCredit(keys)
	--print ('[DOTASTRIKERS] OnTeamKillCredit')
	--PrintTable(keys)

	local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
	local victimPlayer = PlayerResource:GetPlayer(keys.victim_userid)
	local numKills = keys.herokills
	local killerTeamNumber = keys.teamnumber
end

-- An entity died
function DotaStrikers:OnEntityKilled( keys )
	--print( '[DOTASTRIKERS] OnEntityKilled Called' )
	--PrintTable( keys )

	-- The Unit that was Killed
	local killedUnit = EntIndexToHScript( keys.entindex_killed )
	-- The Killing entity
	local killerEntity = nil

	if keys.entindex_attacker ~= nil then
		killerEntity = EntIndexToHScript( keys.entindex_attacker )
	end

	if killedUnit:IsRealHero() then
		--print ("KILLEDKILLER: " .. killedUnit:GetName() .. " -- " .. killerEntity:GetName())
		
	end

end


-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
function DotaStrikers:InitDotaStrikers()
	DotaStrikers = self
	print('[DOTASTRIKERS] Starting to load DotaStrikers gamemode...')

	-- Setup rules
	GameRules:SetHeroRespawnEnabled( true )
	GameRules:SetUseUniversalShopMode( true )
	GameRules:SetSameHeroSelectionEnabled( true )
	GameRules:SetHeroSelectionTime( HERO_SELECTION_TIME )
	GameRules:SetPreGameTime( PRE_GAME_TIME )
	GameRules:SetPostGameTime( POST_GAME_TIME )
	GameRules:SetUseBaseGoldBountyOnHeroes(false)
	GameRules:SetHeroMinimapIconScale( .8 )
	GameRules:SetCreepMinimapIconScale( 1.4 )
	--print('[DOTASTRIKERS] GameRules set')

	InitLogFile( "log/dotastrikers.txt","")

	-- Event Hooks
	ListenToGameEvent('dota_player_gained_level', Dynamic_Wrap(DotaStrikers, 'OnPlayerLevelUp'), self)
	ListenToGameEvent('dota_ability_channel_finished', Dynamic_Wrap(DotaStrikers, 'OnAbilityChannelFinished'), self)
	ListenToGameEvent('dota_player_learned_ability', Dynamic_Wrap(DotaStrikers, 'OnPlayerLearnedAbility'), self)
	ListenToGameEvent('entity_killed', Dynamic_Wrap(DotaStrikers, 'OnEntityKilled'), self)
	ListenToGameEvent('player_connect_full', Dynamic_Wrap(DotaStrikers, 'OnConnectFull'), self)
	ListenToGameEvent('player_disconnect', Dynamic_Wrap(DotaStrikers, 'OnDisconnect'), self)
	ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(DotaStrikers, 'OnItemPurchased'), self)
	ListenToGameEvent('dota_item_picked_up', Dynamic_Wrap(DotaStrikers, 'OnItemPickedUp'), self)
	ListenToGameEvent('last_hit', Dynamic_Wrap(DotaStrikers, 'OnLastHit'), self)
	ListenToGameEvent('dota_non_player_used_ability', Dynamic_Wrap(DotaStrikers, 'OnNonPlayerUsedAbility'), self)
	ListenToGameEvent('player_changename', Dynamic_Wrap(DotaStrikers, 'OnPlayerChangedName'), self)
	--ListenToGameEvent('dota_rune_activated_server', Dynamic_Wrap(DotaStrikers, 'OnRuneActivated'), self)
	ListenToGameEvent('dota_player_take_tower_damage', Dynamic_Wrap(DotaStrikers, 'OnPlayerTakeTowerDamage'), self)
	ListenToGameEvent('tree_cut', Dynamic_Wrap(DotaStrikers, 'OnTreeCut'), self)
	ListenToGameEvent('entity_hurt', Dynamic_Wrap(DotaStrikers, 'OnEntityHurt'), self)
	ListenToGameEvent('player_connect', Dynamic_Wrap(DotaStrikers, 'PlayerConnect'), self)
	ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(DotaStrikers, 'OnAbilityUsedProxy'), self)
	ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(DotaStrikers, 'OnGameRulesStateChange'), self)
	ListenToGameEvent('npc_spawned', Dynamic_Wrap(DotaStrikers, 'OnNPCSpawned'), self)
	ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap(DotaStrikers, 'OnPlayerPickHero'), self)
	ListenToGameEvent('dota_team_kill_credit', Dynamic_Wrap(DotaStrikers, 'OnTeamKillCredit'), self)
	ListenToGameEvent("player_reconnected", Dynamic_Wrap(DotaStrikers, 'OnPlayerReconnect'), self)

	-- Commands can be registered for debugging purposes or as functions that can be called by the custom Scaleform UI
	Convars:RegisterCommand( "command_example", Dynamic_Wrap(DotaStrikers, 'ExampleConsoleCommand'), "A console command example", 0 )

	Convars:RegisterCommand('player_say', function(...)
		local arg = {...}
		table.remove(arg,1)
		local sayType = arg[1]
		table.remove(arg,1)

		local cmdPlayer = Convars:GetCommandClient()
		keys = {}
		keys.ply = cmdPlayer
		keys.teamOnly = false
		keys.text = table.concat(arg, " ")

		if (sayType == 4) then
			-- Student messages
		elseif (sayType == 3) then
			-- Coach messages
		elseif (sayType == 2) then
			-- Team only
			keys.teamOnly = true
			-- Call your player_say function here like
			self:PlayerSay(keys)
		else
			-- All chat
			-- Call your player_say function here like
			self:PlayerSay(keys)
		end
	end, 'player say', 0)

	Convars:RegisterCommand('close_menu', function(...)
		local cmdPlayer = Convars:GetCommandClient()
		EmitSoundOnClient("Close_Menu", cmdPlayer)
	end, '', 0)

	Convars:RegisterCommand('open_menu', function(...)
		local cmdPlayer = Convars:GetCommandClient()
		EmitSoundOnClient("Open_Menu", cmdPlayer)
	end, '', 0)

	Convars:RegisterCommand('click_radio_button', function(...)
		local cmdPlayer = Convars:GetCommandClient()
		EmitSoundOnClient("ui.click_toptab", cmdPlayer)
	end, '', 0)

	Convars:RegisterCommand('click_hero', function(...)
		local cmdPlayer = Convars:GetCommandClient()
		EmitSoundOnClient("ui.browser_click_common", cmdPlayer)
	end, '', 0)

	-- Change random seed
	local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
	math.randomseed(tonumber(timeTxt))

	--DeepPrintTable(LoadKeyValues("scripts/npc/npc_abilities_custom.txt"))

	-- PLAYER COLORS in RGB
	self.m_TeamColors = {}
	self.m_TeamColors[0] = { 50, 100, 220 } -- 49:100:218
	self.m_TeamColors[1] = { 90, 225, 155 } -- 87:224:154
	self.m_TeamColors[2] = { 170, 0, 160 } -- 171:0:156
	self.m_TeamColors[3] = { 210, 200, 20 } -- 211:203:16
	self.m_TeamColors[4] = { 215, 90, 5 } -- 214:87:8
	self.m_TeamColors[5] = { 210, 100, 150 } -- 210:97:153
	self.m_TeamColors[6] = { 130, 150, 80 } -- 130:154:80
	self.m_TeamColors[7] = { 100, 190, 200 } -- 99:188:206
	self.m_TeamColors[8] = { 5, 110, 50 } -- 7:109:44
	self.m_TeamColors[9] = { 130, 80, 5 } -- 124:75:6

	GlobalDummy = CreateUnitByName("global_dummy", Vector(0,0,0), false, nil, nil, DOTA_TEAM_GOODGUYS)
	GlobalDummy.rooted_passive = GlobalDummy:FindAbilityByName("rooted_passive")
	GlobalDummy.dummy_passive = GlobalDummy:FindAbilityByName("global_dummy_passive")

	GroundZ = GetGroundPosition(GlobalDummy:GetAbsOrigin(), GlobalDummy).z
	--print("GroundZ: " .. GroundZ)

	EndRoundDummy = CreateUnitByName("endround_dummy", Vector(-4000,-4000,0), false, nil, nil, DOTA_TEAM_GOODGUYS)
	EndRoundDummy.endround_passive = EndRoundDummy:FindAbilityByName("endround_passive")

	self:InitCreeps() -- creep spectators

	RefereeSpawnPos = Vector(2780,1550,GroundZ)
	Referee = CreateUnitByName("referee", RefereeSpawnPos, true, nil, nil, DOTA_TEAM_NEUTRALS)
	-- helps avoid runtime errors down the road.
	SetupStats(Referee)

	Timers:CreateTimer(.06, function()
		AddEndgameRoot(Referee)
		AddDisarmed(Referee)

		Referee:FindAbilityByName("referee_passive"):SetLevel(1)
		Referee:SetCustomHealthLabel( "Referee", 255, 0, 0 )

		-- constantly make the ref look at the ball, for aesthetics
		Referee.referee_timer = Timers:CreateTimer(function()
			if Referee:HasModifier("modifier_disarmed_on") then
				Referee:SetForwardVector((Ball.unit:GetAbsOrigin()-Referee:GetAbsOrigin()):Normalized())
			end
			return .06
		end)

		DotaStrikers:InitMap()
		--print("initmap")
	end)

	self.lastGoalTime = 0

	VisionDummies = {GoodGuys = {}, BadGuys = {}}
	local timeOffset = .03
	-- CREATE vision dummies
	local offset = 1800 --528
	for y=8192, -5632, -1*offset do
		for x=-8192, 8192, offset do
			Timers:CreateTimer(timeOffset, function()
				--if GridNav:IsTraversable(Vector(x,y,GlobalDummy.z)) and not GridNav:IsBlocked(Vector(x,y,GlobalDummy.z)) then
				local goodguy = CreateUnitByName("vision_dummy", Vector(x,y,GlobalDummy.z), false, nil, nil, DOTA_TEAM_GOODGUYS)
				local badguy = CreateUnitByName("vision_dummy", Vector(x,y,GlobalDummy.z), false, nil, nil, DOTA_TEAM_BADGUYS)

				--modifier_vision_dummy
				GlobalDummy.dummy_passive:ApplyDataDrivenModifier(GlobalDummy, goodguy, "modifier_vision_dummy", {})
				GlobalDummy.dummy_passive:ApplyDataDrivenModifier(GlobalDummy, badguy, "modifier_vision_dummy", {})

				goodguy.isVisionDummy = true
				badguy.isVisionDummy = true
				table.insert(VisionDummies.GoodGuys, goodguy)
				table.insert(VisionDummies.BadGuys, badguy)
				--print("vision_dummy")
				--DebugDrawCircle(Vector(x,y,GlobalDummy.z), Vector(0,0,255), 10, 1800, true, 4000)
				--end
			end)
			timeOffset = timeOffset + .03
		end
	end

	-- Show the ending scoreboard immediately
	--GameRules:SetCustomGameEndDelay( 0 )
	--GameRules:SetCustomVictoryMessageDuration( 0 )

	self.HeroesKV = LoadKeyValues("scripts/npc/npc_heroes_custom.txt")
	self.AbilitiesKV = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
	--DeepPrintTable(self.AbilitiesKV)

	-- Initialized tables for tracking state
	self.vUserIds = {}
	self.vSteamIds = {}
	self.vBots = {}
	self.vBroadcasters = {}

	self.vPlayers = {}
	self.vHeroes = {}
	self.vRadiant = {}
	self.vDire = {}

	self.radiantScore = 0
	self.direScore = 0

	self.bSeenWaitForPlayers = false
	self.colliderFilter = {}

	Ball:Init()


	-- Main thinker
	LastHeroThinkerTime = GameRules:GetGameTime()
	Timers:CreateTimer(function()
		local currTime = GameRules:GetGameTime()
		for i,hero in ipairs(self.vHeroes) do
			hero:OnThink()

			if hero.goalie then
				hero.time_as_goalie = hero.time_as_goalie + (currTime - LastHeroThinkerTime)
			end
		end
		LastHeroThinkerTime = currTime
		return NEXT_FRAME
	end)

end

mode = nil

-- This function is called as the first player loads and sets up the DotaStrikers parameters
function DotaStrikers:CaptureDotaStrikers()
	if mode == nil then
		mode = GameRules:GetGameModeEntity()
		mode:SetRecommendedItemsDisabled( true )
		mode:SetCameraDistanceOverride( 2000 ) --1800
		mode:SetBuybackEnabled( false )
		mode:SetTopBarTeamValuesOverride ( true )
		mode:SetTopBarTeamValuesVisible( true )
		mode:SetGoldSoundDisabled( true )
		--mode:SetRemoveIllusionsOnDeath( true )

		-- Hide some HUD elements
		mode:SetHUDVisible(DOTA_HUD_VISIBILITY_INVENTORY_SHOP, false)
		mode:SetHUDVisible( DOTA_HUD_VISIBILITY_SHOP_SUGGESTEDITEMS, false )
		mode:SetHUDVisible( DOTA_HUD_VISIBILITY_INVENTORY_QUICKBUY, false )
		mode:SetHUDVisible( DOTA_HUD_VISIBILITY_INVENTORY_COURIER, false )
		mode:SetHUDVisible( DOTA_HUD_VISIBILITY_INVENTORY_PROTECT, false )
		mode:SetHUDVisible( DOTA_HUD_VISIBILITY_INVENTORY_GOLD, false )

		self:OnFirstPlayerLoaded()
	end
end

-- This function is called 1 to 2 times as the player connects initially but before they
-- have completely connected
function DotaStrikers:PlayerConnect(keys)
	--print('[DOTASTRIKERS] PlayerConnect')
	--PrintTable(keys)

	if keys.bot == 1 then
		-- This user is a Bot, so add it to the bots table
		self.vBots[keys.userid] = 1
	end
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function DotaStrikers:OnConnectFull(keys)
	--print ('[DOTASTRIKERS] OnConnectFull')
	--PrintTable(keys)
	DotaStrikers:CaptureDotaStrikers()

	local entIndex = keys.index+1
	-- The Player entity of the joining user
	local ply = EntIndexToHScript(entIndex)

	-- The Player ID of the joining player
	local playerID = ply:GetPlayerID()

	-- Update the user ID table with this user
	self.vUserIds[keys.userid] = ply

	-- Update the Steam ID table
	self.vSteamIds[PlayerResource:GetSteamAccountID(playerID)] = ply

	-- If the player is a broadcaster flag it in the Broadcasters table
	if PlayerResource:IsBroadcaster(playerID) then
		self.vBroadcasters[keys.userid] = 1
		return
	end
end

-- This is an example console command
function DotaStrikers:ExampleConsoleCommand()
	--print( '******* Example Console Command ***************' )
	local cmdPlayer = Convars:GetCommandClient()
	if cmdPlayer then
		local playerID = cmdPlayer:GetPlayerID()
		if playerID ~= nil and playerID ~= -1 then
			-- Do something here for the player who called this command
			PlayerResource:ReplaceHeroWith(playerID, "npc_dota_hero_viper", 1000, 1000)
		end
	end
	--print( '*********************************************' )
end