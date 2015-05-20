TIME_TILL_NEXT_ROUND = 8
NUM_ROUNDEND_SOUNDS = 11
GOAL_SMOOTHING = 540 -- the inwardness of the goal post.
RECT_X_MIN = Bounds.min-RectangleOffset
RECT_X_MAX = Bounds.max+RectangleOffset
-- these are for the whole goal post (everywhere the goalie can move)
GOAL_X_MIN = RECT_X_MIN-GOAL_SMOOTHING
GOAL_X_MAX = RECT_X_MAX+GOAL_SMOOTHING

SCORE_X_MAX = 2830
SCORE_X_MIN = -1*SCORE_X_MAX

GOAL_OUTWARDNESS = 420
GOAL_LESSEN_SIDE = 20 -- lessens the y-length of the goal post (for goalies), helps with model clipping into fences.
GC_INCREASE_SIDE = 20 -- increases the y-length of the goal collider. 
COLLIDER_Z = 15000

GOAL_Y = 428 -- half of the y direction width of the goal post.
-- RADIANT MAP VALUES:
R_OUTWARDNESS = -1879
R_INWARDNESS = -3218.45
R_SCORE = -2828.21
BIG_OFFSET = 10000
GOAL_Z = 492

D_OUTWARDNESS = -1*R_OUTWARDNESS
D_SCORE = -1*R_SCORE

function DotaStrikers:GetRoundAbils( hero )
	--print("round_in_progress_abils:")
	local ptr = 1
	local round_in_progress_abils = {}
	for k,v in pairs(self.HeroesKV) do
		if k == hero.heroes_kv_name then
			for k,v2 in pairs(v) do
				--print(k .. ": " .. v2)
				if k:sub(1,7) == "Ability" and k:len() == 8 then
					local index = tonumber(k:sub(8,8))
					if index and index <= 6 then
						--print(k .. ": " .. v2)
						round_in_progress_abils[index] = v2
					end
				end
			end
		end
	end

	hero.round_in_progress_abils = round_in_progress_abils

	local round_not_in_progress_abils = {}
	for i=1,6 do
		if i == 4 then
			round_not_in_progress_abils[i] = "pass_me"
		else
			round_not_in_progress_abils[i] = "dotastrikers_empty" .. i
		end
		--print(round_not_in_progress_abils[i])
	end
	hero.round_not_in_progress_abils = round_not_in_progress_abils
