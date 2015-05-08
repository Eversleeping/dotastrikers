GOAL_Y = 210
TIME_TILL_NEXT_ROUND = 8
SCORE_TO_WIN = 13
NUM_ROUNDEND_SOUNDS = 3
GOAL_SMOOTHING = 180
GOAL_Z = 500

function DotaStrikers:InitMap()
	local ball = Ball.unit

	BoundsColliders = {}
	Corners = 
	{
		[1] = Vector(Bounds.max+RectangleOffset, Bounds.max, GroundZ),
		[2] = Vector(Bounds.min-RectangleOffset, Bounds.max, GroundZ),
		[3] = Vector(Bounds.min-RectangleOffset, Bounds.min, GroundZ),
		[4] = Vector(Bounds.max+RectangleOffset, Bounds.min, GroundZ),
	}

	CornerParticles = {}

	local offset = 2000
	local colliderZ = 2000
	for i=1,4 do
		BoundsColliders[i] = Physics:AddCollider("bounds_collider_" .. i, Physics:ColliderFromProfile("aaboxreflect"))
		local corner = Corners[i]
		local nextCorner = Corners[1]
		if i < 4 then
			nextCorner = Corners[i+1]
		end
		if i == 1 then
			corner = Vector(corner.x+offset, corner.y, 0)
			nextCorner = Vector(nextCorner.x-offset, nextCorner.y+offset,nextCorner.z+colliderZ)
		elseif i == 2 then
			corner = Vector(corner.x, corner.y+offset, 0)
			nextCorner = Vector(nextCorner.x-offset, nextCorner.y-offset,nextCorner.z+colliderZ)
		elseif i == 3 then
			corner = Vector(corner.x-offset, corner.y, 0)
			nextCorner = Vector(nextCorner.x+offset, nextCorner.y-offset,nextCorner.z+colliderZ)
		else
			corner = Vector(corner.x, corner.y-offset, 0)
			nextCorner = Vector(nextCorner.x+offset, nextCorner.y+offset, nextCorner.z+colliderZ)
		end

		BoundsColliders[i].box = {corner, nextCorner}

		BoundsColliders[i].test = function(self, unit)
			local passTest = false
			local isBall = unit == ball
			if isBall and not ball.controller then
				--print("passTest")
				local pos = ball:GetAbsOrigin()
				if (pos.y > -1*GOAL_Y and pos.y < GOAL_Y) and pos.z < GOAL_Z then
					if pos.x < (Bounds.min-RectangleOffset-GOAL_SMOOTHING) then
						DotaStrikers:OnGoal("Dire")
					elseif pos.x > (Bounds.max+RectangleOffset+GOAL_SMOOTHING) then
						DotaStrikers:OnGoal("Radiant")
					end
				else
					passTest = true
				end
			elseif isBall and unit.controller then
				--print("ball, controller not nil.")
			elseif unit.isDSHero then
				passTest = true
			end
			-- done with passTest logic. move onto parsing that logic, add sounds, effects, etc.
			if isBall and passTest and not ball.controller and not ball.affectedByPowershot then
				unit:EmitSound("Bounce" .. RandomInt(1, NUM_BOUNCE_SOUNDS))
			elseif unit.isDSHero and passTest then
				if unit.velocityMagnitude > CRACK_THRESHOLD*CRACK_THRESHOLD then
					EmitSoundAtPosition("ThunderClapCaster", unit:GetAbsOrigin())
					if unit.currPos.z < (GroundZ + 10) then
						ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_ground_cracks.vpcf", PATTACH_ABSORIGIN, unit)
					end
				end
			end

			return passTest
		end
		--BoundsColliders[i].draw = true
	end

	GoalColliders = {}
	GoalColliders[1] = Physics:AddCollider("goal_collider_" .. 1, Physics:ColliderFromProfile("aaboxreflect"))
	GoalColliders[2] = Physics:AddCollider("goal_collider_" .. 2, Physics:ColliderFromProfile("aaboxreflect"))

	GoalColliders[1].team = DOTA_TEAM_GOODGUYS
	GoalColliders[2].team = DOTA_TEAM_BADGUYS

	local rgp = Entities:FindByName(nil, "radiant_goal_point"):GetAbsOrigin()
	local rgp2 = Entities:FindByName(nil, "radiant_goal_point2"):GetAbsOrigin()
	local outwardness = 422
	GoalColliders[1].corners =
	{
		[1] = Vector(Bounds.min-RectangleOffset+outwardness, -1*GOAL_Y, 0),
		[2] = Vector(Bounds.min-RectangleOffset-offset, GOAL_Y, colliderZ),
	}
	GoalColliders[2].corners =
	{
		[1] = Vector(Bounds.max+RectangleOffset-outwardness, -1*GOAL_Y, 0),
		[2] = Vector(Bounds.max+RectangleOffset+offset, GOAL_Y, colliderZ),
	}

	for i=1,2 do
		local gc = GoalColliders[i]
		gc.box = {gc.corners[1], gc.corners[2]}
		gc.test = function ( self, unit )
			if not IsPhysicsUnit(unit) then return false end
			if unit == gc.goalie then return false end -- ignore the current goalie in this goalpost.
			local passTest = false
			if unit ~= ball and gc.goalie then
				-- if the unit isn't the ball and there's a goalie in there, collision occurs.
				passTest = true
				if unit:GetTeamNumber() == gc.team then
					ShowErrorMsg(unit, "Your team already has a goalie")
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
					ShowErrorMsg(unit, "Can't enter enemy goal post")
				end
				
			end
			if passTest then
				DotaStrikers:OnCantEnterGoalPost(unit) -- this is in abilities.lua
				-- if high velocity onto the goal post, do sounds/effects etc.
				if unit.isDSHero then
					if unit.velocityMagnitude > CRACK_THRESHOLD*CRACK_THRESHOLD then
						EmitSoundAtPosition("ThunderClapCaster", unit:GetAbsOrigin())
						if unit.currPos.z < (GroundZ + 10) then
							ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_ground_cracks.vpcf", PATTACH_ABSORIGIN, unit)
						end
					end
				end
			end

			return passTest
		end
		--gc.draw = true
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

	for _,hero in ipairs(DotaStrikers.vHeroes) do
		if not hero:HasAbility("stun_passive") then
			hero:AddAbility("stun_passive")
			hero:FindAbilityByName("stun_passive"):SetLevel(1)
		end
		CleanUpHero(hero)
	end

	ball:CleanUp()

	local start = 5
	ShowCenterMsg(lastController.playerName .. " SCORED!", TIME_TILL_NEXT_ROUND-start )
	for i=start,1,-1 do
		Timers:CreateTimer(TIME_TILL_NEXT_ROUND-i, function()
			if i == start then
				for _,hero in ipairs(DotaStrikers.vHeroes) do
					hero:SetAbsOrigin(hero.spawn_pos)
				end
				ball:SetAbsOrigin(Vector(0,0,GroundZ))
			end
			Say(nil, i .. "...", false)
		end)
	end

	Timers:CreateTimer(TIME_TILL_NEXT_ROUND, function()
		for _,hero in ipairs(DotaStrikers.vHeroes) do
			if hero:HasAbility("stun_passive") then
				hero:RemoveAbility("stun_passive")
				hero:RemoveModifierByName("modifier_stun_passive")
			end
		end

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

function CleanUpHero( hero )
	hero:SetPhysicsAcceleration(BASE_ACCELERATION)
	hero:SetPhysicsVelocity(Vector(0,0,0))
	hero.dontChangeFriction = false
	hero:SetPhysicsFriction(GROUND_FRICTION)


end