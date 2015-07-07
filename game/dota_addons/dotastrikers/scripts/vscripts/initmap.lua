TIME_TILL_NEXT_ROUND = 9

RECT_X_MAX = 2585.02
RECT_X_MIN = -1*RECT_X_MAX
GC_INCREASE_SIDE = 20 -- increases the y-length of the goal collider. 
COLLIDER_Z = 15000

GOAL_Y = 415 -- half of the y direction width of the goal post.
-- RADIANT MAP VALUES:
R_OUTWARDNESS = -2028
--R_INWARDNESS = -3268
R_SCORE = -2837.82
BIG_OFFSET = 16000

-- Apparently z-level you see in Hammer isn't the same as the z-level in game.
-- 1st num is the ground level in-game. 2nd num is z level of goal post in hammer. third num is base z-level in hammer. fourth is my custom offset
GOAL_Z = 256+(465-128-20)

D_OUTWARDNESS = -1*R_OUTWARDNESS
D_SCORE = -1*R_SCORE

function DotaStrikers:InitMap()
	local ball = Ball.unit

	self.bcs = {
		[1] = Physics:AddCollider("bounds_collider_1", Physics:ColliderFromProfile("aaboxreflect")),
		[2] = Physics:AddCollider("bounds_collider_2", Physics:ColliderFromProfile("aaboxreflect")),
		[3] = Physics:AddCollider("bounds_collider_3", Physics:ColliderFromProfile("aaboxreflect")),
	}
	local bcs = self.bcs

	-- the top of everything
	bcs[1].box = {Vector(BIG_OFFSET, BIG_OFFSET, BIG_OFFSET-3000), Vector(-1*BIG_OFFSET, -1*BIG_OFFSET, BIG_OFFSET+3000)}

	-- top of radiant goal post, ball reflector
	bcs[2].box = {Vector(-1*BIG_OFFSET, GOAL_Y*-1-BIG_OFFSET, GOAL_Z), Vector(R_SCORE+10, GOAL_Y+BIG_OFFSET, BIG_OFFSET)}
	--bcs[2].draw = true

	-- top of dire goal post, ball reflector
	bcs[3].box = {Vector(BIG_OFFSET, GOAL_Y*-1-BIG_OFFSET, GOAL_Z), Vector(D_SCORE-10, GOAL_Y+BIG_OFFSET, BIG_OFFSET)}
	--bcs[3].draw = true

	for i,bc in ipairs(bcs) do
		bc.test = function(self, unit)
			return OnBoundsCollision(self, unit, bc)
		end
		bc.filter = DotaStrikers.colliderFilter
	end

	self.gcs = {
		[1] = Physics:AddCollider("goal_collider_1", Physics:ColliderFromProfile("aaboxreflect")),
		[2] = Physics:AddCollider("goal_collider_2", Physics:ColliderFromProfile("aaboxreflect"))
	}

	local gcs = self.gcs

	gcs[1].box = {Vector(R_OUTWARDNESS, -1*GOAL_Y, 0), Vector(-1*BIG_OFFSET, GOAL_Y, BIG_OFFSET)}
	gcs[2].box = {Vector(D_OUTWARDNESS, -1*GOAL_Y, 0), Vector(BIG_OFFSET, GOAL_Y, BIG_OFFSET)}
	gcs[1].team = DOTA_TEAM_GOODGUYS
	gcs[2].team = DOTA_TEAM_BADGUYS
	--gcs[1].draw=true
	--gcs[2].draw=true

	for _,gc in ipairs(gcs) do
		gc.test = function ( self, unit )
			if not IsPhysicsUnit(unit) then return false end

			if TryWaitComponent(unit) then return true end

			if unit == gc.goalie then return false end -- ignore the current goalie in this goalpost.

			-- swapdummy doesn't care if there's a goalie or not.
			if unit.isSwapDummy and unit:GetTeam() ~= gc.team then
				return true
			elseif unit.isSwapDummy then
				return false
			end

			local passTest = false
			if unit ~= ball and gc.goalie then
				-- if the unit isn't the ball and there's a goalie in there, collision occurs.
				passTest = true
				if unit:GetTeamNumber() == gc.team then
					ShowErrorMsg(unit, "#already_has_goalie")
				else
					ShowErrorMsg(unit, "#cant_enter_enemy_goal_post")
				end
			elseif unit == ball then
				passTest = false
			elseif unit.isDSHero and not gc.goalie and unit:GetTeamNumber() == gc.team then
				-- if there's nobody in the goal and the unit isn't the ball and he's on the same team as this goal post, then let the unit in.
				--print("new goalie")
				gc.goalie = unit
				unit.goalie = true
				unit.timeBecameGoalie = GameRules:GetGameTime()
				passTest = false
			else
				passTest = true
				-- people can't enter enemy goal posts.
				if unit:GetTeamNumber() ~= gc.team then
					--print("cant enter")
					ShowErrorMsg(unit, "#cant_enter_enemy_goal_post")
				end
				
			end
			-- done with calculating passTest value.
			if passTest then
				DotaStrikers:PlayReflectParticle(unit)
				-- if high velocity onto the goal post, do sounds/effects etc.
				if unit.isDSHero then
					TryPlayCracks(unit)
				end
			end
			TryWaitComponent(unit)

			return passTest
		end
		--gc.draw=true
		gc.filter = DotaStrikers.colliderFilter
	end
