print ('[DOTASTRIKERS] dotastrikers.lua' )

NEXT_FRAME = .01
Testing = true
--TestMoreAbilities = false
OutOfWorldVector = Vector(5000, 5000, -200)
DrawDebug = false
UseCursorStream = false

GROUND_FRICTION = .04
AIR_FRICTION = .02
BOUNCE_MULTIPLIER = 21
GRAVITY = -1700
BASE_ACCELERATION = Vector(0,0,GRAVITY)
BALL_COLLISION_DIST = 110

SURGE_TICK = .2

if not Testing then
  statcollection.addStats({
    modID = 'XXXXXXXXXXXXXXXXXXX'
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
	[1] = "Bob",
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
	--print("[DOTASTRIKERS] All Players have loaded into the game")
end

--[[
	This function is called once and only once when the game completely begins (about 0:00 on the clock).  At this point,
	gold will begin to go up in ticks if configured, creeps will spawn, towers will become damageable etc.  This function
	is useful for starting any game logic timers/thinkers, beginning the first round, etc.
]]
function DotaStrikers:OnGameInProgress()
	--print("[DOTASTRIKERS] The game has officially begun")

	Timers:CreateTimer(30, function() -- Start this timer 30 game-time seconds later
		--print("This function is called 30 seconds after the game begins, and every 30 seconds thereafter")
		return 30.0 -- Rerun this timer every 30 game-time seconds
	end)
end

function DotaStrikers:PlayerSay( keys )
	local ply = keys.ply
	local hero = ply:GetAssignedHero()
	local txt = keys.text

	if keys.teamOnly then
		-- This text was team-only.
	end

	if txt == nil or txt == "" then
		return
	end

  -- At this point we have valid text from a player.
	--print("P" .. ply .. " wrote: " .. keys.text)
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
				self.greetPlayers = true
			end

			self:OnPlayersHeroFirstSpawn(hero)
			ply.firstTime = true

		else
			self:OnPlayersHeroRespawn(hero)
		end
	end
end

function DotaStrikers:OnPlayersHeroFirstSpawn( hero )
	--print("OnPlayersHeroFirstSpawn")

	function hero:AddDirectionalInfluence(  )
		hero.lastMovespeedVect = hero:GetForwardVector()*hero:GetBaseMoveSpeed()
		hero:SetPhysicsVelocity(hero:GetPhysicsVelocity() + hero.lastMovespeedVect)
		hero.physics_directional_influence = true
	end

	function hero:OnThink(  )
		local heroPos = hero:GetAbsOrigin()
		--print("heroPos: " .. VectorString(heroPos))
		if hero.goalie then
			-- check if actually still in goal
			local corner1 = hero.gc.corners[1]
			local corner2 = hero.gc.corners[3]
			if heroPos.x > corner1.x or heroPos.x < corner2.x or heroPos.y > corner1.y or heroPos.y < corner2.y then
				--print("goalie left net.")
				hero.goalie = false
				hero.gc.goalie = nil
			end
		end
	end

	--local hero = ply:GetAssignedHero()
	hero.base_move_speed = hero:GetBaseMoveSpeed()
	hero.plyID = hero:GetPlayerID()
	hero.colHex = ColorHex[hero.plyID+1]
	hero.colStr = ColorStr[hero.plyID+1]
	-- Store the player's name inside this hero handle.
	hero.playerName = PlayerResource:GetPlayerName(hero.plyID)
	if hero.playerName == nil or hero.playerName == "" then
		hero.playerName = DummyNames[hero.plyID+1]
	end

	if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
		hero.gc = GoalColliders[1]
	else
		hero.gc = GoalColliders[2]
	end

	-- Store this hero handle in this table.
	table.insert(self.vHeroes, hero)
	self:ApplyDSPhysics(hero)

	hero.isDSHero = true
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
				if hero:GetClassname() ~= "npc_dota_hero_antimage" then
					hero:CastAbilityNoTarget(hero:FindAbilityByName("surge_break"), 0)
				else
					hero:CastAbilityNoTarget(hero:FindAbilityByName("surge_break_sprint"), 0)
					manaDrainInterval = SURGE_TICK*40
				end
			end
			hero:SetMana(currMana - manaDrainInterval)
		else
			if not (currMana >= maxMana) then
				hero:SetMana(currMana + manaGainInterval)

			end
		end

		return SURGE_TICK
	end)

	hero:OnPhysicsFrame(function(unit)
		DotaStrikers:OnMyPhysicsFrame(hero)

	end)

end

function DotaStrikers:ApplyDSPhysics( unit )
	Physics:Unit(unit)
	unit:Hibernate(false)
	unit:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
	unit:SetGroundBehavior(PHYSICS_GROUND_ABOVE)
	-- gravity
	unit:SetPhysicsAcceleration(BASE_ACCELERATION)
	unit.shieldParticles = {}
	unit.lastShieldParticleTime = GameRules:GetGameTime()
	unit.lastErrorPopupTime = GameRules:GetGameTime()
end

function DotaStrikers:OnMyPhysicsFrame( unit )
	local unitPos = unit:GetAbsOrigin()
	local currVel = unit:GetPhysicsVelocity()
	local fv = unit:GetForwardVector()
	local ball = Ball.unit
	local unitFriction = unit:GetPhysicsFriction()

	if unitPos.z > (GroundZ) and not unit.isAboveGround then
		unit.isAboveGround = true
		--print("unit.isAboveGround")
		-- if hero, set the modifier up
		if unit.isDSHero and not unit:HasModifier("modifier_rooted_passive") then
			GlobalDummy.rooted_passive:ApplyDataDrivenModifier(GlobalDummy, unit, "modifier_rooted_passive", {})
		end
		if not unit.dontChangeFriction then
			unit:SetPhysicsFriction(AIR_FRICTION)
		end
		unit.bounce_multiplier = BOUNCE_MULTIPLIER

	elseif unitPos.z <= (GroundZ) and unit.isAboveGround then
		-- bounce takes priority
		-- determine if bounce should occur.
		local bounceOccured = false
		local len3dSq = Length3DSq(currVel)
		--print("len3dSq: " .. len3dSq)
		if len3dSq > 200*200 and not unit.noBounce then
			currVel = Vector(currVel.x, currVel.y, -1*currVel.z*unit.bounce_multiplier)
			unit.bounce_multiplier = unit.bounce_multiplier*.8
			unit:SetPhysicsVelocity(currVel)
			bounceOccured = true
			--unit:SetPhysicsFriction(GROUND_FRICTION)
		end

		if unit.noBounce then
			unit.noBounce = false
		end

		if not bounceOccured then
			unit.isAboveGround = false
			--print("not unit.isAboveGround")
			-- if hero, remove the modifier
			if unit:HasModifier("modifier_rooted_passive") then
				unit:RemoveModifierByName("modifier_rooted_passive")
			end
			if not unit.dontChangeFriction then
				unit:SetPhysicsFriction(GROUND_FRICTION)
			end
		end
	end

	if unit.isDSHero then
		if unit.isUsingPull then
			-- it's imba is the puller already has the pull and she's using pull.
			if ball.controller ~= unit then
				local dirToBall = (Ball.unit:GetAbsOrigin() - unit:GetAbsOrigin()):Normalized()
				unit:SetPhysicsAcceleration(BASE_ACCELERATION + dirToBall*2500)
			end
		end
		if unit == ball.controller then
			ball:SetAbsOrigin(unit:GetAbsOrigin() + Vector(fv.x,fv.y,0)*(BALL_COLLISION_DIST-40))
			--print("setting ball fv.")
			ball:SetForwardVector(fv)
		end
	end

	-- do above ground think logic
	if unit.isAboveGround then
		if not unit.dontChangeFriction and unitFriction ~= AIR_FRICTION then
			unit:SetPhysicsFriction(AIR_FRICTION)
		end

	else
		if not unit.dontChangeFriction and unitFriction ~= GROUND_FRICTION then
			unit:SetPhysicsFriction(GROUND_FRICTION)
		end

	end


	--[[if unit.isAboveGround then
		if unit.isDSHero then
			if not unit.physics_directional_influence then
				unit.lastMovespeedVect = fv*unit:GetBaseMoveSpeed()
				unit:SetPhysicsVelocity(currVel + unit.lastMovespeedVect)
				unit.physics_directional_influence = true
			end
		end
	elseif not unit.isAboveGround then
		if unit.isDSHero then
			if unit.physics_directional_influence and not unit.isUsingPull then
				unit.physics_directional_influence = false
			end
		end
	end

	if unit.physics_directional_influence then
		local baseVel = currVel - unit.lastMovespeedVect
		unit.lastMovespeedVect = fv*unit:GetBaseMoveSpeed()
		unit:SetPhysicsVelocity(baseVel + unit.lastMovespeedVect)
	end]]

end

function DotaStrikers:OnPlayersHeroRespawn( hero )


end

function DotaStrikers:GreetPlayers(  )
	local lines = 
	{
		[1] = ColorIt("Welcome to ", "green") .. ColorIt("DotaStrikers! ", "magenta") .. ColorIt("v0.1", "blue"),
		[2] = ColorIt("Developer: ", "green") .. ColorIt("XXX", "orange")
	}

	Timers:CreateTimer(4, function()
		for i,line in ipairs(lines) do
			GameRules:SendCustomMessage(line, 0, 0)
		end
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
function DotaStrikers:OnAbilityUsed(keys)
	local player = EntIndexToHScript(keys.PlayerID)
	local abilityname = keys.abilityname
	local hero = player:GetAssignedHero()
	local ball = Ball.unit

	if abilityname == "slam" then
		local radius = hero:FindAbilityByName("slam"):GetCastRange()
		print("radius: " .. radius)
		for i, ent in ipairs(Entities:FindAllInSphere(hero:GetAbsOrigin(), radius)) do
			if IsPhysicsUnit(ent) then
				local dir = (ent:GetAbsOrigin()-hero:GetAbsOrigin()):Normalized()
				local dist = (ent:GetAbsOrigin()-hero:GetAbsOrigin()):Length()
				local knockbackScale = (radius-dist)/radius
				-- if it's the ball and ball has a controller, don't move the ball.
				-- if it's the slammer, don't move him
				if (ent == ball and ball.controller ~= nil) or ent == hero then

				else
					if ent.isDSHero and not ent:HasModifier("modifier_rooted_passive") then
						GlobalDummy.rooted_passive:ApplyDataDrivenModifier(GlobalDummy, ent, "modifier_rooted_passive", {})
					end
					ent:AddPhysicsVelocity((dir*1900 + Vector(0,0,1900)*knockbackScale))
				end
			end
		end
	end

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
		if killedUnit:GetTeam() == DOTA_TEAM_BADGUYS and killerEntity:GetTeam() == DOTA_TEAM_GOODGUYS then
			self.nRadiantKills = self.nRadiantKills + 1
			if END_GAME_ON_KILLS and self.nRadiantKills >= KILLS_TO_END_GAME_FOR_TEAM then
				GameRules:SetSafeToLeave( true )
				GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
			end
		elseif killedUnit:GetTeam() == DOTA_TEAM_GOODGUYS and killerEntity:GetTeam() == DOTA_TEAM_BADGUYS then
			self.nDireKills = self.nDireKills + 1
			if END_GAME_ON_KILLS and self.nDireKills >= KILLS_TO_END_GAME_FOR_TEAM then
				GameRules:SetSafeToLeave( true )
				GameRules:SetGameWinner( DOTA_TEAM_BADGUYS )
			end
		end

		if SHOW_KILLS_ON_TOPBAR then
			GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_BADGUYS, self.nDireKills )
			GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_GOODGUYS, self.nRadiantKills )
		end
	end

	-- Put code here to handle when an entity gets killed
