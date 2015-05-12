GOAL_Y = 290 -- half of the y direction width of the goal post.
TIME_TILL_NEXT_ROUND = 7
SCORE_TO_WIN = 13
NUM_ROUNDEND_SOUNDS = 11
GOAL_SMOOTHING = 540 -- the inwardness of the goal post.
GOAL_Z = 510
RECT_X_MIN = Bounds.min-RectangleOffset
RECT_X_MAX = Bounds.max+RectangleOffset
-- these are for the whole goal post (everywhere the goalie can move)
GOAL_X_MIN = RECT_X_MIN-GOAL_SMOOTHING
GOAL_X_MAX = RECT_X_MAX+GOAL_SMOOTHING

SCORE_X_MAX = RECT_X_MAX+270
SCORE_X_MIN = -1*SCORE_X_MAX

GOAL_OUTWARDNESS = 400
GOAL_LESSEN_SIDE = 20 -- lesses the y-length of the goal post (for goalies), helps with model clipping into fences.
GC_INCREASE_SIDE = 30 -- increases the y-length of the goal collider. 
COLLIDER_Z = 15000

function DotaStrikers:InitMap()
	local ball = Ball.unit

	local offset = 3000

	self.bcs = {
		[1] = Physics:AddCollider("bounds_collider_1", Physics:ColliderFromProfile("aaboxreflect")),
		[2] = Physics:AddCollider("bounds_collider_2", Physics:ColliderFromProfile("aaboxreflect")),
		[3] = Physics:AddCollider("bounds_collider_3", Physics:ColliderFromProfile("aaboxreflect")),
		[4] = Physics:AddCollider("bounds_collider_4", Physics:ColliderFromProfile("aaboxreflect")),
		[5] = Physics:AddCollider("bounds_collider_5", Physics:ColliderFromProfile("aaboxreflect")),
		[6] = Physics:AddCollider("bounds_collider_6", Physics:ColliderFromProfile("aaboxreflect")),
		[7] = Physics:AddCollider("bounds_collider_7", Physics:ColliderFromProfile("aaboxreflect")),
		[8] = Physics:AddCollider("bounds_collider_8", Physics:ColliderFromProfile("aaboxreflect")),
		[9] = Physics:AddCollider("bounds_collider_9", Physics:ColliderFromProfile("aaboxreflect")),
		[10] = Physics:AddCollider("bounds_collider_10", Physics:ColliderFromProfile("aaboxreflect")),
		[11] = Physics:AddCollider("bounds_collider_11", Physics:ColliderFromProfile("aaboxreflect")),
		[12] = Physics:AddCollider("bounds_collider_12", Physics:ColliderFromProfile("aaboxreflect")),
		[13] = Physics:AddCollider("bounds_collider_13", Physics:ColliderFromProfile("aaboxreflect")),
	}
	local bcs = self.bcs

	-- top and bottom big colliders
	bcs[1].box = {Vector(RECT_X_MAX+offset, Bounds.max, 0), Vector(RECT_X_MIN-offset, Bounds.max+offset, COLLIDER_Z)}
	bcs[2].box = {Vector(RECT_X_MAX+offset, Bounds.min, 0), Vector(RECT_X_MIN-offset, Bounds.min-offset, COLLIDER_Z)}
	-- upper right, badguys goal
	bcs[3].box = {Vector(RECT_X_MAX+offset, Bounds.max+offset, 0), Vector(RECT_X_MAX, GOAL_Y-GOAL_LESSEN_SIDE, COLLIDER_Z)}
	--bcs[3].draw=true
	-- lower right, badguys goal
	bcs[4].box = {Vector(RECT_X_MAX+offset, Bounds.min-offset, 0), Vector(RECT_X_MAX, -1*GOAL_Y+GOAL_LESSEN_SIDE, COLLIDER_Z)}
	--bcs[4].draw=true
	-- upper left, goodguys goal
	bcs[5].box = {Vector(RECT_X_MIN-offset, Bounds.max+offset, 0), Vector(RECT_X_MIN, GOAL_Y-GOAL_LESSEN_SIDE, COLLIDER_Z)}
	--bcs[5].draw=true
	-- lower left, goodguys goal
	bcs[6].box = {Vector(RECT_X_MIN-offset, Bounds.min-offset, 0), Vector(RECT_X_MIN, -1*GOAL_Y+GOAL_LESSEN_SIDE, COLLIDER_Z)}
	--bcs[6].draw=true

	-- far left, goodguys (to prevent non-goalies from entering area.)
	bcs[7].box = {Vector(RECT_X_MIN-offset, Bounds.max, 0), Vector(RECT_X_MIN, Bounds.min, COLLIDER_Z)}

	-- far right, badguys (to prevent non-goalies from entering area.)
	bcs[8].box = {Vector(RECT_X_MAX+offset, Bounds.max, 0), Vector(RECT_X_MAX, Bounds.min, COLLIDER_Z)}

	-- far left, goodguys FOR GOALIES
	bcs[9].box = {Vector(RECT_X_MIN-offset, Bounds.max, 0), Vector(RECT_X_MIN-GOAL_SMOOTHING, Bounds.min, COLLIDER_Z)}

	-- far right, badguys FOR GOALIES
	bcs[10].box = {Vector(RECT_X_MAX+offset, Bounds.max, 0), Vector(RECT_X_MAX+GOAL_SMOOTHING, Bounds.min, COLLIDER_Z)}

	-- the top of everything
	local this_offset = 2*offset
	bcs[11].box = {Vector(GOAL_X_MAX+this_offset, Bounds.max+this_offset, COLLIDER_Z-this_offset), Vector(GOAL_X_MIN-this_offset, Bounds.min-this_offset, COLLIDER_Z+this_offset)}

	-- top of radiant goal post, ball reflector
	bcs[12].box = {Vector(SCORE_X_MIN-offset, GOAL_Y*-1, GOAL_Z), Vector(SCORE_X_MIN, GOAL_Y, COLLIDER_Z)}

	-- top of dire goal post, ball reflector
	bcs[13].box = {Vector(SCORE_X_MAX+offset, GOAL_Y*-1, GOAL_Z), Vector(SCORE_X_MAX, GOAL_Y, COLLIDER_Z)}

	for i,bc in ipairs(bcs) do
		bc.test = function(self, unit)
			return OnBoundsCollision(self, unit, bc, i)
		end
		bc.filter = DotaStrikers.colliderFilter
	end

	self.gcs = {
		[1] = Physics:AddCollider("goal_collider_1", Physics:ColliderFromProfile("aaboxreflect")),
		[2] = Physics:AddCollider("goal_collider_2", Physics:ColliderFromProfile("aaboxreflect"))
	}

	local gcs = self.gcs

	gcs[1].box = {Vector(RECT_X_MIN+GOAL_OUTWARDNESS, -1*GOAL_Y-GC_INCREASE_SIDE, 0), Vector(RECT_X_MIN-offset, GOAL_Y+GC_INCREASE_SIDE, COLLIDER_Z)}
	gcs[2].box = {Vector(RECT_X_MAX-GOAL_OUTWARDNESS, -1*GOAL_Y-GC_INCREASE_SIDE, 0), Vector(RECT_X_MAX+offset, GOAL_Y+GC_INCREASE_SIDE, COLLIDER_Z)}
	gcs[1].team = DOTA_TEAM_GOODGUYS
	gcs[2].team = DOTA_TEAM_BADGUYS
	--gcs[1].draw=true
	--gcs[2].draw=true

	for _,gc in ipairs(gcs) do
		gc.test = function ( self, unit )
			if not IsPhysicsUnit(unit) then return false end

			if unit == gc.goalie then return false end -- ignore the current goalie in this goalpost.

			local passTest = false
			if unit ~= ball and gc.goalie then
				-- if the unit isn't the ball and there's a goalie in there, collision occurs.
				passTest = true
				if unit:GetTeamNumber() == gc.team then
					ShowErrorMsg(unit, "Your team already has a goalie")
				else
					ShowErrorMsg(unit, "Can't enter enemy goal post")
				end
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
					--print("cant enter")
					ShowErrorMsg(unit, "Can't enter enemy goal post")
				end
				
			end
			-- done with calculating passTest value.

			if passTest then
				DotaStrikers:OnCantEnter(unit)
				-- if high velocity onto the goal post, do sounds/effects etc.
				if unit.isDSHero then
					TryPlayCracks(unit)
				end
			end
			return passTest
		end
		--gc.draw=true
		gc.filter = DotaStrikers.colliderFilter
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
	local lastController = ball.lastController
	lastController.personalScore = lastController.personalScore + 1

	local winningTeamCol = "green"
	if team == "Dire" then
		winningTeamCol = "red"
		self.direScore = self.direScore + 1
		GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_BADGUYS, self.direScore )
		if self.direScore >= SCORE_TO_WIN then
			DotaStrikers:OnWonGame("Dire")
		end
	else
		self.radiantScore = self.radiantScore + 1
		GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_GOODGUYS, self.radiantScore )
		if self.radiantScore >= SCORE_TO_WIN then
			DotaStrikers:OnWonGame("Radiant")
		end
	end

	local lines = {
		[1] = ColorIt(lastController.playerName, lastController.colStr) .. " scored for the " .. ColorIt(team, winningTeamCol) .. "!!!"

	}

	ShowQuickMessages(lines, .2)

	EmitGlobalSound("Round_End" .. RandomInt(1, NUM_ROUNDEND_SOUNDS))

	ball.dontChangeFriction = true

	ball:SetPhysicsFriction(GROUND_FRICTION*3)

	CleanUp(ball)

	-- hero is going to activate the surge/sprint break ability at this point. we cant silence or stun him yet.
	for _,hero in ipairs(DotaStrikers.vHeroes) do
		hero:SetMana(2)
	end

	Timers:CreateTimer(.06, function()
		for _,hero in ipairs(DotaStrikers.vHeroes) do
			CleanUp(hero)
			--print("accel: " .. VectorString(hero:GetPhysicsAcceleration()))
			AddStun(hero)
			AddSilence(hero)
		end
	end)

	local start = 3
	ShowCenterMsg(lastController.playerName .. " SCORED!", TIME_TILL_NEXT_ROUND-start )
	for i=start,1,-1 do
		Timers:CreateTimer(TIME_TILL_NEXT_ROUND-i, function()
			if i == start then
				--ball:SetPhysicsVelocity(Vector(0,0,0))
				for _,hero in ipairs(DotaStrikers.vHeroes) do
					AddEndgameRoot(hero)
					RemoveStun(hero)

					-- NOTE: make sure to do all physics stop BEFORE StopPhysicsSimulation or AFTER StartPhysicsSimulation.
					hero.dontChangeFriction = false
					hero:SetPhysicsFriction(GROUND_FRICTION)
					hero:StopPhysicsSimulation()

					if hero:HasModifier("modifier_flail_passive") then
						hero:RemoveModifierByName("modifier_flail_passive")
					end

					hero:SetAbsOrigin(Vector(hero.spawn_pos.x, hero.spawn_pos.y, GroundZ))

					-- make them all face the ball (looks nicer)
					Timers:CreateTimer(.06, function()
						hero:SetForwardVector((ball:GetAbsOrigin()-hero:GetAbsOrigin()):Normalized())
						hero:SetMana(hero:GetMaxMana())
						Timers:CreateTimer(.06, function()
							AddStun(hero)
							RemoveEndgameRoot(hero)
							hero:AddNewModifier(hero, nil, "modifier_camera_follow", {})
						end)
					end)

				end
				ball.controller = nil
				ball.dontChangeFriction = false
				ball:SetPhysicsFriction(GROUND_FRICTION)
				ball:StopPhysicsSimulation()

				ball:SetAbsOrigin(Vector(0,0,GroundZ))
			end
			Say(nil, i .. "...", false)
		end)
	end

	Timers:CreateTimer(TIME_TILL_NEXT_ROUND, function()
		for _,hero in ipairs(DotaStrikers.vHeroes) do
			RemoveStun(hero)
			RemoveSilence(hero)
			hero:StartPhysicsSimulation()
			hero:SetPhysicsAcceleration(BASE_ACCELERATION)
			hero:SetPhysicsVelocity(Vector(0,0,0))
		end
		ball:StartPhysicsSimulation()
		ball:SetPhysicsAcceleration(BASE_ACCELERATION)
		ball:SetPhysicsVelocity(ball:GetAbsOrigin() + RandomVector(RandomInt(BALL_ROUNDSTART_KICK[1], BALL_ROUNDSTART_KICK[2])))

		Say(nil, "PLAY!!", false)
	end)