end

function DotaStrikers:AddGoalieJump(unit)
	if not RoundInProgress then return end

	-- he can't have goalie jump while having the ball
	if Ball.unit.controller == unit or not unit.goalie then return end

	if not unit:HasAbility("goalie_jump") then
		if unit:HasAbility("dotastrikers_empty5") then
			unit:RemoveAbility("dotastrikers_empty5")
		end

		Timers:CreateTimer(.03, function()
			if not unit:HasAbility("goalie_jump") then
				unit:AddAbility("goalie_jump")
				unit:FindAbilityByName("goalie_jump"):SetLevel(1)
			end
		end)
	end

end

function DotaStrikers:RemoveGoalieJump(unit)
	if unit:HasAbility("goalie_jump") then
		unit:RemoveAbility("goalie_jump")

		Timers:CreateTimer(.03, function()
			if not unit:HasAbility("dotastrikers_empty5") then
				unit:AddAbility("dotastrikers_empty5")
				unit:FindAbilityByName("dotastrikers_empty5"):SetLevel(1)
			end
		end)
	end
end

-- TODO: in the future prolly should have a class for a Team. ex. logo, color, players, etc in the far future.
function DotaStrikers:OnGoal(team)
	local currTime = GameRules:GetGameTime()
	if currTime-DotaStrikers.lastGoalTime < TIME_TILL_NEXT_ROUND then
		return
	end
	DotaStrikers.lastGoalTime = currTime

	print("OnGoal")

	RoundOver = true

	local ball = Ball.unit

	local scorer = ball.lastMovedBy

	-- Retrieve winning and losing teams.
	local nWinningTeam = DOTA_TEAM_BADGUYS
	local nLosingTeam = DOTA_TEAM_GOODGUYS
	if team == "Radiant" then
		nWinningTeam = DOTA_TEAM_GOODGUYS
		nLosingTeam = DOTA_TEAM_BADGUYS
	end

	PlayVictoryAndDeathAnimations(nWinningTeam)

	if scorer:GetTeam() == nWinningTeam then
		scorer.scoredParticle = ParticleManager:CreateParticle("particles/scored_txt/tusk_rubickpunch_txt.vpcf", PATTACH_ABSORIGIN_FOLLOW, scorer)
		ParticleManager:SetParticleControlEnt(scorer.scoredParticle, 4, scorer, 4, "follow_origin", scorer:GetAbsOrigin(), true)
		--ParticleManager:SetParticleControl( scorer.scoredParticle, 2, scorer:GetAbsOrigin() )

		local part = ParticleManager:CreateParticle("particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_chakra_magic.vpcf", PATTACH_OVERHEAD_FOLLOW, scorer)
		ParticleManager:SetParticleControlEnt(part, 1, scorer, 1, "follow_origin", scorer:GetAbsOrigin(), true)

		scorer.highlightP = ParticleManager:CreateParticle("particles/econ/courier/courier_trail_05/courier_trail_05.vpcf", PATTACH_ABSORIGIN_FOLLOW, scorer)

		EmitGlobalSound("Round_End" .. RandomInt(1, NUM_ROUNDEND_SOUNDS))

		scorer.goalsAgainst = scorer.goalsAgainst + 1
	else
		EmitGlobalSound("Fail" .. RandomInt(1, NUM_FAIL_SOUNDS))

		scorer.goalsAgainst = scorer.goalsAgainst - 1
	end


	ball.dontChangeFriction = true

	-- Slow the ball down a lot
	ball:SetPhysicsFriction(GROUND_FRICTION*3)

	--local win_ball_pos = ball:GetAbsOrigin()
	Timers:CreateTimer(.06, function()
		local win_ball_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_templar_assassin/templar_assassin_trap_explode.vpcf", PATTACH_ABSORIGIN, ball.particleDummy)
		EmitSoundAtPosition("Hero_TemplarAssassin.Trap.Explode", ball:GetAbsOrigin())
	end)

	CleanUp(ball)

	-- force activate the break abil if hero has it.
	for _,hero in ipairs(DotaStrikers.vHeroes) do
		local surge_break = hero:GetAbilityByIndex(2)
		local abilName = surge_break:GetAbilityName()
		if string.ends(abilName, "break") then
			hero:CastAbilityNoTarget(surge_break, 0)
		end

		AddEndgameRoot(hero)

		if hero:GetTeam() ~= nWinningTeam then
			GlobalDummy.dummy_passive:ApplyDataDrivenModifier(GlobalDummy, hero, "modifier_defeat_anim", {})

			if hero.goalie then
				print("goalie didn't save.")
				hero.non_saves = hero.non_saves + 1

			end

		else
			ParticleManager:CreateParticle("particles/legion_duel_victory/legion_commander_duel_victory.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
			GlobalDummy.dummy_passive:ApplyDataDrivenModifier(GlobalDummy, hero, "modifier_victory_anim", {})
		end

		--ball:AddNewModifier(hero, nil, "modifier_camera_follow", {})

	end

	-- Allot time for the break ability to execute.
	Timers:CreateTimer(.06, function()
		for _,hero in ipairs(DotaStrikers.vHeroes) do
			CleanUp(hero)
			AddSilence(hero)
		end
	end)

	-- Check if game over.
	local winningTeamCol = "green"
	if nWinningTeam == DOTA_TEAM_BADGUYS then
		winningTeamCol = "red"
		self.direScore = self.direScore + 1
		GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_BADGUYS, self.direScore )
		if self.direScore >= SCORE_TO_WIN then
			DotaStrikers:OnWonGame(DOTA_TEAM_BADGUYS)
			GameOver = true
		end
	else
		self.radiantScore = self.radiantScore + 1
		GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_GOODGUYS, self.radiantScore )
		if self.radiantScore >= SCORE_TO_WIN then
			DotaStrikers:OnWonGame(DOTA_TEAM_GOODGUYS)
			GameOver = true
		end
	end

	local lines = {
		[1] = ColorIt(scorer.playerName, scorer.colStr) .. " scored for the " .. ColorIt(team, winningTeamCol) .. "!!!"

	}

	ShowQuickMessages(lines, .2)

	RoundsCompleted = RoundsCompleted + 1

	RoundInProgress = false

	if GameOver then
		return
	end

	local start = 3
	ShowCenterMsg(scorer.playerName .. " SCORED!", TIME_TILL_NEXT_ROUND-start )
	local roundCountdownSet = RandomInt(1, #RoundCountdownSounds)
	local numCountdownSounds = RoundCountdownSounds[roundCountdownSet]

	for i=start,1,-1 do
		Timers:CreateTimer(TIME_TILL_NEXT_ROUND-i, function()
			if i == start then
				for _,hero in ipairs(DotaStrikers.vHeroes) do
					--[[if hero.goalie then
						DotaStrikers:RemoveGoalieJump(hero)
					end]]

					if hero:HasModifier("modifier_flail_passive") then
						hero:RemoveModifierByName("modifier_flail_passive")
					end

					AddEndgameRoot(hero)

					if hero:HasModifier("modifier_victory_anim") then
						hero:RemoveModifierByName("modifier_victory_anim")
					elseif hero:HasModifier("modifier_defeat_anim") then
						hero:RemoveModifierByName("modifier_defeat_anim")
					end

					-- NOTE: make sure to do all physics stuff BEFORE StopPhysicsSimulation or AFTER StartPhysicsSimulation.
					hero.dontChangeFriction = false

					hero:SetPhysicsFriction(GROUND_FRICTION)

					hero:StopPhysicsSimulation()

					if ball.netParticle then
						ParticleManager:DestroyParticle(ball.netParticle, false)
						ball.netParticle = nil
					end

					-- return heroes back to their spawn positions.
					hero:SetAbsOrigin(Vector(hero.spawn_pos.x, hero.spawn_pos.y, GroundZ))

					ParticleManager:CreateParticle("particles/econ/events/ti4/blink_dagger_end_ti4.vpcf", PATTACH_ABSORIGIN, hero)

					if scorer.highlightP then
						ParticleManager:DestroyParticle(scorer.highlightP, false)
						scorer.highlightP = nil
					end

					-- make them all face the ball (looks nicer)
					Timers:CreateTimer(.03, function()
						hero:SetForwardVector((ball:GetAbsOrigin()-hero:GetAbsOrigin()):Normalized())

						hero:SetMana(hero:GetMaxMana())

						Timers:CreateTimer(.03, function()
							hero:AddNewModifier(ball, nil, "modifier_camera_follow", {})
							PlayAnimation("act_dota_spawn", hero)
						end)
					end)
				end

				-- play some particle on the ball
				ParticleManager:CreateParticle("particles/econ/events/ti5/blink_dagger_end_ti5.vpcf", PATTACH_ABSORIGIN, ball.particleDummy)

				ball.controller = nil

				ball.dontChangeFriction = false

				ball:SetPhysicsFriction(GROUND_FRICTION)

				--ball:SetAbsOrigin(Vector(0,0,GroundZ))
				FindClearSpaceForUnit(ball, Vector(0,0,0), false)

				Timers:CreateTimer(.03, function()
					ball:StopPhysicsSimulation()
				end)
			end
			EmitGlobalSound("RoundCountdown" .. roundCountdownSet .. "_" .. RandomInt(1, numCountdownSounds))
			Say(nil, i .. "...", false)
		end)
	end

	Timers:CreateTimer(TIME_TILL_NEXT_ROUND, function()
		for _,hero in ipairs(DotaStrikers.vHeroes) do
			RemoveEndgameRoot(hero)

			RemoveSilence(hero)

			hero:StartPhysicsSimulation()

			hero:SetPhysicsAcceleration(BASE_ACCELERATION)

			hero:SetPhysicsVelocity(Vector(0,0,0))
		end

		ball:StartPhysicsSimulation()

		ball:SetPhysicsAcceleration(BASE_ACCELERATION)

		local ballVel = ball:GetAbsOrigin() + RandomVector(RandomInt(BALL_ROUNDSTART_KICK[1], BALL_ROUNDSTART_KICK[2]))

		ball:SetPhysicsVelocity(ballVel)

		ball:SetFV(ballVel:Normalized())

		RoundInProgress = true

		Say(nil, "PLAY!!", false)

		local roundStartSound = "Round_Start" .. RandomInt(1, NumRoundStartSounds)

		EmitGlobalSound(roundStartSound)

		-- make all creeps cheer
		PlayVictoryAndDeathAnimations(DOTA_TEAM_GOODGUYS, true)
		--print("playing " .. roundStartSound)
	end)
end

function DotaStrikers:OnWonGame( nWinningTeam )
	local shutout = false
	local sWinningTeam = "Radiant"
	if nWinningTeam == DOTA_TEAM_BADGUYS then
		sWinningTeam = "Dire"
		if self.radiantScore == 0 then
			shutout = true
		end
	else
		if self.direScore == 0 then
			shutout = true
		end
	end
	ShowCenterMsg(sWinningTeam .. " WINS!", 4 )

	-- TODO:
	--[[for _,hero in pairs(self.vHeroes) do
		-- inc games won for player.
	end]]
	FireGameEvent("game_over", {})

	GameRules:SetPostGameTime( 60 )
	GameRules:SetSafeToLeave( true )

	Timers:CreateTimer(function()
		GameRules:SetGameWinner( nWinningTeam )
	end)
	-- TODO: show popup with elo rating change

end

--[[function DotaStrikers:GetTeamName( team )
	if team == DOTA_TEAM_GOODGUYS then
end]]

function CleanUp( unit )
	if unit.isDSHero then
		local hero = unit
		if hero.isUsingPull then
			if hero:HasAbility("pull_break") then
				hero:CastAbilityImmediately(hero:FindAbilityByName("pull_break"), 0)
			end
		end
	elseif unit.isBall then
		local ball = Ball.unit
		if ball.affectedByPowershot then
			ball.affectedByPowershot = false
			ParticleManager:DestroyParticle(ball.powershot_particle, false)
			ball.affectedByPowershot = false
		end
	end
end

function GetGoalUnitIsWithin( unit )
	local pos = unit:GetAbsOrigin()

	local goal_neg = -1*GOAL_Y-GC_INCREASE_SIDE
	local goal_pos = GOAL_Y+GC_INCREASE_SIDE

	if pos.x < R_OUTWARDNESS and (pos.y > goal_neg and pos.y < goal_pos) then
		return DOTA_TEAM_GOODGUYS
	elseif pos.x > D_OUTWARDNESS and (pos.y > goal_neg and pos.y < goal_pos) then
		return DOTA_TEAM_BADGUYS
	end
	return nil
end

function OnBoundsCollision( self, unit, bc )
	if not IsPhysicsUnit(unit) then return false end

	if TryWaitComponent(unit) then return true end

	local ball = Ball.unit

	local isBall = unit == ball

	local passTest = true

	local unitPos = unit:GetAbsOrigin()
	
	--print(bc.name)
	--print(VectorString(unitPos))

	-- top of radiant, top of dire goals
	if bc.name == "bounds_collider_2" or bc.name == "bounds_collider_3" then
		if unit.goalie then
			return false
		end
	end

	-- when someone is holding the ball
	if isBall and ball.controller then
		return false
	end

	-- done with passTest logic. move onto parsing that logic, add sounds, effects, etc.
	if passTest then
		if isBall and not ball.affectedByPowershot then
			unit:EmitSound("Bounce" .. RandomInt(1, NUM_BOUNCE_SOUNDS))
		elseif unit.isDSHero then
			TryPlayCracks(unit, nil, true)
		end
		if unit.isAboveGround then
			DotaStrikers:PlayReflectParticle(unit)
		end
	else

	end

	TrySignalComponents(passTest, unit)

	return passTest
end

function DotaStrikers:PlayReflectParticle( unit )
	local currTime = GameRules:GetGameTime()
	if not unit.lastShieldParticleTime or currTime-unit.lastShieldParticleTime > .03 then
		local pos = unit:GetAbsOrigin()
		local fv = unit:GetForwardVector()
		unit.shieldParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_medusa/medusa_mana_shield_impact_highlight01.vpcf", PATTACH_CUSTOMORIGIN, unit)
		ParticleManager:SetParticleControl(unit.shieldParticle, 0, Vector(pos.x,pos.y,pos.z-70) + Vector(fv.x,fv.y,0)*40)
		unit.lastShieldParticleTime = currTime
	end
end

function PlayAnimation( name, unit )
    unit:AddAbility(name)
    local anim = unit:FindAbilityByName(name)
    anim:SetLevel(1)
    -- waiting a frame may be necessary, to prevent a crash, but feel free to try without the timer.
    Timers:CreateTimer(.03, function()
        unit:CastAbilityNoTarget(anim, 0)
        -- need to wait a frame here, i checked and some animations won't play if the abil is removed right away.
        Timers:CreateTimer(.03, function()
            unit:RemoveAbility(name)
        end)
    end)    
end

function DotaStrikers:InitCreeps(  )
	CreepSpecs = {[1] = "rs", [2] = "ds", [3] = "ns", [4] = "brew"}

	for i,spec_team in ipairs(CreepSpecs) do
		CreepSpecs[spec_team] = {}
		local spec_team_table = CreepSpecs[spec_team]
		local ptr = 1
		local t = Entities:FindAllByName(spec_team .. ptr .. "*")
		--ptr = ptr + 1
		while t and #t > 0 do
			spec_team_table[ptr] = {}
			for i2,ent in ipairs(t) do
				spec_team_table[ptr][i2] = ent
				--print("adding " .. ent:GetName() .. " to " .. spec_team .. " " .. ptr .. " " .. i2)
				InitCreepSpec(ent)
			end
			ptr = ptr + 1
			t = Entities:FindAllByName(spec_team .. ptr .. "*")
		end
	end
	--DeepPrintTable(CreepSpecs)
end

function InitCreepSpec( creep )
	if creep.GetUnitName then
		--print(creep:GetUnitName() .. " success")
		ClearAbilities( creep )
		GlobalDummy.dummy_passive:ApplyDataDrivenModifier(GlobalDummy, creep, "modifier_creep_spectator", {})
		AddDisarmed( creep )
		AddEndgameRoot(creep)
		creep.isCreepSpectator = true
		creep:SetAbsOrigin(GetGroundPosition(creep:GetAbsOrigin(), creep))

		if string.starts(creep:GetName(), "brew") then
			Timers:CreateTimer(RandomFloat(5, 20), function()
				local anim = "act_dota_spawn"
				--[[if RandomInt(1, 100) <= 25 then
					anim = "act_dota_cast_ability_1"
				end]]

				PlayAnimation(anim, creep)

				return RandomFloat(5, 20)
			end)
		end
	end
end

function PlayVictoryAndDeathAnimations( ... )
	local t = {...}
	local nWinningTeam = t[1]
	local victory_only = t[2]
	local this_team_only = t[3]

	local winning_creep_group = "ds"
	local losing_creep_group = "rs"
	if nWinningTeam == DOTA_TEAM_GOODGUYS then
		winning_creep_group = "rs"
		losing_creep_group = "ds"
	end

	for i, creep_group in ipairs(CreepSpecs[winning_creep_group]) do
		for i2,creep in ipairs(creep_group) do
			PlayAnimation("act_dota_victory", creep)
		end
	end

	if not this_team_only then
		for i, creep_group in ipairs(CreepSpecs[losing_creep_group]) do
			for i2,creep in ipairs(creep_group) do
				local defeatAnim = "act_dota_defeat"
				if RandomInt(1, 100) <= 25 then
					defeatAnim = "act_dota_die"
				end
				if victory_only then
					defeatAnim = "act_dota_victory"
				end
				PlayAnimation(defeatAnim, creep)
			end
		end
	end
end

function SetupStats( hero )
	hero.goalsAgainst = 0
	hero.numAssists = 0
	hero.numSaves = 0
	hero.numPasses = 0
	hero.pickups = 0
	hero.non_saves = 0
	hero.time_as_goalie = 0
	hero.shotsAgainst = 0
	hero.passesReceived = 0
	hero.steals = 0
	hero.turnovers = 0
	hero.possession_time = 0

	--[[if Testing then
		hero.goalsAgainst = RandomInt(1,5)
		hero.numAssists = RandomInt(1,6)
		hero.numSaves = RandomInt(1,5)
		hero.numPasses = RandomInt(5,15)
		hero.pickups = RandomInt(5,15)
		hero.non_saves = RandomInt(1,5)
		hero.time_as_goalie = RandomFloat(0, 400)
		hero.shotsAgainst = RandomInt(3, 15)
		hero.passesReceived = RandomInt(5, 15)
		hero.steals = RandomInt(2, 10)
		hero.turnovers = RandomInt(2, 10)
		hero.possession_time = RandomFloat(40, 400)
	end]]

end

function SummonTornado(  )
	local ball = Ball.unit
	--particles/tornado/tornado_ambient.vpcf
	local offset = 90
	local x = RandomFloat(RECT_X_MIN+offset, RECT_X_MAX-offset)
	local y = RandomFloat(Bounds.min+offset, Bounds.max-offset)

	local tornadoDummy = CreateUnitByName("dummy", Vector(x,y,GroundZ+1), true, nil, nil, DOTA_TEAM_NEUTRALS)
	tornadoDummy.isTornadoDummy = true
	tornadoDummy.tornado_particle = ParticleManager:CreateParticle("particles/tornado/tornado_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, tornadoDummy)
	EmitGlobalSound("n_creep_Wildkin.SummonTornado")

	tornadoDummy:SetBaseMoveSpeed(400)
	tornadoDummy.duration = RandomFloat(30, 90)
	tornadoDummy.end_time = GameRules:GetGameTime() + tornadoDummy.duration
	tornadoDummy.next_move_time = GameRules:GetGameTime() + RandomFloat(.4, 4)
	local id = DoUniqueString("id")
	tornadoDummy.tornado_id = id
	tornadoDummy.targets = {}
	--GlobalDummy.dummy_passive:ApplyDataDrivenModifier(GlobalDummy, tornadoDummy, "modifier_flying_on", {})

	for k,unit in pairs(DotaStrikers.colliderFilter) do
		if unit.isDSHero or unit == ball then
			unit.last_tornado_vels[id] = Vector(0,0,0)
			unit.next_tornado_update_time = GameRules:GetGameTime() + .04
		end
	end

	Timers:CreateTimer(.03, function()
		tornadoDummy:SetControllableByPlayer(0, true)
		-- play loop
		tornadoDummy:EmitSound("n_creep_Wildkin.Tornado")
		tornadoDummy:MoveToPosition(tornadoDummy:GetAbsOrigin() + RandomVector(1000))
	end)


	Timers:CreateTimer(.03, function()
		local currTime = GameRules:GetGameTime()
		local pos = tornadoDummy:GetAbsOrigin()
		if currTime > tornadoDummy.end_time or not IsValidEntity(tornadoDummy) or not tornadoDummy:IsAlive() then
			tornadoDummy:StopSound("n_creep_Wildkin.Tornado")
			if tornadoDummy:IsAlive() then
				tornadoDummy:ForceKill(true)
			end
			ParticleManager:DestroyParticle(tornadoDummy.tornado_particle, false)
			tornadoDummy.isTornadoDummy = false

			for k,unit in pairs(DotaStrikers.colliderFilter) do
				if unit.isDSHero or unit == ball then
					local lastVel = unit.last_tornado_vels[id]-unit.last_tornado_vels[id]*unit:GetPhysicsFriction()+unit:GetPhysicsAcceleration()/30
					unit:SetPhysicsVelocity(unit:GetPhysicsVelocity()-lastVel)
					unit.last_tornado_vels[id] = nil
				end
			end

			return
		end

		if currTime > tornadoDummy.next_move_time then
			tornadoDummy:MoveToPosition(pos + RandomVector(1000))

			tornadoDummy.next_move_time = currTime + RandomFloat(.4, 5)
		end

		if tornadoDummy:IsIdle() then
			local x = RandomFloat(RECT_X_MIN+offset, RECT_X_MAX-offset)
			local y = RandomFloat(Bounds.min+offset, Bounds.max-offset)
			tornadoDummy:MoveToPosition(pos + Vector(x,y,GroundZ+1))
		end

		-- do physics
		for k,unit in pairs(DotaStrikers.colliderFilter) do
			if unit.isDSHero or unit == ball then
				local hero = unit
				local p2 = tornadoDummy:GetAbsOrigin()
				local p1 = hero:GetAbsOrigin()
				local pID = 20 -- 20 is the ball
				if hero ~= ball then
					pID = hero:GetPlayerID()
				end

				-- make it easier for tornado to pickup ground units.

				local len2d = (Vector(p2.x,p2.y,0)-Vector(p1.x,p1.y,0)):Length()
				if len2d <= TORNADO_RADIUS and p1.z < TORNADO_MAX_HEIGHT then
					local force = (len2d/TORNADO_RADIUS)*TORNADO_FORCE
					if force < TORNADO_FORCE*.7 then
						force = TORNADO_FORCE*.7
					end

					if not unit.last_tornado_vels[id] then
						unit.last_tornado_vels[id] = Vector(0,0,0)
					end

					local rand = RandomVector(TORNADO_RADIUS*.4)
					local newP2 = p2+rand
					local dir = (Vector(newP2.x, newP2.y, RandomFloat(p2.z+100, p2.z+700))-p1):Normalized()
					local newForce = dir*force
					local lastVel = hero.last_tornado_vels[id]-hero.last_tornado_vels[id]*hero:GetPhysicsFriction()+hero:GetPhysicsAcceleration()/30
					local newVel = hero:GetPhysicsVelocity()-lastVel+newForce
					hero:SetPhysicsVelocity(newVel)
					hero.last_tornado_vels[id] = newForce

				else
					if hero.last_tornado_vels[id] ~= Vector(0,0,0) then
						local lastVel = hero.last_tornado_vels[id]-hero.last_tornado_vels[id]*hero:GetPhysicsFriction()+hero:GetPhysicsAcceleration()/30
						hero.last_tornado_vels[id] = Vector(0,0,0)
						hero:SetPhysicsVelocity(hero:GetPhysicsVelocity()-lastVel)
					end
				end
			end
		end


		return .01
	end)

	-- send notification
	local lines = {
		[1] = ColorIt("WARNING!", "red") ..  " a " .. ColorIt("TORNADO", "purple") .. " has entered the field!",
	}
	ShowQuickMessages(lines, .2)

end

function DotaStrikers:InitScoreboard(  )
	if ScoreboardTimer then return end

	ScoreboardTimer = Timers:CreateTimer(.5, function()
		for _,hero in pairs(DotaStrikers.vHeroes) do
			local pID = hero:GetPlayerID()
			FireGameEvent("update_scoreboard_value", {player_ID=pID, key="goals",value=hero.goalsAgainst})
			FireGameEvent("update_scoreboard_value", {player_ID=pID, key="assists",value=hero.numAssists})
			FireGameEvent("update_scoreboard_value", {player_ID=pID, key="steals",value=hero.steals})
			FireGameEvent("update_scoreboard_value", {player_ID=pID, key="turn",value=hero.turnovers})
			FireGameEvent("update_scoreboard_value", {player_ID=pID, key="st",value=hero.steals-hero.turnovers})
			FireGameEvent("update_scoreboard_value", {player_ID=pID, key="pickups",value=hero.pickups})
			FireGameEvent("update_scoreboard_value", {player_ID=pID, key="passes",value=hero.numPasses})
			FireGameEvent("update_scoreboard_value", {player_ID=pID, key="pr",value=hero.passesReceived})
			FireGameEvent("update_scoreboard_value", {player_ID=pID, key="poss",value=round(hero.possession_time,0)})
			-- seconds played as goalie. (spag)
			FireGameEvent("update_scoreboard_value", {player_ID=pID, key="spag",value=round(hero.time_as_goalie,0)})

			local savp = -1
			if hero.numSaves ~= 0 or hero.non_saves ~= 0 then
				savp = hero.numSaves/(hero.numSaves+hero.non_saves)*100
			end
			--print("savp: " .. savp)

			FireGameEvent("update_scoreboard_value", {player_ID=pID, key="savp",value=savp})

			--10 * Goals + 5 * Assists + (S - T) + Pickups + 2*Passes + 3*Saves - Non_Saves
			-- Zealot Hockey formula.
			local total = 10*hero.goalsAgainst + 5*hero.numAssists + (hero.steals-hero.turnovers) + hero.pickups + 2*hero.numPasses + 3*hero.numSaves - hero.non_saves

			FireGameEvent("update_scoreboard_value", {player_ID=pID, key="tot",value=total})
			--FireGameEvent("update_scoreboard_value", {player_ID=pID, key="pr",value=hero.passesReceived})


		end

		return .5
	end)

end

function DotaStrikers:PrecacheTest()
	PrecacheResource("particle", "particles/econ/courier/courier_trail_international_2013_se/courier_international_2013_se.vpcf", PrecacheContext)



end


TORNADO_RADIUS = 230
TORNADO_FORCE = 1600
TORNADO_MAX_HEIGHT = 1200