end


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
	bcs[2].box = {Vector(-1*BIG_OFFSET, GOAL_Y*-1, GOAL_Z), Vector(R_SCORE, GOAL_Y, BIG_OFFSET)}

	-- top of dire goal post, ball reflector
	bcs[3].box = {Vector(BIG_OFFSET, GOAL_Y*-1, GOAL_Z), Vector(D_SCORE, GOAL_Y, BIG_OFFSET)}

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

			if TrySetComponentStatus(unit) then return true end

			if unit == gc.goalie then return false end -- ignore the current goalie in this goalpost.

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
			TrySetComponentStatus(unit)

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
	scorer.personalScore = scorer.personalScore + 1

	-- special effect for scorer?

	EmitGlobalSound("Round_End" .. RandomInt(1, NUM_ROUNDEND_SOUNDS))

	ball.dontChangeFriction = true

	ball:SetPhysicsFriction(GROUND_FRICTION*3)

	--local win_ball_pos = ball:GetAbsOrigin()
	Timers:CreateTimer(.06, function()
		local win_ball_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_templar_assassin/templar_assassin_trap_explode.vpcf", PATTACH_ABSORIGIN, ball)
		--ParticleManager:SetParticleControl(win_ball_particle, 0, win_ball_pos)
		EmitSoundAtPosition("Hero_TemplarAssassin.Trap.Explode", ball:GetAbsOrigin())
	end)

	CleanUp(ball)

	local nWinningTeam = DOTA_TEAM_BADGUYS
	if team == "Radiant" then
		nWinningTeam = DOTA_TEAM_GOODGUYS
	end

	-- force activate the break abil if hero has it.
	for _,hero in ipairs(DotaStrikers.vHeroes) do
		local surge_break = hero:GetAbilityByIndex(2)
		local abilName = surge_break:GetAbilityName()
		if string.ends(abilName, "break") then
			hero:CastAbilityNoTarget(surge_break, 0)
		end

		-- root losing heroes only
		if hero:GetTeam() ~= nWinningTeam then
			AddEndgameRoot(hero)
		else
			ParticleManager:CreateParticle("particles/legion_duel_victory/legion_commander_duel_victory.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
		end
		
	--[[
		local animType = t[1]
		local unit = t[2]
		local unitKVName = t[3]
		local maxDuration = t[4]
		local singleDuration = t[5]
		local repeatAnim = t[6]
	]]

		-- play victory/defeat animation
		--[[if not hero:HasModifier("modifier_flail_passive") then
			if hero:GetTeam() == nWinningTeam then
				hero.victory_anim = PlayAnimation("victory", hero )
			else
				hero.defeat_anim = PlayAnimation("defeat", hero )
			end
		end]]
	end

	-- Allot time for the break ability to execute.
	Timers:CreateTimer(.06, function()
		for _,hero in ipairs(DotaStrikers.vHeroes) do
			CleanUp(hero)

			-- Replace the abils with the round_not_in_progress abils
			for i=1,6 do
				local abil = hero:GetAbilityByIndex(i-1)
				hero:RemoveAbility(abil:GetAbilityName())
				hero:AddAbility(hero.round_not_in_progress_abils[i])
				hero:FindAbilityByName(hero.round_not_in_progress_abils[i]):SetLevel(1)
			end
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
	for i=start,1,-1 do
		Timers:CreateTimer(TIME_TILL_NEXT_ROUND-i, function()
			if i == start then
				for _,hero in ipairs(DotaStrikers.vHeroes) do
					--[[if hero:GetTeam() == nWinningTeam then
						StopAnimation(hero.victory_anim, hero)
					else
						StopAnimation(hero.defeat_anim, hero)
					end]]

					--[[if hero.goalie then
						DotaStrikers:RemoveGoalieJump(hero)
					end]]

					StopAnimation("modifier_flail_passive", hero)
					AddEndgameRoot(hero)

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

					-- make them all face the ball (looks nicer)
					Timers:CreateTimer(.03, function()
						hero:SetForwardVector((ball:GetAbsOrigin()-hero:GetAbsOrigin()):Normalized())

						hero:SetMana(hero:GetMaxMana())

						Timers:CreateTimer(.03, function()
							hero:AddNewModifier(hero, nil, "modifier_camera_follow", {})

							InitAbility("spawn_anim", hero, function(abil)
								hero:CastAbilityNoTarget(abil, 0)
							end, true)

						end)
					end)
				end

				ball.controller = nil
				ball.dontChangeFriction = false
				ball:SetPhysicsFriction(GROUND_FRICTION)
				ball:SetAbsOrigin(Vector(0,0,GroundZ))
				Timers:CreateTimer(.03, function()
					ball:StopPhysicsSimulation()
				end)
			end
			Say(nil, i .. "...", false)
		end)
	end

	Timers:CreateTimer(TIME_TILL_NEXT_ROUND, function()
		for _,hero in ipairs(DotaStrikers.vHeroes) do
			RemoveEndgameRoot(hero)

			for i=1,6 do
				local abil = hero:GetAbilityByIndex(i-1)
				if abil then
					hero:RemoveAbility(abil:GetAbilityName())
					hero:AddAbility(hero.round_in_progress_abils[i])
					hero:FindAbilityByName(hero.round_in_progress_abils[i]):SetLevel(1)
				else
					print("no abil at " .. i)
				end
			end

			hero:StartPhysicsSimulation()
			hero:SetPhysicsAcceleration(BASE_ACCELERATION)
			hero:SetPhysicsVelocity(Vector(0,0,0))
		end
		ball:StartPhysicsSimulation()
		ball:SetPhysicsAcceleration(BASE_ACCELERATION)
		ball:SetPhysicsVelocity(ball:GetAbsOrigin() + RandomVector(RandomInt(BALL_ROUNDSTART_KICK[1], BALL_ROUNDSTART_KICK[2])))


		RoundInProgress = true
		Say(nil, "PLAY!!", false)
	end)
end

function DotaStrikers:OnWonGame( nWinningTeam )
	local sWinningTeam = "Radiant"
	if nWinningTeam == DOTA_TEAM_BADGUYS then
		sWinningTeam = "Dire"
	end
	ShowCenterMsg(sWinningTeam .. " WINS!", 4 )

	GameRules:SetGameWinner( nWinningTeam )
	GameRules:SetSafeToLeave( true )
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
	--[[if pos.x < (RECT_X_MIN-5) then
		return DOTA_TEAM_GOODGUYS
	elseif pos.x > (RECT_X_MAX+5) then
		return DOTA_TEAM_BADGUYS
	end]]

	local goal_neg = -1*GOAL_Y-GC_INCREASE_SIDE
	local goal_pos = GOAL_Y+GC_INCREASE_SIDE

	if pos.x < (RECT_X_MIN+GOAL_OUTWARDNESS) and (pos.y > goal_neg and pos.y < goal_pos) then
		return DOTA_TEAM_GOODGUYS
	elseif pos.x > (RECT_X_MAX-GOAL_OUTWARDNESS) and (pos.y > goal_neg and pos.y < goal_pos) then
		return DOTA_TEAM_BADGUYS
	end
	return nil
end

function OnBoundsCollision( self, unit, bc )
	if not IsPhysicsUnit(unit) then return false end

	if TrySetComponentStatus(unit) then return true end

	local ball = Ball.unit
	local isBall = unit == ball
	local passTest = true
	local unitPos = unit:GetAbsOrigin()
	--print(bc.name)

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

	TryInvokeComponents(passTest, unit)

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


function PlayAnimation( ... )
	local t = {...}
	local animType = t[1]
	local unit = t[2]
	local unitKVName = t[3]
	local maxDuration = t[4]
	local singleDuration = t[5]
	local repeatAnim = t[6]

	if not t[3] then
		if not unit:IsRealHero() then
			unitKVName = unit:GetUnitName()
		else
			unitKVName = unit.heroes_kv_name
		end
	end

	local anim = "modifier_victory_anim_" .. unitKVName
	if animType == "victory" then
		if not DotaStrikers.AbilitiesKV["global_dummy_passive"]["Modifiers"][anim] then
			anim = "modifier_victory_anim"
		end
	elseif animType == "defeat" then
		anim = "modifier_defeat_anim_" .. unitKVName
		if not DotaStrikers.AbilitiesKV["global_dummy_passive"]["Modifiers"][anim] then
			print("getting defeat anim.")
			anim = "modifier_defeat_anim"
		end
	end
	print("anim: " .. anim)

	GlobalDummy.dummy_passive:ApplyDataDrivenModifier(GlobalDummy, unit, anim, {})

	if maxDuration then
		if repeatAnim then
			local animStopTime = GameRules:GetGameTime() + maxDuration
			local firstRun = singleDuration
			if not firstRun then firstRun = 2 end
			Timers:CreateTimer(firstRun, function()
				StopAnimation(anim, unit)
				if GameRules:GetGameTime() > animStopTime then
					return
				end
				GlobalDummy.dummy_passive:ApplyDataDrivenModifier(GlobalDummy, unit, anim, {})

				return firstRun
			end)
		else
			Timers:CreateTimer(maxDuration, function()
				StopAnimation(anim, unit)
			end)
		end
	end
end

function StopAnimation( anim, unit )
	if anim == nil then return end
	if unit:HasModifier(anim) then
		unit:RemoveModifierByName(anim)
	end
end