end

function DotaStrikers:OnWonGame( winningTeam )
	ShowCenterMsg(winningTeam .. " WINS!", 4 )
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

function IsUnitWithinGoalBounds( unit )
	local pos = unit:GetAbsOrigin()
	if pos.x < (RECT_X_MIN-5) or pos.x > (RECT_X_MAX+5) and pos.z < GOAL_Z then
		return true
	end

	if pos.x < (RECT_X_MIN+GOAL_OUTWARDNESS) and (pos.y > -1*GOAL_Y and pos.y < GOAL_Y) and pos.z < GOAL_Z then
		return true
	elseif pos.x > (RECT_X_MAX-GOAL_OUTWARDNESS) and (pos.y > -1*GOAL_Y and pos.y < GOAL_Y) and pos.z < GOAL_Z then
		return true
	end
	return false
end

function OnBoundsCollision( self, unit, bc, i )
	--return false
	if not IsPhysicsUnit(unit) then return false end
	local ball = Ball.unit
	local isBall = unit == ball
	local passTest = true
	local unitPos = unit:GetAbsOrigin()

	-- when someone is holding the ball
	if isBall and ball.controller then
		return false
	end

	if bc.name == "bounds_collider_12" or bc.name == "bounds_collider_13" then
		if isBall then
			DotaStrikers:OnCantEnter(unit)

			return true
		end
	end

	if bc.name == "bounds_collider_11" then
		return true
	end

	if bc.name == "bounds_collider_7" or bc.name == "bounds_collider_8" then
		if unit.goalie or isBall then
			return false
		end
	end

	if bc.name == "bounds_collider_9" or bc.name == "bounds_collider_10" then
		if unit.goalie or isBall then
			if unit.isAboveGround then
				DotaStrikers:OnCantEnter(unit)
			end
			return true
		end
	end

	-- done with passTest logic. move onto parsing that logic, add sounds, effects, etc.
	if isBall and passTest and not ball.controller and not ball.affectedByPowershot then
		unit:EmitSound("Bounce" .. RandomInt(1, NUM_BOUNCE_SOUNDS))
	elseif unit.isDSHero and passTest then
		TryPlayCracks(unit, nil, true)
	end
	if passTest then
		if unit.isAboveGround then
			DotaStrikers:OnCantEnter(unit)
		end
	end

	return passTest