end


-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
function DotaStrikers:InitDotaStrikers()
	DotaStrikers = self
	--print('[DOTASTRIKERS] Starting to load DotaStrikers gamemode...')

	-- Setup rules
	-- Setup rules
	GameRules:SetHeroRespawnEnabled( true )
	GameRules:SetUseUniversalShopMode( true )
	GameRules:SetSameHeroSelectionEnabled( true )
	GameRules:SetHeroSelectionTime( 1 )
	GameRules:SetPreGameTime( 0)
	GameRules:SetPostGameTime( 30 )
	GameRules:SetUseBaseGoldBountyOnHeroes(false)
	GameRules:SetHeroMinimapIconScale( 1.4 )
	GameRules:SetCreepMinimapIconScale( 1.7 )
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
	ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(DotaStrikers, 'OnAbilityUsed'), self)
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

	--[[self.runeTypes =
	{
		[1] = "Goo_Bomb",
		[2] = "Fiery_Jaw", 
		[3] = "Segment_Bomb",
		[4] = "Crypt_Craving",
		[5] = "Reverse",
	}]]

	GlobalDummy = CreateUnitByName("dummy", Vector(0,0,0), false, nil, nil, DOTA_TEAM_GOODGUYS)
	GlobalDummy.rooted_passive = GlobalDummy:FindAbilityByName("rooted_passive")
	print("GlobalDummy pos: " .. VectorString(GlobalDummy:GetAbsOrigin()))
	GroundZ = GlobalDummy:GetAbsOrigin().z

	Bounds = {min = -3000, max = 3000}

	Timers:CreateTimer(.06, function()
		DotaStrikers:InitMap()
	end)

	--[[Timers:CreateTimer(.06, function()
		DebugDrawBox(Vector(0,0,GlobalDummy.z), Vector(Bounds.min,Bounds.min,0), Vector(Bounds.max,Bounds.max,100), 255, 0, 0, 50, 99999)
	end)]]

	VisionDummies = {GoodGuys = {}, BadGuys = {}}
	local timeOffset = .03
	-- CREATE vision dummies
	local offset = 1800 --528
	for y=Bounds.max-500, Bounds.min, -1*offset do
		for x=Bounds.min+500, Bounds.max, offset do
			Timers:CreateTimer(timeOffset, function()
				--if GridNav:IsTraversable(Vector(x,y,GlobalDummy.z)) and not GridNav:IsBlocked(Vector(x,y,GlobalDummy.z)) then
				local goodguy = CreateUnitByName("vision_dummy", Vector(x,y,GlobalDummy.z), false, nil, nil, DOTA_TEAM_GOODGUYS)
				local badguy = CreateUnitByName("vision_dummy", Vector(x,y,GlobalDummy.z), false, nil, nil, DOTA_TEAM_BADGUYS)
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
	GameRules:SetCustomGameEndDelay( 0 )
	GameRules:SetCustomVictoryMessageDuration( 0 )

	self.HeroesKV = LoadKeyValues("scripts/npc/npc_heroes_custom.txt")
	--BASE_WORM_MOVE_SPEED = self.HeroesKV["worm"]["MovementSpeed"]

	-- Initialized tables for tracking state
	self.vUserIds = {}
	self.vSteamIds = {}
	self.vBots = {}
	self.vBroadcasters = {}

	self.vPlayers = {}
	self.vHeroes = {}
	self.vRadiant = {}
	self.vDire = {}

	self.nRadiantKills = 0
	self.nDireKills = 0

	self.bSeenWaitForPlayers = false

	Ball:Init()
	Referee:Init()

	-- Main thinker
	Timers:CreateTimer(function()
		for i,hero in ipairs(self.vHeroes) do
			hero:OnThink()
		end

		return NEXT_FRAME
	end)

end

mode = nil

-- This function is called as the first player loads and sets up the DotaStrikers parameters
function DotaStrikers:CaptureDotaStrikers()
	if mode == nil then
		mode = GameRules:GetGameModeEntity()
		mode:SetRecommendedItemsDisabled( true )
		mode:SetCameraDistanceOverride( 1400 )
		mode:SetBuybackEnabled( false )
		mode:SetTopBarTeamValuesOverride ( true )
		mode:SetTopBarTeamValuesVisible( false ) -- this needed for kill banners?
		--mode:SetFogOfWarDisabled(true)
		mode:SetGoldSoundDisabled( true )
		--mode:SetRemoveIllusionsOnDeath( true )

		-- Hide some HUD elements
		--mode:SetHUDVisible(0, false) --Clock

		--[[if not TestMoreAbilities then
			mode:SetHUDVisible(1, false)
			mode:SetHUDVisible(2, false)
			mode:SetHUDVisible(6, false)
			mode:SetHUDVisible(7, false) 
			mode:SetHUDVisible(8, false) 
			mode:SetHUDVisible(9, false)
			mode:SetHUDVisible(11, false)
			mode:SetHUDVisible(12, false)
			mode:SetHUDVisible(5, false) --Inventory
			Convars:SetInt("dota_render_crop_height", 0) -- Renders the bottom part of the screen
			Convars:SetInt("dota_draw_portrait", 0)
			mode:SetHUDVisible( DOTA_HUD_VISIBILITY_SHOP_SUGGESTEDITEMS, false )
		end]]

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

DotaStrikersHero = {}
-- pass in regular dota hero, make it a DS hero.
function DotaStrikersHero:Init(hero)
	local heroName = hero:GetUnitName()
	if heroName == "npc_dota_hero_antimage" then

	elseif heroName == "npc_dota_hero_spectre" then

	end
	--elseif heroName == ""

end

Ball = {}

function Ball:Init(  )
	Ball.unit = CreateUnitByName("ball", Vector(0,0,GroundZ), true, nil, nil, DOTA_TEAM_GOODGUYS)
	local ball = Ball.unit
	BALL = ball.unit
	ball.isBall = true

	function ball:IsBallOutOfBounds()
		local ballPos = ball:GetAbsOrigin()
		return ballPos.x > Bounds.max or ballPos.x < Bounds.min or ballPos.y > Bounds.max or ballPos.y < Bounds.min
	end

	function ball:InGoalPost(  )
		local ballPos = ball:GetAbsOrigin()
		local inGoalPost = true
		for i=1,2 do
			local gc = GoalColliders[i]
			local corner1 = gc.corners[1]
			local corner2 = gc.corners[3]
			if ballPos.x > corner1.x or ballPos.x < corner2.x or ballPos.y > corner1.y or ballPos.y < corner2.y then
				inGoalPost = false
			end
		end
		return inGoalPost
	end

	ball.controller = nil
	DotaStrikers:ApplyDSPhysics(ball)

	Timers:CreateTimer(1, function()
		if not ball.ballParticle then
			ball.ballParticle = ParticleManager:CreateParticle("particles/ball/espirit_rollingboulder.vpcf", PATTACH_ABSORIGIN_FOLLOW, ball)
		end
	end)

	ball:OnPhysicsFrame(function(unit)
		DotaStrikers:OnMyPhysicsFrame(ball)
		local ballPos = ball:GetAbsOrigin()
		for _,hero in ipairs(DotaStrikers.vHeroes) do
			-- TODO: do 3D collision
			local collision = (hero:GetAbsOrigin()-ball:GetAbsOrigin()):Length() <= BALL_COLLISION_DIST
			--if collision then print ("collision.") end
			if hero ~= ball.controller and collision then
				if not hero.ballProc then
					ball:SetPhysicsVelocity(Vector(0,0,0))
					if hero.isUsingPull then
						hero:CastAbilityNoTarget(hero.pull_break, 0)
					end
					print("new controller.")
					if ball.affectedByPowershot then
						ball.affectedByPowershot = false
						ball.dontChangeFriction = false
						hero:EmitSound("Hero_VengefulSpirit.MagicMissileImpact")
					else
						hero:EmitSound("Hero_Puck.ProjectileImpact")
					end

					if hero == Referee.unit then
						Referee.unit:MoveToTargetToAttack(ball)
					else
						ball.controller = hero
					end
					hero.ballProc = true
				end
			elseif hero ~= ball.controller and not collision then
				if hero.ballProc then
					hero.ballProc = false
				end
			elseif hero == ball.controller and not collision then
				--print("ball.controller is nil")
				ball.controller = nil
				hero.ballProc = false
			end
		end

		--[[if ball:InGoalPost() then
			ball.inGoalPost = true
		else
			ball.inGoalPost = false
		end]]

		--print("ball veL: " .. VectorString(ball:GetPhysicsVelocity()))

		if ball.controller ~= nil then
			-- handle when controller took the ball out of bounds
			local isBallOutOfBounds = ball:IsBallOutOfBounds()

			if isBallOutOfBounds and not ball.outOfBoundsProc then
				--Timers:RemoveTimer(ball.outOfBoundsTimer)
				ball.outOfBoundsTimer = Timers:CreateTimer(2, function()
					if not ball.outOfBoundsProc then return end
					print("Referee.unit:GetBallInBounds()")
					Referee.unit:GetBallInBounds()
				end)
				ball.outOfBoundsProc = true
			elseif not isBallOutOfBounds and ball.outOfBoundsProc then
				Timers:RemoveTimer(ball.outOfBoundsTimer)
				ball.outOfBoundsProc = false
			end

		else
			ball:SetForwardVector(ball:GetPhysicsVelocity():Normalized())
		end
	end)

	return ball
end

function DotaStrikers:InitMap()
	BoundsColliders = {}
	Corners = 
	{
		[1] = Vector(Bounds.max, Bounds.max, GroundZ),
		[2] = Vector(Bounds.min, Bounds.max, GroundZ),
		[3] = Vector(Bounds.min, Bounds.min, GroundZ),
		[4] = Vector(Bounds.max, Bounds.min, GroundZ),
	}

	local offset = 900
	local colliderZ = 2000
	for i=1,4 do
		BoundsColliders[i] = Physics:AddCollider("bounds_collider_" .. i, Physics:ColliderFromProfile("aaboxreflect"))
		local corner = Corners[i]
		local nextCorner = Corners[1]
		if i < 4 then
			nextCorner = Corners[i+1]
		end
		if i == 1 then
			corner = Vector(corner.x+offset, corner.y, corner.z)
			nextCorner = Vector(nextCorner.x-offset, nextCorner.y+offset,nextCorner.z+colliderZ)
		elseif i == 2 then
			corner = Vector(corner.x, corner.y+offset, corner.z)
			nextCorner = Vector(nextCorner.x-offset, nextCorner.y-offset,nextCorner.z+colliderZ)
		elseif i == 3 then
			corner = Vector(corner.x-offset, corner.y, corner.z)
			nextCorner = Vector(nextCorner.x+offset, nextCorner.y-offset,nextCorner.z+colliderZ)
		else
			corner = Vector(corner.x, corner.y-offset, corner.z)
			nextCorner = Vector(nextCorner.x+offset, nextCorner.y+offset, nextCorner.z+colliderZ)
		end

		BoundsColliders[i].box = {corner, nextCorner}

		BoundsColliders[i].test = function(self, unit)
			local passTest = false
			if unit.isBall and unit.controller == nil then
				print("passTest")
				passTest = true
			elseif unit.isBall and unit.controller ~= nil then
				--print("ball, controller not nil.")
			elseif unit.isDSHero then
				passTest = true
			end


			return passTest
		end
		BoundsColliders[i].draw = true
	end

	GoalColliders = {}
	GoalColliders[1] = Physics:AddCollider("goal_collider_" .. 1, Physics:ColliderFromProfile("aaboxreflect"))
	GoalColliders[2] = Physics:AddCollider("goal_collider_" .. 2, Physics:ColliderFromProfile("aaboxreflect"))

	local ball = Ball.unit
	GoalColliders[1].team = DOTA_TEAM_GOODGUYS
	GoalColliders[2].team = DOTA_TEAM_BADGUYS
	local gcOffset = 700
	GoalColliders[1].corners =
	{
		[1] = Vector(500, Bounds.max+gcOffset, 0),
		[2] = Vector(-500, Bounds.max+gcOffset, 0),
		[3] = Vector(-500, Bounds.max-gcOffset,colliderZ),
		[4] = Vector(500,Bounds.max-gcOffset,0),
	}
	GoalColliders[2].corners =
	{
		[1] = Vector(500, Bounds.min+gcOffset, 0),
		[2] = Vector(-500, Bounds.min+gcOffset, 0),
		[3] = Vector(-500, Bounds.min-gcOffset,colliderZ),
		[4] = Vector(500,Bounds.min-gcOffset,0),
	}

	for i=1,2 do
		local gc = GoalColliders[1]
		if i==2 then gc = GoalColliders[2] end
		gc.box = {gc.corners[1], gc.corners[3]}
		gc.test = function ( self, unit )
			if not IsPhysicsUnit(unit) then return false end
			if unit == gc.goalie then return false end -- ignore the current goalie in this goalpost.
			local passTest = false
			if unit ~= ball and gc.goalie then
				-- if the unit isn't the ball and there's a goalie in there, collision occurs.
				passTest = true
				if unit:GetPlayerOwner() ~= nil then
					--print("printing error.")
					if GameRules:GetGameTime()-unit.lastErrorPopupTime > 1 then
						FireGameEvent( 'custom_error_show', { player_ID = unit:GetPlayerOwner():GetPlayerID(), _error = "Your team already has a goalie" } )
						unit.lastErrorPopupTime = GameRules:GetGameTime()
					end
				end

				--ParticleManager:CreateParticle("particles/units/heroes/hero_medusa/medusa_mana_shield_impact.vpcf", PATTACH_ABSORIGIN, unit)

			elseif unit == ball then
				passTest = false
			elseif not gc.goalie and unit ~= ball and unit:GetTeamNumber() == gc.team then
				-- if there's nobody in the goal and the unit isn't the ball and he's on the same team as this goal post, then let the unit in.
				--print("new goalie in net.")
				gc.goalie = unit
				unit.goalie = true
				passTest = false
			else
				passTest = true
				-- people can't enter enemy goal posts.
				if unit:GetTeamNumber() ~= gc.team then
					if GameRules:GetGameTime()-unit.lastErrorPopupTime > 1 then
						FireGameEvent( 'custom_error_show', { player_ID = unit:GetPlayerOwner():GetPlayerID(), _error = "Can't enter enemy goal post" } )
						unit.lastErrorPopupTime = GameRules:GetGameTime()
					end
				end
				
			end
			if passTest then
				local currTime = GameRules:GetGameTime()
				if currTime-unit.lastShieldParticleTime > .1 then
					--unit.shieldParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_lich/lich_frost_nova_sphere_1.vpcf", PATTACH_CUSTOMORIGIN, unit)
					unit.shieldParticle = ParticleManager:CreateParticle("particles/items_fx/immunity_sphere_buff.vpcf", PATTACH_CUSTOMORIGIN, unit)
					--unit.shieldParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_medusa/medusa_mana_shield_shell_add.vpcf", PATTACH_CUSTOMORIGIN, unit)
					ParticleManager:SetParticleControl(unit.shieldParticle, 0, unit:GetAbsOrigin() + unit:GetForwardVector()*40)
					
					table.insert(unit.shieldParticles, unit.shieldParticle)
					--print("shieldtable: " .. #unit.shieldParticles)
					Timers:CreateTimer(.3, function()
						ParticleManager:DestroyParticle(unit.shieldParticles[1], true)
						table.remove(unit.shieldParticles, 1)
					end)
					unit.lastShieldParticleTime = currTime
				end
			end

			return passTest
		end
		gc.draw = true
	end
end

Referee = {}

function Referee:Init(  )
	Referee.unit = CreateUnitByName("npc_dota_hero_omniknight", Vector(4000,4000,0), true, nil, nil, Ball.unit:GetOpposingTeamNumber())
	local referee = Referee.unit
	--table.insert(DotaStrikers.vHeroes, referee)

	function referee:GetBallInBounds(  )
		local ball = Ball.unit
		local towardsCenter = (Vector(0,0,GroundZ)-ball:GetAbsOrigin()):Normalized()
		local backOfBall = -400*towardsCenter + ball:GetAbsOrigin()
		referee:SetAbsOrigin(backOfBall)

	end

	function referee:TakeBallFromGoalie(  )
		
	end

	function referee:OnThink(  )
		-- snap
	end

	Timers:CreateTimer(.04, function()
		if not Referee.firstTime then
			referee:FindAbilityByName("referee_passive"):SetLevel(1)

			Referee.firstTime = true
		end
		referee:OnThink()

		return .01
	end)
end

--[[function DotaStrikers:ThinkAbilities()
	--[[if not RoundInProgress then
		return
	end
	for _,hero in pairs(self.vHeroes) do
		if hero.phaseOn then
			-- Check if out of mana.
			if hero:GetMana() <= 1.0 then
				hero:CastAbilityImmediately(hero:FindAbilityByName("phase_off"), 0)
			else
				-- Drain a small percentage of mana
				hero:SetMana(hero:GetMana()-(hero:GetMaxMana()*.01))
			end
		end
	end
end]]
