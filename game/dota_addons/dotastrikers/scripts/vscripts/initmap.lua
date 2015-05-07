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
			if unit.isBall and unit.controller == nil then
				--print("passTest")
				passTest = true
			elseif unit.isBall and unit.controller ~= nil then
				--print("ball, controller not nil.")
			elseif unit.isDSHero then
				passTest = true
			end
			-- done with passTest logic. move onto parsing that logic, add sounds, effects, etc.
			if unit.isBall and passTest and not unit.controller and not ball.affectedByPowershot then
				unit:EmitSound("Bounce" .. RandomInt(1, NUM_BOUNCE_SOUNDS))
			elseif unit.isDSHero and passTest then
				if unit.velocityMagnitude > CRACK_THRESHOLD*CRACK_THRESHOLD then
					unit:EmitSound("ThunderClapCaster")
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
	local gcOffset = 190
	GoalColliders[1].corners =
	{
		[1] = Vector(Bounds.min-RectangleOffset+outwardness, -210, 0),
		[2] = Vector(Bounds.min-RectangleOffset-offset, 210, colliderZ),
	}
	GoalColliders[2].corners =
	{
		[1] = Vector(Bounds.max+RectangleOffset-outwardness, -210, 0),
		[2] = Vector(Bounds.max+RectangleOffset+offset, 210, colliderZ),
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
				if unit:GetPlayerOwner() ~= nil then
					ShowErrorMsg(unit, "Can't enter enemy goal post")
				end
			elseif unit == ball then
				passTest = false
				local pos = ball:GetAbsOrigin()
				local scored = false
				if not ball.controller then
					if i == 1 then
						if pos.x < (Bounds.min-RectangleOffset) and pos.z < 300 then
							scored = true
						end
					else
						if pos.x > (Bounds.max+RectangleOffset) and pos.z < 300 then
							scored = true
						end
					end
				end

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
						unit:EmitSound("ThunderClapCaster")
					end
				end
			end

			return passTest
		end
		--gc.draw = true
	end
	--self:PlaceProps()
end