end

function DotaStrikers:OnCantEnter( unit )
	local currTime = GameRules:GetGameTime()
	if not unit.lastShieldParticleTime or currTime-unit.lastShieldParticleTime > .03 then
		local pos = unit:GetAbsOrigin()
		local fv = unit:GetForwardVector()
		unit.shieldParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_medusa/medusa_mana_shield_impact_highlight01.vpcf", PATTACH_CUSTOMORIGIN, unit)
		ParticleManager:SetParticleControl(unit.shieldParticle, 0, Vector(pos.x,pos.y,pos.z-70) + Vector(fv.x,fv.y,0)*40)
		--ParticleManager:SetParticleControl(unit.shieldParticle, 0, Vector(pos.x,pos.y,pos.z-80) + Vector(fv.x,fv.y,0)*50)
		unit.lastShieldParticleTime = currTime
	end
end

function AddStun( hero )
	if not hero:HasAbility("stun_passive") then
		hero:AddAbility("stun_passive")
		hero:FindAbilityByName("stun_passive"):SetLevel(1)
	end
end

function RemoveStun( hero )
	if hero:HasAbility("stun_passive") then
		hero:RemoveAbility("stun_passive")
		hero:RemoveModifierByName("modifier_stun_passive")
	end
end

function AddSilence( hero )
	if not hero:HasModifier("modifier_endround_silenced_passive") then
		EndRoundDummy.endround_passive:ApplyDataDrivenModifier(EndRoundDummy, hero, "modifier_endround_silenced_passive", {})
	end
end

function RemoveSilence( hero )
	if hero:HasModifier("modifier_endround_silenced_passive") then
		hero:RemoveModifierByName("modifier_endround_silenced_passive")
	end
end

function AddEndgameRoot( hero )
	if not hero:HasModifier("modifier_endround_rooted_passive") then
		EndRoundDummy.endround_passive:ApplyDataDrivenModifier(EndRoundDummy, hero, "modifier_endround_rooted_passive", {})
	end
end

function RemoveEndgameRoot( hero )
	if hero:HasModifier("modifier_endround_rooted_passive") then
		hero:RemoveModifierByName("modifier_endround_rooted_passive")
	end
end